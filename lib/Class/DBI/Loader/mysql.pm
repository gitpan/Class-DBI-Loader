package Class::DBI::Loader::mysql;

use strict;
use base 'Class::DBI::Loader::Generic';
use vars '$VERSION';
use DBI;
use Carp;
require Class::DBI::mysql;
require Class::DBI::Loader::Generic;

$VERSION = '0.17';

=head1 NAME

Class::DBI::Loader::mysql - Class::DBI::Loader mysql Implementation.

=head1 SYNOPSIS

  use Class::DBI::Loader;

  # $loader is a Class::DBI::Loader::mysql
  my $loader = Class::DBI::Loader->new(
    dsn       => "dbi:mysql:dbname",
    user      => "root",
    password  => "",
    namespace => "Data",
  );
  my $class = $loader->find_class('film'); # $class => Data::Film
  my $obj = $class->retrieve(1);

=head1 DESCRIPTION

See L<Class::DBI::Loader>, L<Class::DBI::Loader::Generic>.

=cut

sub _db_class { return 'Class::DBI::mysql' }

# Very experimental and untested!
sub _relationships {
    my $self   = shift;
    my @tables = $self->tables;
    my $dbh    = $self->find_class( $tables[0] )->db_Main;
    my $dsn    = $self->{_datasource}[0];
    my %conn   =
      $dsn =~ m/\Adbi:\w+(?:\(.*?\))?:(.+)\z/i
      && index( $1, '=' ) >= 0
      ? split( /[=;]/, $1 )
      : ( database => $1 );
    my $dbname = $conn{database} || $conn{dbname} || $conn{db};
    die("Can't figure out the table name automatically.") if !$dbname;
    my $quoter = $dbh->get_info(29);

    foreach my $table (@tables) {
        my $query = "SHOW TABLE STATUS FROM $dbname LIKE '$table'";
        my $sth   = $dbh->prepare($query)
          or die("Cannot get table status: $table");
        $sth->execute;
        ( my $comment = $sth->fetchrow_hashref->{comment} ) =~ s/$quoter//g;
        $sth->finish;
        while ( $comment =~ m!\((\w+)\)\sREFER\s\w+/(\w+)\(\w+\)!g ) {
            eval { $self->_has_a_many( $table, $1, $2 ) };
            warn qq/has_a_many failed "$@"/ if $@ && $self->debug;
        }
    }
}

sub _tables {
    my $self = shift;
    my $dbh = DBI->connect( @{ $self->{_datasource} } ) or croak($DBI::errstr);
    my @tables;
    foreach my $table ( $dbh->tables ) {
        my $quoter = $dbh->get_info(29);
        $table =~ s/$quoter//g;
        push @tables, $1
          if $table =~ /\A(\w+)\z/;
    }
    $dbh->disconnect;
    return @tables;
}

=head1 SEE ALSO

L<Class::DBI::Loader>, L<Class::DBI::Loader::Generic>

=cut

1;

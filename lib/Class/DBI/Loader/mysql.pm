package Class::DBI::Loader::mysql;

use strict;
use base 'Class::DBI::Loader::Generic';
use vars '$VERSION';
use DBI;
use Carp;
require Class::DBI::mysql;
require Class::DBI::Loader::Generic;

$VERSION = '0.12';

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
    $dsn =~ m/\:([\w\.]*)[\w\=\;]*$/;
    my $dbname = $1;
    die("Can't figure out the table name automatically.") if !$dbname;
    foreach my $table (@tables) {
        my $query = "SHOW TABLE STATUS FROM $dbname LIKE '$table'";
        my $sth   = $dbh->prepare($query)
          or die("Cannot get table status: $table");
        $sth->execute;
        my $comment = $sth->fetchrow_hashref->{comment};
        $sth->finish;
        foreach ( split( /\;/, $comment ) ) {
            next unless $_ =~ m/REFER/i;
            my ( $local_key, $foreign_key ) = split( /\sREFER\s/, $_ );
            $local_key =~ m/\((\w*)\)/;
            my $column = $1;
            $foreign_key =~ m/(\w*)\/+(\w*)\((\w*)\)/;
            my $other = $2;
            $self->_has_a_many( $table, $column, $other );
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
        push @tables, $table;
    }
    return @tables;
}

=head1 SEE ALSO

L<Class::DBI::Loader>, L<Class::DBI::Loader::Generic>

=cut

1;

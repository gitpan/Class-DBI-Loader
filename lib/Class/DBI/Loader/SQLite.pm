package Class::DBI::Loader::SQLite;

use strict;
use base 'Class::DBI::Loader::Generic';
use vars '$VERSION';
use DBI;
use Carp;
require Class::DBI::SQLite;
require Class::DBI::Loader::Generic;

$VERSION = '0.11';

=head1 NAME

Class::DBI::Loader::SQLite - Class::DBI::Loader SQLite Implementation.

=head1 SYNOPSIS

  use Class::DBI::Loader;

  # $loader is a Class::DBI::Loader::SQLite
  my $loader = Class::DBI::Loader->new(
    dsn       => "dbi:SQLite:dbname=/path/to/dbfile",
    namespace => "Data",
  );
  my $class = $loader->find_class('film'); # $class => Data::Film
  my $obj = $class->retrieve(1);

=head1 DESCRIPTION

See L<Class::DBI::Loader>, L<Class::DBI::Loader::Generic>.

=cut

sub _db_class { return 'Class::DBI::SQLite' }

sub _tables {
    my $self = shift;
    my $dbh  = DBI->connect( @{ $self->{_datasource} } ) or croak($DBI::errstr);
    my $sth  = $dbh->prepare("SELECT * FROM sqlite_master");
    $sth->execute;
    my @tables;
    while ( my $row = $sth->fetchrow_hashref ) {
        next unless lc( $row->{type} ) eq 'table';
        push @tables, $row->{tbl_name};
    }
    return @tables;
}

=head1 SEE ALSO

L<Class::DBI::Loader>, L<Class::DBI::Loader::Generic>

=cut

1;

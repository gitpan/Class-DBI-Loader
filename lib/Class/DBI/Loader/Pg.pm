package Class::DBI::Loader::Pg;

use strict;
use base 'Class::DBI::Loader::Generic';
use vars '$VERSION';
use DBI;
use Carp;
require Class::DBI::Pg;
require Class::DBI::Loader::Generic;

$VERSION = '0.18';

=head1 NAME

Class::DBI::Loader::Pg - Class::DBI::Loader Postgres Implementation.

=head1 SYNOPSIS

  use Class::DBI::Loader;

  # $loader is a Class::DBI::Loader::Pg
  my $loader = Class::DBI::Loader->new(
    dsn       => "dbi:Pg:dbname=dbname",
    user      => "postgres",
    password  => "",
    namespace => "Data",
  );
  my $class = $loader->find_class('film'); # $class => Data::Film
  my $obj = $class->retrieve(1);

=head1 DESCRIPTION

See L<Class::DBI::Loader>, L<Class::DBI::Loader::Generic>.

=cut

sub _db_class { return 'Class::DBI::Pg' }

sub _tables {
    my $self = shift;
    my $dbh = DBI->connect( @{ $self->{_datasource} } ) or croak($DBI::errstr);
    my @tables;
    if ( $DBD::Pg::VERSION >= 1.31 ) {
        return $dbh->tables( undef, "public", "", "table",
            { noprefix => 1, pg_noprefix => 1 } );
    }
    else { return $dbh->tables }
}

=head1 SEE ALSO

L<Class::DBI::Loader>, L<Class::DBI::Loader::Generic>

=cut

1;

package Class::DBI::Loader;

use strict;
use vars qw($VERSION);

$VERSION = '0.04';

=head1 NAME

Class::DBI::Loader - dynamic definition of Class::DBI sub classes.

=head1 SYNOPSIS

  use Class::DBI::Loader;

  my $loader = Class::DBI::Loader->new(
    dsn => "dbi:mysql:dbname",
    user => "root",
    password => "",
    namespace => "Data",
  );
  my $class = $loader->find_class('film'); # $class => Data::Film
  my $obj = $class->retrieve(1);

use with mod_perl

in your startup.pl

  # load all tables
  use Class::DBI::Loader;
  my $loader = Class::DBI::Loader->new(
    dsn => "dbi:mysql:dbname",
    user => "root",
    password => "",
    namespace => "Data",
  );

in your web application.

  use strict;

  # you can use Data::Film directly
  my $film = Data::Film->retrieve($id);


=head1 DESCRIPTION

Class::DBI::Loader automate the definition of Class::DBI sub-classes.
scan table schemas and setup columns, primary key.

class names are defined by table names and namespace option.

 +-----------+-----------+-----------+
 |   table   | namespace | class     |
 +-----------+-----------+-----------+
 |   foo     | Data      | Data::Foo |
 |   foo_bar |           | FooBar    |
 +-----------+-----------+-----------+

Class::DBI::Loader supports MySQL, Postgres and SQLite.

=cut

sub new {
    my ( $class, %args ) = @_;
    my $dsn = $args{dsn};
    my ($driver) = $dsn =~ m/^dbi:(\w*?)(?:\((.*?)\))?:/i;
    my $impl = "Class::DBI::Loader::" . $driver;
    eval qq/use $impl/;
    return $impl->new(%args);
}

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 AUTHOR EMERITUS

IKEBE Tomohiro, C<ikebe@edge.co.jp>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI>, L<Class::DBI::mysql>, L<Class::DBI::Pg>, L<Class::DBI::SQLite>

=cut

1;

package Class::DBI::Loader;

use strict;
use vars '$VERSION';

$VERSION = '0.13';

=head1 NAME

Class::DBI::Loader - Dynamic definition of Class::DBI sub classes.

=head1 SYNOPSIS

  use Class::DBI::Loader;

  my $loader = Class::DBI::Loader->new(
    dsn                     => "dbi:mysql:dbname",
    user                    => "root",
    password                => "",
    namespace               => "Data",
    additional_classes      => qw/Class::DBI::AbstractSearch/,
    additional_base_classes => qw/My::Stuff/,
    constraint              => '^foo.*',
    relationships           => 1
  );
  my $class = $loader->find_class('film'); # $class => Data::Film
  my $obj = $class->retrieve(1);

use with mod_perl

in your startup.pl

  # load all tables
  use Class::DBI::Loader;
  my $loader = Class::DBI::Loader->new(
    dsn       => "dbi:mysql:dbname",
    user      => "root",
    password  => "",
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

See L<Class::DBI::Loader::Generic>.

=cut

sub new {
    my ( $class, %args ) = @_;
    my $dsn = $args{dsn};
    my ($driver) = $dsn =~ m/^dbi:(\w*?)(?:\((.*?)\))?:/i;
    $driver = 'SQLite' if $driver eq 'SQLite2';
    my $impl = "Class::DBI::Loader::" . $driver;
    eval qq/use $impl/;
    return $impl->new(%args);
}

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 AUTHOR EMERITUS

IKEBE Tomohiro, C<ikebe@edge.co.jp>

=head1 THANK YOU

Adam Anderson, Dan Kubb, Randal Schwartz, Simon Flack and all the others
who've helped.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI>, L<Class::DBI::mysql>, L<Class::DBI::Pg>, L<Class::DBI::SQLite>,
L<Class::DBI::Loader::Generic>, L<Class::DBI::Loader::mysql>,
L<Class::DBI::Loader::Pg>, L<Class::DBI::Loader::SQLite>

=cut

1;

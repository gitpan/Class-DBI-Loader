package Class::DBI::Loader::mysql;

use strict;
use DBI;
use Carp ();
require Class::DBI::mysql;
require Class::DBI::Loader::Generic;
use base qw(Class::DBI::Loader::Generic);
use vars qw($VERSION);

$VERSION = '0.05';

=head1 NAME

Class::DBI::Loader::mysql - Class::DBI::Loader mysql implementation.

=head1 SYNOPSIS

  use Class::DBI::Loader;

  # $loader is a Class::DBI::Loader::mysql
  my $loader = Class::DBI::Loader->new(
    dsn => "dbi:mysql:dbname",
    user => "root",
    password => "",
    namespace => "Data",
  );
  my $class = $loader->find_class('film'); # $class => Data::Film
  my $obj = $class->retrieve(1);

=head1 DESCRIPTION

please see L<Class::DBI::Loader>

=cut

sub _croak { require Carp; Carp::croak(@_); }

sub _load_classes {
    my $self = shift;
    my $dbh = DBI->connect( @{ $self->_datasource } ) or _croak($DBI::errstr);
    foreach my $table ( $dbh->tables ) {
        my $quoter = $dbh->get_info(29);
        $table =~ s/$quoter//g;
        my $class = $self->_table2class($table);
        no strict 'refs';
        @{"$class\::ISA"} = qw(Class::DBI::mysql);
        $class->set_db( Main => @{ $self->_datasource } );
        $class->set_up_table($table);
        $self->{CLASSES}->{$table} = $class;
    }
    $dbh->disconnect;
}

=head1 SEE ALSO

L<Class::DBI::Loader>

=cut

1;

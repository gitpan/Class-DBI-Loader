package Class::DBI::Loader::Generic;

use strict;
use vars qw($VERSION);
use Carp ();
require Class::Accessor;
use base qw(Class::Accessor);

$VERSION = '0.05';

__PACKAGE__->mk_accessors(qw(_datasource _namespace));

=head1 NAME

Class::DBI::Loader::Generic - generic Class::DBI::Loader implementation.

=head1 SYNOPSIS

ABSTRACT CLASS

=head1 DESCRIPTION

please see L<Class::DBI::Loader>

=cut

sub _croak { require Carp; Carp::croak(@_); }

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {
        _datasource =>
          [ $args{dsn}, $args{user}, $args{password}, $args{options} ],
        _namespace => $args{namespace},
        CLASSES    => {},
    }, $class;
    $self->_load_classes;
    $self;
}

sub _load_classes {
    _croak('ABSTRACT METHOD');
}

sub find_class {
    my ( $self, $table ) = @_;
    return $self->{CLASSES}->{$table};
}

sub classes {
    my $self = shift;
    return sort values %{ $self->{CLASSES} };
}

sub tables {
    my $self = shift;
    return sort keys %{ $self->{CLASSES} };
}

sub _table2class {
    my ( $self, $table ) = @_;
    my $namespace = $self->{_namespace} || "";
    $namespace =~ s/(.*)::$/$1/;
    my $subclass = $table;
    $subclass =~ s/_(\w)/ucfirst($1)/eg;
    my $class =
      $namespace ? "$namespace\::" . ucfirst($subclass) : ucfirst($subclass);
}

=head1 SEE ALSO

L<Class::DBI::Loader>

=cut

1;

package Class::DBI::Loader::Generic;

use strict;
use vars qw($VERSION);
use Carp;
require Class::Accessor;
use base qw(Class::Accessor);

$VERSION = '0.06';

__PACKAGE__->mk_accessors(qw(_datasource _namespace));

=head1 NAME

Class::DBI::Loader::Generic - generic Class::DBI::Loader implementation.

=head1 SYNOPSIS

ABSTRACT CLASS

=head1 DESCRIPTION

please see L<Class::DBI::Loader>

=cut

sub new {
    my ( $class, %args ) = @_;
    my $additional = $args{additional_classes} || [];
    $additional = [$additional] unless ref $additional eq 'ARRAY';
    my $additional_base = $args{additional_base_classes} || [];
    $additional_base = [$additional_base]
      unless ref $additional_base eq 'ARRAY';
    my $self = bless {
        _datasource =>
          [ $args{dsn}, $args{user}, $args{password}, $args{options} ],
        _namespace       => $args{namespace},
        _additional      => $additional,
        _additional_base => $additional_base,
        _constraint      => $args{constraint} || '.*',
        CLASSES          => {},
    }, $class;
    $self->_load_classes;
    $self;
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

sub _db_class { croak "ABSTRACT METHOD" }

sub _load_classes {
    my $self            = shift;
    my @tables          = $self->_tables();
    my $db_class        = $self->_db_class();
    my $additional      = map "use $_;", @{ $self->{_additional} };
    my $additional_base = map "use base '$_';", @{ $self->{_additional_base} };
    my $constraint      = $self->{_constraint};
    foreach my $table (@tables) {
        next unless $table =~ /$constraint/;
        my $class = $self->_table2class($table);
        no strict 'refs';
        @{"$class\::ISA"} = $db_class;
        $class->set_db( Main => @{ $self->_datasource } );
        $class->set_up_table($table);
        $self->{CLASSES}->{$table} = $class;
        eval "package $class;$additional_base$additional";
        croak qq/Couldn't load additional classes "$@"/ if $@;
    }
}

sub _table2class {
    my ( $self, $table ) = @_;
    my $namespace = $self->{_namespace} || "";
    $namespace =~ s/(.*)::$/$1/;
    my $subclass = join '', map ucfirst, split /[\W_]+/, $table;
    my $class = $namespace ? "$namespace\::" . $subclass : $subclass;
}

sub _tables { croak "ABSTRACT METHOD" }

=head1 SEE ALSO

L<Class::DBI::Loader>

=cut

1;

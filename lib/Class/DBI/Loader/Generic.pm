package Class::DBI::Loader::Generic;

use strict;
use vars qw($VERSION);
use Carp;
use Lingua::EN::Inflect;

$VERSION = '0.12';

=head1 NAME

Class::DBI::Loader::Generic - Generic Class::DBI::Loader Implementation.

=head1 SYNOPSIS

See L<Class::DBI::Loader>

=head1 DESCRIPTION

=head2 OPTIONS

Available constructor options are:

=head3 additional_base_classes

List of additional base classes your table classes will use.

=head3 additional_classes

List of additional classes which your table classes will use.

=head3 constraint

Only load tables matching regex.

=head3 debug

Enable debug messages.

=head3 dsn

DBI Data Source Name.

=head3 namespace

Namespace under which your table classes will be initialized.

=head3 password

Password.

=head3 relationships

Try to automatically detect/setup has_a and has_many relationships.

=head3 user

Username.

=head

=head2 METHODS

=cut

sub new {
    my ( $class, %args ) = @_;
    if ( $args{debug} ) {
        no strict 'refs';
        *{"$class\::debug"} = sub { 1 };
    }
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
        _relationships   => $args{relationships},
        CLASSES          => {},
    }, $class;
    $self->_load_classes;
    $self->_relationships if $self->{_relationships};
    $self;
}

=head3 find_class

Returns a tables class.

    my $class = $loader->find_class($table);

=cut

sub find_class {
    my ( $self, $table ) = @_;
    return $self->{CLASSES}->{$table};
}

=head3 classes

Returns a sorted list of classes.

    my $@classes = $loader->classes;

=cut

sub classes {
    my $self = shift;
    return sort values %{ $self->{CLASSES} };
}

=head3 debug

Overload to enable debug messages.

=cut

sub debug { 0 }

=head3 tables

Returns a sorted list of tables.

    my @tables = $loader->tables;

=cut

sub tables {
    my $self = shift;
    return sort keys %{ $self->{CLASSES} };
}

# Overload in your driver class
sub _db_class { croak "ABSTRACT METHOD" }

# Setup has_a and has_many relationships
sub _has_a_many {
    my ( $self, $table, $column, $other ) = @_;
    my $table_class = $self->find_class($table);
    my $other_class = $self->find_class($other);
    warn qq/Has_a relationship "$table_class", "$column" -> "$other_class"/
      if $self->debug;
    $table_class->has_a( $column => $other_class );
    my ($table_class_base) = $table_class =~ /.*::(.+)/;
    my $plural = Lingua::EN::Inflect::PL( lc $table_class_base );
    warn qq/Has_many relationship "$other_class", "$plural" -> "$table_class"/
      if $self->debug;
    $other_class->has_many( $plural => $table_class );
}

# Load and setup classes
sub _load_classes {
    my $self            = shift;
    my @tables          = $self->_tables();
    my $db_class        = $self->_db_class();
    my $additional      = join '', map "use $_;", @{ $self->{_additional} };
    my $additional_base = join '', map "use base '$_';",
      @{ $self->{_additional_base} };
    my $constraint = $self->{_constraint};
    foreach my $table (@tables) {
        next unless $table =~ /$constraint/;
        warn qq/Found table "$table"/ if $self->debug;
        my $class = $self->_table2class($table);
        warn qq/Initializing "$class"/ if $self->debug;
        no strict 'refs';
        @{"$class\::ISA"} = $db_class;
        $class->set_db( Main => @{ $self->{_datasource} } );
        $class->set_up_table($table);
        $self->{CLASSES}->{$table} = $class;
        my $code = "package $class;$additional_base$additional";
        warn qq/Additional classes are "$code"/ if $self->debug;
        eval $code;
        croak qq/Couldn't load additional classes "$@"/ if $@;
    }
}

# Find and setup relationships
sub _relationships {
    my $self = shift;
    foreach my $table ( $self->tables ) {
        my $dbh = $self->find_class($table)->db_Main;
        if ( my $sth = $dbh->foreign_key_info( '', '', '', '', '', $table ) ) {
            for my $res ( @{ $sth->fetchall_arrayref( {} ) } ) {
                my $column = $res->{FK_COLUMN_NAME};
                my $other  = $res->{UK_TABLE_NAME};
                $self->_has_a_many( $table, $column, $other );
            }
        }
    }
}

# Make a class from a table
sub _table2class {
    my ( $self, $table ) = @_;
    my $namespace = $self->{_namespace} || "";
    $namespace =~ s/(.*)::$/$1/;
    my $subclass = join '', map ucfirst, split /[\W_]+/, $table;
    my $class = $namespace ? "$namespace\::" . $subclass : $subclass;
}

# Overload in driver class
sub _tables { croak "ABSTRACT METHOD" }

=head1 SEE ALSO

L<Class::DBI::Loader>, L<Class::DBI::Loader::mysql>, L<Class::DBI::Loader::Pg>,
L<Class::DBI::Loader::SQLite>

=cut

1;

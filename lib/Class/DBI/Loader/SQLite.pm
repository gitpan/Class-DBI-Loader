package Class::DBI::Loader::SQLite;
# $Id: SQLite.pm,v 1.2 2002/08/26 08:16:41 ikechin Exp $
use strict;
use DBI;
use Carp ();
require Class::DBI::SQLite;
require Class::DBI::Loader::Generic;
use base qw(Class::DBI::Loader::Generic);
use vars qw($VERSION);

$VERSION = '0.01';

sub _croak { require Carp; Carp::croak(@_); }
sub _load_classes {
    my $self = shift;
    my $dbh = DBI->connect(@{$self->_datasource}) or _croak($DBI::errstr);
    my $sth = $dbh->prepare("SELECT * FROM sqlite_master");
    $sth->execute;
    my @tables;
    while (my $row = $sth->fetchrow_hashref) {
	next unless lc($row->{type}) eq 'table';
	push @tables, $row->{tbl_name};
    }
    $sth->finish;
    $dbh->disconnect;
    foreach my $table(@tables) {
	my $class = $self->_table2class($table);
	no strict 'refs';
	@{"$class\::ISA"} = qw(Class::DBI::SQLite);
	$class->set_db(Main => @{$self->_datasource});
	$class->set_up_table($table);
	$self->{CLASSES}->{$table} = $class;
    }
    $dbh->disconnect;
}

1;

__END__

=head1 NAME

Class::DBI::Loader::SQLite - Class::DBI::Loader SQLite implementation.

=head1 SYNOPSIS

  use Class::DBI::Loader;

  # $loader is a Class::DBI::Loader::SQLite
  my $loader = Class::DBI::Loader->new(
    dsn => "dbi:SQLite:dbname=/path/to/dbfile",
    namespace => "Data",
  );
  my $class = $loader->find_class('film'); # $class => Data::Film
  my $obj = $class->retrieve(1);

=head1 DESCRIPTION

please see L<Class::DBI::Loader>

=head1 AUTHOR

IKEBE Tomohiro E<lt>ikebe@edge.co.jpE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI::Loader>

=cut
use strict;
use Test::More tests => 6;

use Class::DBI::Loader;

my $dbh;
SKIP: {
    eval {
	require Class::DBI::mysql;
    };
    skip "Class::DBI::mysql is not installed", 6 if $@;

    print STDERR "\n";
    my $hostname = read_input("please specify the MySQL host");
    my $database = read_input("please specify the writable MySQL database");
    my $user = read_input("please specify the mysql username");
    my $password = read_input("please specify the mysql password");
    my $dsn = "dbi:mysql:$database;host=$hostname";
    $dbh = DBI->connect($dsn, $user, $password, { 
	RaiseError => 1,
	PrintError => 1
    });

    $dbh->do(<<'SQL');
CREATE TABLE loader_test1 (
    id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
    dat VARCHAR(32)
)
SQL

    my $sth = $dbh->prepare(<<"SQL");
INSERT INTO loader_test1 (dat) VALUES(?)
SQL
    for my $dat(qw(foo bar baz)){
	$sth->execute($dat);
	$sth->finish;
    }

    $dbh->do(<<'SQL');
CREATE TABLE loader_test2 (
    id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
    dat VARCHAR(32)
)
SQL

    $sth = $dbh->prepare(<<"SQL");
INSERT INTO loader_test2 (dat) VALUES(?)
SQL
    for my $dat(qw(aaa bbb ccc ddd)){
	$sth->execute($dat);
	$sth->finish;
    }
    $sth->finish;

    my $loader = Class::DBI::Loader->new(
	dsn => $dsn, 
	user => $user, 
	password => $password,
    );
    is($loader->find_class("loader_test1"), "LoaderTest1");
    is($loader->find_class("loader_test2"), "LoaderTest2");
    my $class1 = $loader->find_class("loader_test1");
    my $obj = $class1->retrieve(1);
    is($obj->id, 1);
    is($obj->dat, "foo");
    my $class2 = $loader->find_class("loader_test2");
    is($class2->retrieve_all, 4);
    my($obj2) = $class2->search(dat => 'bbb');
    is($obj2->id, 2)
}

sub read_input {
    my $prompt = shift;
    print STDERR "$prompt: ";
    my $value = <STDIN>;
    chomp $value;
    return $value;
}

END {
    if ($dbh) {
	$dbh->do("DROP TABLE loader_test1");
	$dbh->do("DROP TABLE loader_test2");
	$dbh->disconnect;
    }
}

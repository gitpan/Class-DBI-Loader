use strict;
use Test::More tests => 6;

use Class::DBI::Loader;
use DBI;

my $dbh;
SKIP: {

    eval { require Class::DBI::SQLite; };
    skip "Class::DBI::SQLite is not installed", 6 if $@;

    my $database = './t/sqlite_test';

    my $dsn = "dbi:SQLite:dbname=$database";
    $dbh = DBI->connect(
        $dsn, "", "",
        {
            RaiseError => 1,
            PrintError => 1,
            AutoCommit => 1
        }
    );

    $dbh->do(<<'SQL');
CREATE TABLE loader_test1 (
    id INTEGER NOT NULL PRIMARY KEY ,
    dat TEXT
)
SQL

    my $sth = $dbh->prepare(<<"SQL");
INSERT INTO loader_test1 (dat) VALUES(?)
SQL
    for my $dat (qw(foo bar baz)) {
        $sth->execute($dat);
        $sth->finish;
    }

    $dbh->do(<<'SQL');
CREATE TABLE loader_test2 (
    id INTEGER NOT NULL PRIMARY KEY,
    dat TEXT
)
SQL

    $sth = $dbh->prepare(<<"SQL");
INSERT INTO loader_test2 (dat) VALUES(?)
SQL
    for my $dat (qw(aaa bbb ccc ddd)) {
        $sth->execute($dat);
        $sth->finish;
    }

    my $loader = Class::DBI::Loader->new(
        dsn       => $dsn,
        namespace => 'SQLiteTest',
    );
    is( $loader->find_class("loader_test1"), "SQLiteTest::LoaderTest1" );
    is( $loader->find_class("loader_test2"), "SQLiteTest::LoaderTest2" );
    my $class1 = $loader->find_class("loader_test1");
    my $obj    = $class1->retrieve(1);
    is( $obj->id,  1 );
    is( $obj->dat, "foo" );
    my $class2 = $loader->find_class("loader_test2");
    is( $class2->retrieve_all, 4 );
    my ($obj2) = $class2->search( dat => 'bbb' );
    is( $obj2->id, 2 );

    $class1->db_Main->disconnect;
    $class2->db_Main->disconnect;
}

END {
    unlink './t/sqlite_test';
}

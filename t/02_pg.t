use strict;
use Test::More tests => 6;

use Class::DBI::Loader;
use DBI;

my $dbh;
SKIP: {

    eval { require Class::DBI::Pg; };
    skip "Class::DBI::Pg is not installed", 6 if $@;

    print STDERR "\n";
    my $database = read_input("please specify the writable Postgres database");
    my $user     = read_input("please specify the Postgres Postgres username");
    my $password = read_input("please specify the Postgres Postgres password");

    my $dsn = "dbi:Pg:dbname=$database";
    $dbh = DBI->connect(
        $dsn, $user,
        $password,
        {
            RaiseError => 1,
            PrintError => 1,
            AutoCommit => 1
        }
    );

    $dbh->do(<<'SQL');
CREATE TABLE loader_test1 (
    id SERIAL NOT NULL PRIMARY KEY ,
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
    id SERIAL NOT NULL PRIMARY KEY,
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
        user      => $user,
        password  => $password,
        namespace => 'PgTest',
    );
    is( $loader->find_class("loader_test1"), "PgTest::LoaderTest1" );
    is( $loader->find_class("loader_test2"), "PgTest::LoaderTest2" );
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
        $dbh->do("DROP SEQUENCE loader_test1_id_seq");
        $dbh->do("DROP SEQUENCE loader_test2_id_seq");
        $dbh->disconnect;
    }
}

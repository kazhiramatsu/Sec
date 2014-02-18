package main;
use strict;
use warnings; 
use Test::More;
use Sec::Util ();
use Sec::DBI;
use Data::Dumper;
use Test::Exception::LessClever;

my $config = Sec::Util::load_file("eg/sense/config/config.pl"); 
my $dbi = Sec::DBI->new(connect_info => $config->{connect_info}); 
my $now = Sec::Util::now();

my $datas = [
    {
        user_id => 'a', username => 'b', password => 'c', email => 'd',
        created_on => $now, updated_on => $now 
    },
    {
        user_id => 'e', username => 'f', password => 'g', email => 'h',
        created_on => $now, updated_on => $now 
    },

];

subtest "should establish a database connection" => sub {
    isa_ok $dbi, 'Sec::DBI'; 
    my $ret = $dbi->dbh;
#    print STDERR Dumper($dbh);
    isa_ok $ret, 'DBI::db'; 
};

subtest "should drop users table"  => sub {
    my $sqls = Sec::Util::load_sql("eg/sense/sql/drop_users.sql"); 
    for my $sql (@$sqls) {
        my $ret = $dbi->do($sql);
        #   print STDERR Dumper($ret);
        is $ret, '0E0';
    }
};

subtest "should create users table"  => sub {
    my $sqls = Sec::Util::load_sql("eg/sense/sql/create_users.sql"); 
    for my $sql (@$sqls) {
        my $ret = $dbi->do($sql);
        #   print STDERR Dumper($ret);
        is $ret, '0E0';
    }
};

subtest "should insert users table"  => sub {
    for my $data (@$datas) {
        lives_ok {
            $dbi->insert(
                'users',
                $data
            );
        };
    }
};

subtest "should select users table"  => sub {
    for my $data (@$datas) {
        my $users = $dbi->find_by_sql(
            "select * from users where user_id = :id",
            { id => $data->{user_id}}
        );
        is ref $users, 'ARRAY'; 
        is scalar @$users, 1; 

        my $user = shift @$users;
        is_deeply $user, $data; 
    }
};

subtest "should select users table for all"  => sub {
    my $users = $dbi->find_by_sql(
        "select * from users",
    );
    is ref $users, 'ARRAY'; 
    is scalar @$users, 2; 

    for (my $i = 0; $i < 2; $i++) {
        is_deeply $users->[$i], $datas->[$i]; 
    }
};

subtest "should update users table"  => sub {
    my $updated_on = Sec::Util::now();
    lives_ok {
        $dbi->update(
            'users',
            { user_id => 'x', updated_on => $updated_on},
            "user_id = :id",
            {id => 'a'}
        );
    };

    my $users = $dbi->find_by_sql(
        "select * from users where user_id = :id",
        {id => 'x'}
    );
    is ref $users, 'ARRAY'; 
    is scalar @$users, 1; 

    my $update_data = {
        user_id => 'x', username => 'b', password => 'c', email => 'd',
        created_on => $now, updated_on => $updated_on 
    };
    my $user = shift @$users;
    is_deeply $user, $update_data; 
};

subtest "should delete users table"  => sub {
    lives_ok {
        $dbi->delete(
            'users',
            "user_id = :id",
            {id => 'x'}
        );
    };
    my $users = $dbi->find_by_sql(
        "select * from users where user_id = :id",
        {id => 'x'}
    );
    is $users, undef; 
};

done_testing;

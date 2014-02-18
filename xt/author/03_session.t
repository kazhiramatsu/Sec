package main;
use strict;
use warnings; 
use Test::More;
use Test::Exception::LessClever;
use Test::Time time => 1362679200; # Thu, 07 Mar 2013 18:00:00 GMT   
use Sec::Util ();
use Sec::Session;
use Sec::Session::Store::DBI;
use Sec::Session::State::Cookie;

my $config = Sec::Util::load_file("eg/sense/config/config.pl"); 

my $env = {
    HTTP_COOKIE => undef,
};

my $session = Sec::Session->new(
    store => Sec::Session::Store::DBI->new(
        connect_info => $config->{connect_info},
        table => 'sessions',
    ),
    state => Sec::Session::State::Cookie->new(
        name => 'sense_session',
        env => $env,
    ),
);


my $now = Sec::Util::date_format_mysql(time);

my $datas = [
    {
        session_id => 'a', session_data => 'b', session_expire => 'c',
        created_on => $now, updated_on => $now 
    },
    {
        session_id => 'a', session_data => 'b', session_expire => 'c',
        created_on => $now, updated_on => $now 
    },

];

subtest "should drop sessions table"  => sub {
    my $sqls = Sec::Util::load_sql("eg/sense/sql/drop_sessions.sql"); 
    for my $sql (@$sqls) {
        my $ret = $session->store->do($sql);
        #   print STDERR Dumper($ret);
        is $ret, '0E0';
    }
};

subtest "should create sessions table"  => sub {
    my $sqls = Sec::Util::load_sql("eg/sense/sql/create_sessions.sql"); 
    for my $sql (@$sqls) {
        my $ret = $session->store->do($sql);
        #   print STDERR Dumper($ret);
        is $ret, '0E0';
    }
};

subtest "should session value"  => sub {
    $session->start;
    $session->set(a => 1);
    $session->set(b => 2);
    my $a = $session->get('a');
    is $a, 1;
    my $b = $session->get('b');
    is $b, 2;

    $session->save($session->data);
    $a = $session->get('a');
    $b = $session->get('b');
    is $a, 1;
    is $b, 2;
};

subtest "should expire sessions"  => sub {
    sleep $session->expire-1;
    my $data = $session->read;
    is $data->{a}, 1;
    is $data->{b}, 2;

    sleep 1;
    $data = $session->read;
    isnt $data->{a}, 1;
    isnt $data->{b}, 2;
};

done_testing;

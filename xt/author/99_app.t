package main;
use strict;
use warnings; 
use Test::More;
use Plack::Test;
use Text::Xslate;
use Hash::MultiValue;
use Encode ();
use lib qw(eg/sense/lib);
use Cwd ();
use Sec::DBI;
use Sec::Util ();
use Sense;
use Data::Dumper;

use constant APP_ROOT => Cwd::getcwd . '/eg/sense';
use constant HOST => 'http://0:5001';

#my $config = Sec::Config->new(app_root => APP_ROOT);

my $sense = Sense->new(
    app_root => APP_ROOT 
    #config => $config
);

my $path = APP_ROOT.'/views';
my $xslate = Text::Xslate->new(
    cache => 0,
    path => [$path]
);

my $app = $sense->psgi_app;

my $config = Sec::Util::load_file("eg/sense/config/config.pl"); 
#my $toml = Sec::Util::slurp("eg/sense/config/database.toml"); 
# my $dbconfig = from_toml($toml);
# print STDERR Dumper($dbconfig);
my $dbi = Sec::DBI->new(connect_info => $config->{connect_info}); 
my $now = Sec::Util::now();

my $expires = Sec::Util::date_format_mysql(time+60*60*24*30);

my $data = {
    session_id => '123456789abcd', session_data => "{}", session_expire => $expires,
    created_on => $now, updated_on => $now 
};

$dbi->do('truncate sessions');
$dbi->do('truncate users');

$dbi->insert(
    'sessions',
    $data
);

subtest "GET /" => sub {
    my $html = Encode::encode_utf8($xslate->render('index/index.tx'));

    test_psgi( 
        app => $app,
        client => sub {
            my $cb = shift;
            my $req = HTTP::Request->new(GET => HOST.'/');
            $req->header('COOKIE' => "sense_session=123456789abcd");
            my $res = $cb->($req);
            is $res->content, $html;
        }
    );
};

subtest "GET /users" => sub {
    my $html = Encode::encode_utf8($xslate->render('users/index.tx'));

    test_psgi( 
        app => $app,
        client => sub {
            my $cb = shift;
            my $req = HTTP::Request->new(GET => HOST."/users");
            $req->header('COOKIE' => "sense_session=123456789abcd");
            my $res = $cb->($req);
            is $res->content, $html;
        }
    );
};

subtest "POST /users/confirm" => sub {

    my $params = {
        params => { 
            username => 'test',    
            email    => 'email',
            password => 'pass',
            user_id => 'abc',
        }
    };

    my @params=();
    my $p = $params->{params};
    for my $s (keys %{$p}) {
        push @params, "$s=$p->{$s}"; 
    }
    my $content = join '&', @params;
    my $html = Encode::encode_utf8($xslate->render('users/confirm.tx', $params));

    test_psgi( 
        app => $app,
        client => sub {
            my $cb = shift;
            my $req = HTTP::Request->new(POST => HOST."/users/confirm");
            $req->header('COOKIE' => "sense_session=123456789abcd");
            $req->content_type('application/x-www-form-urlencoded');
            $req->content($content);
            my $res = $cb->($req);
            is $res->content, $html;
        }
    );
};

subtest "POST /users/complete" => sub {

    my $params = {
        params => { 
            username => 'test',    
            email    => 'email',
            password => 'pass',
            user_id => 'abc',
        }
    };

    my @params=();
    my $p = $params->{params};
    for my $s (keys %{$p}) {
        push @params, "$s=$p->{$s}"; 
    }
    my $content = join '&', @params;
    my $html = Encode::encode_utf8($xslate->render('users/complete.tx', $params));

    test_psgi( 
        app => $app,
        client => sub {
            my $cb = shift;
            my $req = HTTP::Request->new(POST => HOST."/users/complete");
            $req->header('COOKIE' => "sense_session=123456789abcd");
            $req->content_type('application/x-www-form-urlencoded');
            $req->content($content);
            my $res = $cb->($req);
            is $res->content, $html;
        }
    );
};

done_testing;

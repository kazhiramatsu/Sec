package Sec::Lite;
use strict;
use warnings;
use parent qw(Sec);

sub import {
    my $caller = caller;

    my $sec = Sec->new;

    add_method(
        $caller,
        'get',
        sub {
            my ($url, $code) = @_;
            check_args($url, $code);
            $sec->router->add(
                $url,
                {
                    controller => 'Sec::Controller::Lite',     
                    action => $code
                },
                {
                    method => 'GET'
                }
            );
        }
    );

    add_method(
        $caller,
        'post',
        sub {
            my ($url, $code) = @_;
            check_args($url, $code);
            $sec->router->connect(
                $url,
                {
                    controller => 'Sec::Controller::Lite',     
                    action => $code
                },
                {
                    method => 'POST'
                }
            );
        }
    );

    add_method(
        $caller,
        'psgi_app',
        sub {
            $sec->psgi_app
        }
    );
}

sub check_args {
    my ($path, $code) = @_;
    $path or croak("You must provide a path for the request");
    $code or croak("You must provide a code for the request");
}

sub add_method {
    my ($pkg, $name, $code) = @_;
    no strict 'refs';
    *{"${pkg}::${name}"} = $code;
}

1;

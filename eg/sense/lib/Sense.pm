package Sense;
use strict;
use warnings;
use Plack::Builder;
use parent qw(Sec);

sub startup {
    my $self = shift;

    $self->router->connect('/', {controller => 'Index',action => 'index'});

    $self->router->connect('/users', {controller => 'Users', action => 'index'});
    $self->router->connect('/users/confirm', {controller => 'Users', action => 'confirm'});
    $self->router->connect('/users/complete', {controller => 'Users', action => 'complete'});
    $self->router->connect('/users/register', {controller => 'Users', action => 'register'});
    $self->router->connect('/users/finish', {controller => 'Users', action => 'finish'});

    $self->router->connect('/sessions', {controller => 'Sessions', action => 'index'});
    $self->router->connect('/sessions/complete', {controller => 'Sessions', action => 'complete'});
    $self->router->connect('/sessions/logout', {controller => 'Sessions', action => 'logout'});
}

sub psgi_app {
    my $self = shift;

    my $app = $self->to_app;

    # ./public/static配下にファイルを置く
    # ./public配下ではない
    # URLは/staticでアクセス
    builder {
        enable 'Plack::Middleware::Static',
        path => qr{^/static},
        root => $self->app_root.'/public';
        $app;
    };
}

1;

package Sense::Controller::Users;
use strict;
use warnings;
use parent qw(Sense::Controller);
use Sec::Accessor;
use Sense::Util qw(password_hash);
use Sense::Model::User;
use Sec::Session;
use Sec::Session::Store::DBI;
use Sec::Session::State::Cookie;
use Try::Tiny;

has 'user' => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        Sense::Model::User->new(connect_info => $self->config->{connect_info});
    }
);

sub index {
    my $self = shift;

}

sub confirm {
    my $self = shift;

    $self->stash(
        params => $self->req->params
    );

    $self->session->save({user => $self->req->params});
    $self->session->finalize($self->res);
}


sub complete {
    my $self = shift;

    my $data = $self->session->data;
    unless ($data->{user}) {
        $self->stash(session_expires => 1);
        return $self->render('users/index.tx');
    }
    $self->user->insert($data->{user});
}

1;

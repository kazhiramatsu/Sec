package Sec::Controller::Error;
use strict;
use warnings;
use parent qw(Sec::Controller);
use Sec::Response;

sub render_404 {
    my $self = shift;

    $self->no_render(1);
    $self->res->body("404 not found");
}

1;

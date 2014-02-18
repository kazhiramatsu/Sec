package Sense::Controller;
use strict;
use warnings;
use parent qw(Sec::Controller);
use Sec::Accessor;
use Sec::Session;
use Sec::Session::Store::DBI;
use Sec::Session::State::Cookie;

has 'session' => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $s = Sec::Session->new(
            store => Sec::Session::Store::DBI->new(
                connect_info => $self->config->{connect_info},
                table => 'sessions',
            ),
            state => Sec::Session::State::Cookie->new(
                name => 'sense_session',
                env => $self->env,
            ),
        );
        $s->start;
        $s;
    }
);

1;

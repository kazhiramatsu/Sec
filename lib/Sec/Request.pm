package Sec::Request;
use strict;
use warnings;
use parent qw(Plack::Request);
use Sec::Object::Apply;
use Encode();
use Sec::Accessor;

sub param {
    my $self = shift;
    my $val = $self->SUPER::param(@_);
    my $upgrader = Sec::Object::Apply->new(apply_blessed => 1)->apply(sub { Encode::decode_utf8(shift); });
    $upgrader->($val);
}

has 'params' => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        $self->parameters->as_hashref;
    }
);

has 'parameters' => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $params = $self->SUPER::parameters;
        my $upgrader = Sec::Object::Apply->new(apply_blessed => 1)->apply(sub { Encode::decode_utf8(shift); });
        $upgrader->($params);
    }
);

1;

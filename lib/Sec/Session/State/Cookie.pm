package Sec::Session::State::Cookie;
use Sec::Accessor;
use Sec::Cookie;
use Digest::SHA qw(sha256_hex); 
use Time::HiRes qw(gettimeofday);

has 'env' => (
    is => 'ro',
    lazy => 1,
    default => sub {
        {};
    }
);

has 'name' => (
    is => 'rw',
    lazy => 1,
    default =>  sub {
        "sec_session";
    }
);

has 'exists' => (
    is => 'rw',
    lazy => 1,
    default => sub {
        0;
    }
);

has 'session_length' => ( 
    is => 'rw',
    default => 32,
);

has 'id' => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        if ($self->env->{HTTP_COOKIE}) {
            my $c = Sec::Cookie->eat($self->env->{HTTP_COOKIE});
            my $session_id = $c->{$self->name}->{value};
        }
    }
);

has 'expire' => (
    is => 'rw',
    default => 60*60*24*30
);

sub generate_id {
    my $self = shift;
    my $unique = $ENV{UNIQUE_ID} || [] . rand();
    return substr(sha256_hex(gettimeofday . $unique), 0, $self->session_length);
}

sub finalize {
    my ($self, $res, $options) = @_;

    $res->cookies({
        $self->name => {
            value => $self->id,
            expires => time+$self->expire,
            path => '/'
        }
    });
}

1;

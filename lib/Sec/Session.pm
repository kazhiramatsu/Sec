package Sec::Session;
use Sec::Accessor;
use Sec::Cookie;
use Digest::SHA qw(sha256_hex); 
use Time::HiRes qw(gettimeofday);

has 'exists' => (
    is => 'rw',
    lazy => 1,
    default => sub {
        0;
    }
);

has 'store' => (
    is => 'rw',
    lazy => 1,
    default => sub {}
);

has 'state' => (
    is => 'rw',
    lazy => 1,
    default => sub {}
);

has 'data' => (
    is => 'rw',
    lazy => 1,
    default => sub {
        {};
    }
);

sub id {
    my ($self, $id) = @_;

    $id ? $self->state->id($id) : $self->state->id;
}

sub regenerate_id {
    my ($self) = @_;

    $self->state->id($self->state->generate_id);
    $self->data({});
}

sub get {
    my ($self, $key) = @_;
    $self->data->{$key};
}

sub set {
    my ($self, $key, $value) = @_;
    $self->data->{$key} = $value;
}

sub start {
    my $self = shift;

    $self->state->id($self->state->generate_id) unless $self->state->id;
    $self->data($self->read);
}

sub write {
    my ($self, $session) = @_;

    $self->store->store($self->state->id, $session, $self->state->expire);
}

sub read {
    my $self = shift;

    my $data = $self->store->fetch($self->state->id);
    if ($data) {
        $self->exists(1);
        return $data;
    } else {
        return {};
    }
}

sub save {
    my ($self, $session) = @_;

    $self->store->save($self->state->id, $session, $self->state->expire);
}

sub destroy {
    my ($self, $res) = @_;

    $self->store->delete($self->state->id);

    $res->cookies({
        $self->state->name => {
            value => "",
            expires => 0,
        }
    });
}

sub expire {
    my ($self, $expire) = @_;

    defined $expire ? $self->state->expire($expire) : $self->state->expire;
}

sub finalize {
    my ($self, $res) = @_;
    $self->state->finalize($res);
}

1;

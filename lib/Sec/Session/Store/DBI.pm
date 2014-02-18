package Sec::Session::Store::DBI;
use parent qw(Sec::DBI);
use Sec::Accessor;
use Perl6::Perl qw(perl);
use Sec::Util ();

has 'table' => (
    is => 'rw',
    default => sub {
        'sessions'; 
    }  
);

has 'serializer' => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        sub { perl(shift); }; 
#        sub { JSON::XS->new->encode(shift||{}); }; 
    }
);

has 'deserializer' => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        sub { eval(perl(shift)); };
#        sub { JSON::XS->new->decode($d); }; 
    }
);

sub fetch {
    my ($self, $session_id) = @_;

    my ($data) = $self->find_by_sql(
        "select * from ".$self->table." where session_id = :id and session_expire > :now",
        {id => $session_id, now => $self->now }
    );
    $data ? $self->deserializer->($data->{session_data}) : ();
}

sub store {
    my ($self, $session_id, $session, $expire) = @_;

    my $table = $self->table;
    
    my $value = {
        session_id => $session_id,
        session_expire => $self->session_expire($expire),
        session_data => $self->serializer->($session),
        created_on => $self->now,
    };
    
    $self->insert(
        $self->table,
        $value
    ); 
}

sub save {
    my ($self, $session_id, $session, $expire) = @_;

    my $table = $self->table;
   
    my $value = {
        session_id => $session_id,
        session_expire => $self->session_expire($expire),
        session_data => $self->serializer->($session),
    };

    if ($self->fetch($session_id)) {
        $value->{updated_on} = $self->now;
        $self->update(
            $self->table,
            $value,
            "session_id = :id and session_expire > :now",
            {
                id => $session_id,
                now => $self->now
            }
        );
    } else {
        $value->{created_on} = $self->now;
        $self->insert(
            $self->table,
            $value
        ); 
    }
}

sub session_expire {
    my ($self, $expire) = @_;
    Sec::Util::date_format_mysql(time+$expire);
}

sub now {
    Sec::Util::date_format_mysql(time);
}

sub delete {
    my ($self, $session_id) = @_;

    $self->SUPER::delete(
        $self->table,
        "session_id = :id",
        { id => $session_id }
    ); 
}

1;

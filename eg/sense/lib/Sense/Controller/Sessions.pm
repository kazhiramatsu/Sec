package Sense::Controller::Sessions;
use parent qw(Sense::Controller); 
use Sec::Accessor;
use Sense::Model::Session;
use Sense::Model::User;

has 'user' => (
    is => 'rw', 
    lazy => 1,    
    default => sub {
        my $self = shift;
        Sense::Model::User->new(connect_info => $self->config->{connect_info}); 
    }
);

sub index {
    my $self = shift;

    $self->session->finalize($self->res);
}

sub complete {
    my $self = shift;

    my $user_id = $self->req->param('user_id');
    my $password = $self->req->param('password');
   
    if (my $user = $self->user->find_by_user($self->config->{salt}, $user_id, $password)) {
        $self->session->regenerate_id;
        $self->session->write({user => $user});
        $self->session->finalize($self->res);
    } else {
        $self->stash(is_not_registered => 1, params => $self->req->params);
        return $self->render("sessions/index.tx");
    }
}

1;

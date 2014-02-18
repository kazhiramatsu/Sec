use lib 'lib';
use Sec::Lite;

get '/' => sub {
    my $self = shift;
    $self->render('index/index.tx');
};

get '/sessions' => sub {
    my $self = shift;

    $self->render('sessions/index.tx');
};

psgi_app;


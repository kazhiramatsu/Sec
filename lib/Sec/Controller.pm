package Sec::Controller;
use strict;
use warnings;
use Encode ();
use Module::Load;
use parent qw(Sec::Trigger);
use Sec::Accessor;
use File::Basename qw(basename);
use Carp ();

has 'app_root' => (
    is => 'rw', 
    lazy => 1,
    default => sub {
        my $self = shift;
        Cwd::getcwd;
    }
);

has 'config' => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
    }
);

has 'env' => (
    is => 'rw',
    required => 1
);

has 'routes' => (
    is => 'rw',
    required => 1
);

has 'dispatched' => (
    is => 'rw',
    default => 1
);

has 'validator' => (
    is => 'rw',
    lazy => 1,
    default => sub {
        load "Sec::Validator";
        Sec::Validator->new;
    }
);

has 'view' => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        load "Text::Xslate"; 
        Text::Xslate->new(
            syntax => $self->config->{view}->{syntax} || 'Kolon',
            cache => $self->config->{view}->{cache} || 0,
            path => $self->config->{view}->{path}
                    || [$self->app_root.'/views']
        );
    }
);

has 'req' => (
    is => 'rw',
    lazy => 1, 
    default => sub { 
        my $self = shift;
        load "Sec::Request";
        Sec::Request->new($self->env);
    }
);

has 'res' => (
    is => 'rw',
    lazy => 1,
    default => sub { 
        my $self = shift;
        load "Sec::Response";
        my $r = Sec::Response->new();
    }
);

has 'no_render' => (
    is => 'rw',
    lazy => 1,
    default => sub {
        0;
    }
);

has 'rendered' => (
    is => 'rw',
    lazy => 1,
    default => sub {
        0;
    }
);

sub param {
    my $self = shift;
    $self->req->param(@_);
}

sub parameters {
    my $self = shift;
    $self->req->parameters(@_);
}

sub params {
    my $self = shift;
    $self->req->params(@_);
}

sub redirect {
    my $self = shift;
    $self->no_render(1);
    $self->res->redirect(@_);
}

sub forward {
    my $self = shift;
    my %args = @_;

    if ($args{controller}) {
        $self->routes->{controller} = $args{controller};
        my $name = $args{controller};
        my $pkg = ($name =~ /^\+/ ? substr($name, 1) : $name);
        $self->routes->{package} = $pkg;
#        $self->routes->{shortname} = lcfirst((split(/(?<=::)/, $args{controller}))[-1]);
    }

    if ($args{action}) {
        $self->routes->{action} = $args{action}; 
    }

    $self->dispatched(0);
}

sub stash {
    my $self = shift;
     
    if (scalar @_ == 0) {
        $self->{vars} ||= {};
    } else {
        my %args = @_;
        for my $k (keys %args) {
            $self->{vars}->{$k} = $args{$k};
        }
    }
}

sub render {
    my $self = shift;

    $self->rendered(1);
    if ($_[0] eq 'json') {
        $self->no_render(1);
        load "JSON"; 
        my $body = JSON::encode_json($_[1]);
        return $body;
    }
    my $body = $self->view->render(shift, shift||$self->stash);
    Encode::encode_utf8($body);
}

sub finalize {
    my $self = shift;
    my $res = shift;
    
    if (!$self->no_render && !$self->rendered) {
        my $c = $self->routes->{controller};
        $c =~ s/::/\//g;
        $res = $self->render(
            lc($c).'/'.$self->routes->{action}.'.'.($self->config->{view}->{ext}||'tx')
        );
        $self->res->body($res);
    } elsif ($self->rendered) {
        $self->res->body($res);
    }
    $self->call_trigger('before_finalize', $self);
    $self->res->finalize;
}

sub dump {
    my $self = shift;
    load "Data::Dumper";
    my $d = Data::Dumper->new([@_]);
    print STDERR $d->Dump;
}

1;

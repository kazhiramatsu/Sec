package Sec;
use strict;
use 5.008_005;
our $VERSION = '0.01';

use Sec::Accessor;
use Module::Load;
use Carp ();
use Cwd ();
use File::Basename qw(basename);
#use DB;
#use Devel::NYTProf;

has 'config' => (
    is => 'rw', 
    lazy => 1,
    default => sub {
        my $self = shift;
        my $path = $self->app_root . '/config/config.pl';
        load "Sec::Util";
        Sec::Util::load_file($path);
    }
);

has 'app_root' => (
    is => 'rw', 
    lazy => 1,
    default => sub {
        my $self = shift;
        Cwd::getcwd;
    }
);

has 'namespace' => (
    is => 'rw', 
    lazy => 1,
    default => sub {
        my $self = shift;
        ucfirst(basename($self->app_root))."::Controller";
    }
);

has 'env' => (
    is => 'rw',    
);

has 'routes' => (
    is => 'rw',    
);

has 'router' => (
    is => 'rw', 
    lazy => 1,
    default => sub {
        my $self = shift;
        load "Router::Simple";
        my $router = Router::Simple->new;
        $router;
    }
);

has 'not_found' => (
    is => 'rw', 
    lazy => 1,
    default => sub {
        my $self = shift;
        my $routes = {
            controller => '+Sec::Controller::Error',
            action => 'render_404',
        };
    }
);

# sub run {
#     my $self = shift;
#     my $env = shift;
#
# #    DB::enable_profile;
#     my $app = $self->handle_request($env);
# #    DB::disable_profile;
#     $app;
# }

sub add_route {
    my $self = shift;
    $self->router->add(@_);
}

sub get_package {
    my ($self, $name) =  @_;

    $name =~ /^\+/ ? substr($name, 1) : $self->namespace."::${name}";
}

sub run {
    my $self = shift;
    my $env = shift;

    $self->env($env);
    $self->startup;
    my $routes = $self->router->match($env);
    if ($routes) {
        my $name = $routes->{controller};
        #$routes->{shortname} = lcfirst((split(/(?<=::)/, $name))[-1]);
        $routes->{controller} = $name;
        $routes->{package} = $self->get_package($name);
    } else {
        my $not_found = $self->not_found;
        my $name = $not_found->{controller};
        $routes->{controller} = $name;
        $routes->{package} = $self->get_package($name);
        $routes->{action} = $not_found->{action};
    }

    my ($res, $dispatched, $controller);
    $dispatched = 1;
    do {
        $self->routes($routes);
        my $package = $routes->{package};
        load($package);
        $controller = $package->new(
            config => $self->config,
            app_root => $self->app_root,
            env => $env,
            routes => $routes,
        );
        my $a = $routes->{action};
        if (ref $a eq 'CODE') {
            $res = $a->($controller);
            Carp::croak("You must render a template file") unless $controller->rendered;
        } elsif ($controller->can($a)) {
            $controller->call_trigger('before_action', $controller) if $controller->can('call_trigger');
            $res = $controller->$a();
        } else {
            Carp::croak("Cannot call method ${controller}->${a}");
        }
        $dispatched = $controller->dispatched;
        unless ($dispatched) {
            $routes = $controller->routes;
        }
    } until ($dispatched);

    $controller->finalize($res);
}

sub to_app {
    my $self = shift;
    return sub {
        #DB::enable_profile;
        $self->run(@_);
        #DB::disable_profile;
    };
}

sub psgi_app {
    my $self = shift;
    $self->to_app;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sec - Blah blah blah

=head1 SYNOPSIS

  use Sec;

=head1 DESCRIPTION

Sec is

=head1 AUTHOR

Kazutake Hiramatsu E<lt>hiramatsu@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013- Kazutake Hiramatsu

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut

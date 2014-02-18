package Sec::Validator;
use strict;
use warnings;
use Sec::Validator::Core;
use Sec::Accessor;
use Carp ();



sub import {
    my $caller = caller;

    my @export = qw(params clean_params validate errors has_error);

    my $v = Sec::Validator::Core->new;

    no strict 'refs';

    *{"$caller\::new"} = sub {
        my $class = shift;
        my %args = @_;
        Carp::croak "Missing params" unless $args{params};
        $v->params($args{params});
        my $self = {};
        $self->{validator} = $v;
        bless $self, $class; 
    };

    *{"$caller\::rule"} = sub {
        my ($name, %rules) = @_;
            
        $v->add_rule($name => \%rules);
    }; 

    *{"$caller\::validator"} = sub {
        my $self = shift; 
        $self->{validator};
    }; 

    for (@export) {
        my $m = $_;
        *{"$caller\::$m"} = sub {
            my $self = shift; 
            $self->validator->$m(@_);
        }; 
    }
}


1; 

package Sec::Validator::Core;
use strict;
use warnings;
use Carp ();
use Sec::Accessor;

has 'params' => (
    is => 'rw',
    default => sub {{}},
);

has 'rules' => (
    is => 'ro',
    default => sub {{}},
);

has 'clean_params' => (
    is => 'rw',
    default => sub {{}},
);

has 'errors' => (
    is => 'rw',
    default => sub {[]},
);



sub add_rule {
    my $self = shift;
    my $name = shift;
    my $rules = shift;

    my %rules = %$rules; 
    my @attrs = qw/
        required min_length max_length max_value regex callback
    /;
    for my $attr (@attrs) {
        $self->rules->{$name}->{$attr} = $rules{$attr} if exists $rules{$attr};
    }
}

sub validate {
    my $self = shift;

    my $params = $self->params 
        or Carp::croak("Parameters is missing");

    my $errors = [];
    my $clean = {};
    my %rules = %{$self->rules};
    while (my ($key, $value) = each %rules) {
        my $e = {};
        if (exists $value->{required} && ($value->{required} == 1)) {
            if (exists $params->{$key} && ($params->{$key} ne '')) {
                $e = $self->check($params, $key, $value);
                unless (%$e) {
                    $clean->{$key} = $params->{$key};
                }
            } else {
                $e->{$key}->{required} = 1;
            }
            push @{$errors}, $e if %$e;
        } else {
            if (exists $params->{$key}) { 
                $e = $self->check($params, $key, $value);
                unless (%$e) {
                    $clean->{$key} = $params->{$key};
                }
                push @{$errors}, $e if %$e;
            }
        }
    }
    $self->errors($errors);
    $self->clean_params($clean);
    $self;
}

sub check {
    my $self = shift; 
    my $params = shift;
    my $key = shift;
    my $value = shift;

    my $e = {};
    if (exists $value->{min_length} && ($value->{min_length} ne '')) {
        if (length($params->{$key}) < $value->{min_length}) {
            $e->{$key}->{min_length} = 1;
        }
    }
    if (exists $value->{max_length} && ($value->{max_length} ne '')) {
        if (length($params->{$key}) > $value->{max_length}) {
            $e->{$key}->{max_length} = 1;
        }
    }
    if (exists $value->{regex} && ($value->{regex} ne '')) {
        if ($params->{$key} !~ $value->{regex}) {
            $e->{$key}->{regex} = 1;
        }
    }
    if (exists $value->{callback} && ($value->{callback} ne '')) {
        if (!$value->{callback}->($params->{$key})) {
            $e->{$key}->{callback} = 1;
        }
    }
    $e;
}

sub has_error {
    my $self = shift;

    if (scalar @{$self->errors}) {
        return 1;
    }
    return 0;
}

1;

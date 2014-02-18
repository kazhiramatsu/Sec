package Sense::Model::User;
use strict;
use warnings;
use parent qw(Sec::DBI);
use Sense::Util qw(password_hash);
use Sec::Util;

sub insert {
    my $self = shift;
    my $user = shift;

    delete $user->{email_confirm};
    delete $user->{password_confirm};
    $user->{created_on} = Sec::Util::now;
    $self->SUPER::insert(
        'users',
        $user,
    );
}

sub find_by_user {
    my $self = shift;
    my $salt = shift;
    my $user_id = shift;
    my $password = shift;

    my $pass = password_hash($salt, $password, $user_id);

    my ($data) = $self->find_by_sql(
        "select * from users where user_id = :id and password = :pass",
        {
            id => $user_id,
            pass => $pass,
        }
    );
    $data ? $data : ();
}

1;

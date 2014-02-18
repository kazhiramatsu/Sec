package Sense::Model::Session;
use strict;
use warnings;
use parent qw(Sec::DBI);
use Sense::Util ();

sub search_by_user {
    my $self = shift;
    my $salt = shift;
    my $user_id = shift;
    my $password = shift;

    $password = Sense::Util::password_hash($salt, $password, $user_id);

    $self->search_by_sql(
        "select * from users where user_id = :id and password = :pass",
        {
            id => $user_id,
            pass => $password,
        }
    );
}

1;

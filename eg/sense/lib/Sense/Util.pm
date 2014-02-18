package Sense;
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use parent qw(Exporter);
our @EXPORT_OK = qw(password_hash);

sub password_hash {
    my ($salt, $password, $user_id) = @_;

    sha256_hex($salt.$password.$user_id);
}

1;

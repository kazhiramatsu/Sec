package Sec::DBI;
use strict;
use warnings;
use Sec::Accessor;
use DBI;
use Carp ();

has 'connect_info' => (
    is => 'rw',
    lazy => 1,
    default => sub {
        undef;
    }
);

has 'dbh' => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $connect_info = $self->connect_info;
        unless ($connect_info) {
            Carp::croak "Missing connect info";
        }
        my $dbh = DBI->connect(
            $connect_info->{dsn},
            $connect_info->{user},
            $connect_info->{password},
            $connect_info->{connect_options},
        );
    }
);

sub bind_named {
    my ($self, $sql, $args ) = @_;

    Carp::croak("Missing sql statement") unless $sql;

    my @bind;
    $sql =~ s{:([A-Za-z_][A-Za-z0-9_]*)}{
        Carp::croak("'$1' does not exist in bind hash") if !exists $args->{$1};
        if ( ref $args->{$1} && ref $args->{$1} eq "ARRAY" ) {
            push @bind, @{ $args->{$1} };
            my $tmp = join ',', map { '?' } @{ $args->{$1} };
            "( $tmp )";
        } else {
            push @bind, $args->{$1};
            '?'
        }
    }ge;

    return ($sql, \@bind);
}

sub execute {
    my ($self, $sql, $binds) = @_;

    my $sth = $self->dbh->prepare($sql);
    my $i = 1;
    for my $v ( @{ $binds || [] } ) {
        $sth->bind_param( $i++, ref($v) eq 'ARRAY' ? @$v : $v );
    }
    $sth->execute();
    $sth;
}

sub find_by_sql {
    my $self = shift;

    my $sth = $self->execute($self->bind_named(@_));

    my $result = $sth->fetchall_arrayref({}); 
    $sth->finish;

    if (wantarray) {
        return @$result;
    } else {
        return @$result == 0 ? undef : $result;
    }
}

sub insert {
    my ($self, $table, $values) = @_;

    my $sql = $self->make_insert_sql($table, $values);
    my $sth = $self->execute($self->bind_named($sql, $values));
    $sth->finish;
}

sub make_insert_sql {
    my ($self, $table, $values) = @_;

    Carp::croak("Missing table name") unless $table;

    my @keys = keys %$values;
    my $columns = join ',', map { "${_}" } @keys;

    my $tmp = join ',', map { ":${_}"; } @keys;
    my $sql_values = "( $tmp )";

    my $sql = "insert into " . $table ." ( $columns ) values $sql_values";
}

sub update {
    my ($self, $table, $set, $where, $values) = @_;

    my %bind = %$set;
    for my $k (keys %$values) {
        Carp::croak("$k already exists") if exists $bind{$k};
        $bind{$k} = $values->{$k};
    }
    my $sql = $self->make_update_sql($table, $set, $where);
    my $sth = $self->execute($self->bind_named($sql, \%bind));
    $sth->finish;
}

sub make_update_sql {
    my ($self, $table, $set, $where) = @_;

    Carp::croak("Missing table name") unless $table;
    Carp::croak("Missing set") unless $set;
    
    my @set = keys %$set; 
     
    my $columns = join ',', map {
        $_.'='.":".$_ if exists $set->{$_};
    } @set;

    my $sql = "update " . $table ." set $columns";
    $sql .= " where $where" if $where;
}

sub delete {
    my ($self, $table, $where, $values) = @_; 

    my $sql = $self->make_delete_sql($table, $where);
    my $sth = $self->execute($self->bind_named($sql, $values));
    $sth->finish;
}

sub make_delete_sql {
    my ($self, $table, $where) = @_;

    Carp::croak("Missing table name") unless $table;
     
    my $sql = "delete from " . $table;
    
    $sql .= " where $where" if $where;
}

sub do {
    my $self = shift;
    $self->dbh->do(@_);
}

sub last_insert_id {
    my $self = shift;

    my ($data) = $self->find_by_sql(
        'select last_insert_id()'
    );

    $data ? $data->{'last_insert_id()'} : undef;
}

1;

package Hetzner::Robot::Boot;
use base "Hetzner::Robot::Item";
use strict;

sub active {
    return ( $_[0]->__info->{active} ? 1 : 0 );
}

sub password {
    return $_[0]->__info->{password};
}

sub arch {
    return $_[0]->__info->{arch};
}

sub disable {
    my ($self) = @_;
    return $self->req("DELETE", $self->__url);
}
1;

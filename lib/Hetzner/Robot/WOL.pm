package Hetzner::Robot::WOL;
use base "Hetzner::Robot::Item";
use strict;

sub execute {
    my ($self) = @_;
    return $self->__conf();
}
1;

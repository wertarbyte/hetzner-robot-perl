package Hetzner::Robot::Subnet;
use base "Hetzner::Robot::IP";
use strict;

use Hetzner::Robot::Failover;

sub netmask {
    my ($self) = @_;
    return $self->__info->{mask};
}

sub failover {
    my ($self) = @_;
    if ($self->__info->{failover}) {
        return Hetzner::Robot::Failover->new($self->address);
    } else {
        return undef;
    }
}

1;

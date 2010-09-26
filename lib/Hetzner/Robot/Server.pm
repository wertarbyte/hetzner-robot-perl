package Hetzner::Robot::Server;
use base "Hetzner::Robot::Item::Enumerable";
use strict;
use Hetzner::Robot::WOL;
use Hetzner::Robot::Reset;
use Hetzner::Robot::Boot::Rescue;
use Hetzner::Robot::Subnet;
use Hetzner::Robot::IP;

sub __idkey { return "server_ip"; }

sub address {
    my ($self) = @_;
    return $self->key;
}

sub wol {
    my ($self) = @_;
    return new Hetzner::Robot::WOL($self->robot, $self->key);
}

sub reset {
    my ($self) = @_;
    return new Hetzner::Robot::Reset($self->robot, $self->key);
}

sub rescue {
    my ($self) = @_;
    return new Hetzner::Robot::Boot::Rescue($self->robot, $self->key);
}

sub addresses {
    my ($self) = @_;
    return map { Hetzner::Robot::IP->new($self->robot, $_) } @{$self->__info()->{ip}};
}

sub networks {
    my ($self) = @_;
    return map { Hetzner::Robot::Subnet->new($self->robot, $_->{ip}) } @{$self->__info()->{subnet}};
}

sub product { return shift->__info()->{product}; }
sub datacenter { return shift->__info()->{dc}; }
sub paid_until { return shift->__info()->{paid_until}; }
sub throtteled { return shift->__info()->{throtteled}; }
sub included_traffic { return shift->__info()->{traffic}; }

1;

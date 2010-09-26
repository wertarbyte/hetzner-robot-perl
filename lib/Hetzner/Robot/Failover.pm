package Hetzner::Robot::Failover;
use base "Hetzner::Robot::Item::Enumerable";
use strict;

sub __idkey { return "ip"; }

sub address {
    my ($self) = @_;
    return $self->key;
}

sub netmask {
    my ($self) = @_;
    return $self->__info->{netmask};
}

sub server {
    my ($self) = @_;
    my $addr = $self->__info->{server_ip};
    return $self->robot->server($addr);
}

sub target {
    my ($self, $route) = @_;
    if ($route) {
        $self->__conf( active_server_ip => $route->address );
    }
    my $addr = $self->__info->{active_server_ip};
    return $self->robot->server($addr);
}

1;

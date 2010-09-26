package Hetzner::Robot::Reset;
use base "Hetzner::Robot::Item::Enumerable";
use strict;

sub __idkey { return "server_ip"; }

sub available_methods {
    my ($self) = @_;
    return $self->__info->{"type"};
}

sub execute {
    my ($self, $method) = @_;
    $method = "sw" unless $method;
    return $self->__conf(type=>$method);
}
1;

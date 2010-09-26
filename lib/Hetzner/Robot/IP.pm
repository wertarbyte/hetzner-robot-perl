package Hetzner::Robot::IP;
use base "Hetzner::Robot::Item::Enumerable";
use strict;

sub __idkey { return "ip"; }

sub address {
    my ($self) = @_;
    return $self->key;
}

sub server {
    my ($self) = @_;
    return $self->robot->server($self->__info->{server_ip});
}

sub is_locked {
    my ($self) = @_;
    return $self->__info->{locked};
}

sub __trafficconf {
    my ($self, $var, $val) = @_;
    if (defined $val) {
        return $self->__conf($var => $val)->{$var};
    } else {
        return $self->__info->{$var};
    }
}

sub traffic_warnings {
    return $_[0]->__trafficconf("traffic_warnings", $_[1] ? "true" : "false");
}

sub traffic_hourly {
    return $_[0]->__trafficconf("traffic_hourly", $_[1]);
}

sub traffic_daily {
    return $_[0]->__trafficconf("traffic_daily", $_[1]);
}

sub traffic_monthly {
    return $_[0]->__trafficconf("traffic_monthly", $_[1]);
}

1;

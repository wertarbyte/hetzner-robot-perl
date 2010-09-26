package Hetzner::Robot::Boot::Rescue;
use base "Hetzner::Robot::Item";
use strict;

sub active {
    return ( $_[0]->__info->{active} ? 1 : 0 );
}

sub password {
    return $_[0]->__info->{password};
}

sub os {
    return $_[0]->__info->{os};
}

sub arch {
    return $_[0]->__info->{arch};
}

sub available_os {
    return @{ $_[0]->__info->{os} };
}

sub available_arch {
    return @{ $_[0]->__info->{arch} };
}

sub enable {
    my ($self, $os, $arch) = @_;
    return $self->__conf(os => $os, arch => $arch);
}

sub disable {
    my ($self) = @_;
    return $self->req("DELETE", $self->__url);
}
1;

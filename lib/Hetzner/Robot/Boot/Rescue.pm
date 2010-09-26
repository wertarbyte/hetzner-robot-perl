package Hetzner::Robot::Boot::Rescue;
use base "Hetzner::Robot::Item";
use strict;

=head1 NAME

Hetzner::Robot::Boot::Rescue - Configure the Hetzner rescue system

=head1 SYNOPSIS

    my $robot = new Hetzner::Robot( "user", "password" );
    my $rescue = new Hetzner::Robot::Boot::Rescue( $robot, "1.2.3.4" );
    
    # enable rescue system for server 1.2.3.4
    $rescue->enable( "linux", "64" );
    print "Password is: ", $rescue->password, "\n";

=head1 METHODS

=over

=item Hetzner::Robot::Boot::Rescue->new( $robot, $address )

Returns the rescue system handle for the specified server address.

=item $rescue->active

Returns whether the rescue system is activated.

=cut

sub active {
    return ( $_[0]->__info->{active} ? 1 : 0 );
}

=item $rescue->password

Returns the password generated for the activatede rescue system.

=cut

sub password {
    return $_[0]->__info->{password};
}

=item $rescue->os

=item $rescue->arch

Returns the set operating system or architecture.

=cut

sub os {
    return $_[0]->__info->{os};
}

sub arch {
    return $_[0]->__info->{arch};
}

=item $rescue->available_os

=item $rescue->available_arch

Returns a list of all available operating systems or architectures.

=cut

sub available_os {
    return @{ $_[0]->__info->{os} };
}

sub available_arch {
    return @{ $_[0]->__info->{arch} };
}

=item $rescue->enable( $os, $arch )

Prepare the rescue system with the specified OS and architecture.

=cut

sub enable {
    my ($self, $os, $arch) = @_;
    return $self->__conf(os => $os, arch => $arch);
}

=item $rescue->disable

Disable the rescue system.

=cut

sub disable {
    my ($self) = @_;
    return $self->req("DELETE", $self->__url);
}
1;

=back

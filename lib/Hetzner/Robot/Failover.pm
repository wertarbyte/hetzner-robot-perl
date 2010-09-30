package Hetzner::Robot::Failover;
use base "Hetzner::Robot::Item::Enumerable";
use strict;

=head1 NAME

Hetzner::Robot::Failover - Direct failover addresses

=head1 SYNOPSIS

    my $robot = new Hetzner::Robot("user", "password);
    # get object for failover network 10.10.5.1
    my $failover = new Hetzner::Failover( $robot, "10.10.5.1" );
    print "Current destination: ".$failover->target;
    # redirect failover network to other server
    $failover->target( "1.2.3.5" );

=head1 METHODS

=over

=item Hetzner::Robot::Failover->new( $robot, $address )

Returns the object reference to the failover address.

=item Hetzner::Robot::Failover->enumerate( $robot )

Returns a list of all failover addresses known to the robot instance.

=cut

sub __idkey { return "ip"; }

=item $failover->address

Returns the address of a failover object.

=cut

sub address {
    my ($self) = @_;
    return $self->key;
}

=item $failover->netmask

Returns the network mask in CIDR notation.

=cut

sub netmask {
    my ($self) = @_;
    return $self->__info->{netmask};
}

=item $failover->server

Returns the L<Hetzner::Robot::Server> object the address belongs to.

=cut

sub server {
    my ($self) = @_;
    my $addr = $self->__info->{server_ip};
    return $self->robot->server($addr);
}

=item $failover->target

=item $failover->target( $new_server )

Sets or retrieves the L<Hetzner::Robot::Server> object the failover
address points to.

=cut

sub target {
    my ($self, $route) = @_;
    if ($route) {
        $self->__conf( active_server_ip => $route->address );
    }
    my $addr = $self->__info->{active_server_ip};
    return $self->robot->server($addr);
}

1;

=back

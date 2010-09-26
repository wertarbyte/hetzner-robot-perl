package Hetzner::Robot::Subnet;
use base "Hetzner::Robot::IP";
use strict;

=head1 NAME

Hetzner::Robot::Subnet - Subnets assigned to Hetzner servers

=head1 SYNOPSIS

    my $robot = new Hetzner::Robot( "user", "password" );
    my $subnet = new Hetzner::Robot::Subnet( $robot, "10.5.2.0" );
    # deactivate traffic warnings
    $subnet->traffic_warnings( 0 );

=head1 DESCRIPTION

C<Hetzner::Robot::Subnet> is a subclass of C<Hetzner::Robot::IP>, thus
inheriting all of its methods and constructors.

=cut

use Hetzner::Robot::Failover;

=head1 METHODS

Additionally to the methods defined in C<Hetzner::Robot::IP>, two additional
methods are added by this class:

=over

=item $subnet->netmask

Returns the network mask in CIDR notation.

=cut

sub netmask {
    my ($self) = @_;
    return $self->__info->{mask};
}

=item $subnet->failover

Returns the C<Hetzner::Robot::Failover> object associated if the network
is a failover address; otherwise, it returns a false value.

=cut

sub failover {
    my ($self) = @_;
    if ($self->__info->{failover}) {
        return Hetzner::Robot::Failover->new($self->address);
    } else {
        return undef;
    }
}

1;

=back

=head1 SEE ALSO

L<Hetzner::Robot::IP>,
L<Hetzner::Robot::Failover>

package Hetzner::Robot::Server;
use base "Hetzner::Robot::Item::Enumerable";
use strict;

=head1 NAME

Hetzner::Robot::Server - Representation of a single server

=head1 SYNOPSIS

    use Hetzner::Robot;
    use Hetzner::Robot::Server;
    my $robot = new Hetzner::Robot("user", "password");
    my $server = new Hetzner::Robot::Server($robot, "1.2.3.4");
    print $server->product;

=head1 DESCRIPTION

C<Hetzner::Robot::Server> encapsulates access to a server object as
provided by the webservice.

=cut

use Hetzner::Robot::WOL;
use Hetzner::Robot::Reset;
use Hetzner::Robot::Boot::Rescue;
use Hetzner::Robot::Subnet;
use Hetzner::Robot::IP;

sub __idkey { return "server_ip"; }

=head1 METHODS

=over

=item Hetzner::Robot::Server->new( $robot, $address )

Instantiates a new object by specifying the
L<Hetzner::Robot|Hetzner::Robot> object and the server main address.

=item Hetzner::Robot::Server->enumerate( $robot )

Returns a list of all server objects known to the L<Hetzner::Robot>
account.

=item $server->address

Returns the primary address of the server.

=cut

sub address {
    my ($self) = @_;
    return $self->key;
}

=item $server->name

=item $server->name("foo")

Returns or sets the custom server nickname.

=cut

sub name {
    my ($self, $nick) = @_;
    if (defined $nick) {
        $self->__conf( "server_name" => $nick );
    }
    return $self->__info->{server_name};
}

=item $server->wol

=item $server->reset

=item $server->rescue

Returns the WOL/Reset/Rescue controller object assigned to the server.

=cut

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

=item $server->addresses

=item $server->subnets

Returns a list of IP addresses (L<Hetzner::Robot::IP>) or subnets
(L<Hetzner::Robot::Subnet>) assigned to the server.

=cut

sub addresses {
    my ($self) = @_;
    return map { Hetzner::Robot::IP->new($self->robot, $_) } @{$self->__info()->{ip}};
}

sub subnets {
    my ($self) = @_;
    return map { Hetzner::Robot::Subnet->new($self->robot, $_->{ip}) } @{$self->__info()->{subnet}};
}

=item $server->product

=item $server->datacenter

=item $server->paid_until

=item $server->throtteled

=item $server->throtteled

Theses methods return various information about the server.

=cut

sub product { return shift->__info()->{product}; }
sub datacenter { return shift->__info()->{dc}; }
sub paid_until { return shift->__info()->{paid_until}; }
sub throtteled { return shift->__info()->{throtteled}; }
sub included_traffic { return shift->__info()->{traffic}; }

1;

=back

=head1 SEE ALSO

L<Hetzner::Robot>,
L<Hetzner::Robot::WOL>,
L<Hetzner::Robot::Reset>,
L<Hetzner::Robot::Boot::Rescue>,
L<Hetzner::Robot::IP>,
L<Hetzner::Robot::Subnet>

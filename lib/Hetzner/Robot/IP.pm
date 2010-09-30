package Hetzner::Robot::IP;
use base "Hetzner::Robot::Item::Enumerable";
use strict;

=head1 NAME

Hetzner::Robot:IP - Single addresses assigned to Hetzner servers

=head1 SYNOPSIS

    my $robot = new Hetzner::Robot( "user", "password" );
    # print all known addresses with their assigned servers
    for my $ip ( enumerate Hetzner::Robot::IP( $robot ) ) {
        print $ip->address, "\t", $ip->server->address, "\n";
    }

    # print traffic warning limit for a single address
    my $addr = new Hetzner::Robot::IP( $robot, "1.2.3.4" );
    print $addr->traffic_hourly, "\n";

=head1 METHODS

=over

=item Hetzner::Robot::IP->new( $robot, $address )

Returns a reference to the IP object representing
the IP address.

=item Hetzner::Robot::IP->enumerate( $robot )

Returns a list containing all IP objects known to
the robot account.

=cut

sub __idkey { return "ip"; }

=item $ip->address

Returns the IP address of the object.

=cut

sub address {
    my ($self) = @_;
    return $self->key;
}

=item $ip->server

Returns a reference to the server object the address is assigned to.

=cut

sub server {
    my ($self) = @_;
    return $self->robot->server($self->__info->{server_ip});
}

=item $ip->is_locked

Indicates whether the address is locked.

=cut

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

=item $ip->traffic_warnings

=item $ip->traffic_hourly

=item $ip->traffic_daily

=item $ip->traffic_monthly

Set or get values that indicate whether and at which level traffic warnings are
send.

=cut

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

=back

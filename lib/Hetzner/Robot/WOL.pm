package Hetzner::Robot::WOL;
use base "Hetzner::Robot::Item";
use strict;

=head1 NAME

Hetzner::Robot::WOL - Wake-On-Lan trigger for Hetzner servers

=head1 SYNOPSIS

    my $robot = new Hetzner::Robot("user", "password");
    my $wol = new Hetzner::Robot::WOL( $robot, "1.2.3.4");
    # send wakup signal to server 1.2.3.4
    $wol->execute();

=head1 METHODS

=over

=item Hetzner::Robot::WOL->new( $robot, $address );

    Returns a WOL object for the server with the supplied address.

=item $wol->execute()

    Triggers the wakeup signal for the server.

=back

=cut

sub execute {
    my ($self) = @_;
    return $self->__conf();
}
1;

package Hetzner::Robot::Reset;
use base "Hetzner::Robot::Item::Enumerable";
use strict;

=head1 NAME

Hetzner::Robot::Reset - Trigger resets of Hetzner servers

=head1 SYNOPSIS

    my $robot = new Hetzner::Robot( "user", "password" );
    my $reset = new Hetzner::Robot::Reset( $robot, "1.2.3.4" );
    # trigger a software reset
    $reset->execute( "sw" );
    
    # alternative path to trigger hardware reset
    $robot->server( "1.2.3.4" )->reset->execute( "hw" );

=head1 METHODS

=over

=item Hetzner::Robot::Reset->new( $robot, $address )

Returns a handle to the resetter for the specified server.

=item Hetzner::Robot::Reset->enumerate( $robot )

Returns a list of all known resetters.

=cut

sub __idkey { return "server_ip"; }

=item $reset->available_methods

Returns a list of known reset methods for the server.

=cut

sub available_methods {
    my ($self) = @_;
    return $self->__info->{"type"};
}

=item $reset->execute( $method )

Triggers a reset using the supplied method; if no method
is specified, "sw" is assumed.

=cut

sub execute {
    my ($self, $method) = @_;
    $method = "sw" unless $method;
    return $self->__conf(type=>$method);
}
1;

=back

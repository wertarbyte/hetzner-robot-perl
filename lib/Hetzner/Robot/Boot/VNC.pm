package Hetzner::Robot::Boot::VNC;
use base "Hetzner::Robot::Boot";
use strict;

=head1 NAME

Hetzner::Robot::Boot::VNC - Configure the Hetzner VNC installation

=head1 SYNOPSIS

    my $robot = new Hetzner::Robot( "user", "password" );
    my $vnc = new Hetzner::Robot::Boot::VNC( $robot, "1.2.3.4" );
    
    # enable VNC installation for server 1.2.3.4
    $vnc->enable( "centOS-5.0", "64", "de_DE" );
    print "Password is: ", $vnc->password, "\n";

=head1 METHODS

=over

=item Hetzner::Robot::Boot::VNC->new( $robot, $address )

Returns the VNC installer handle for the specified server address.

=item $vnc->active

Returns whether the VNC installation is activated.

=item $vnc->password

Returns the password generated for the activated VNC installer

=item $vnc->dist

=item $vnc->arch

=item $vnc->lang

Returns the set distribution, architecture and language

=cut

sub dist {
    return $_[0]->__info->{dist};
}

sub lang {
    return $_[0]->__info->{lang};
}

=item $vnc->available_dist

=item $vnc->available_arch

Returns a list of all available distributions, architectures or languages.

=cut

sub available_dist {
    return @{ $_[0]->__info->{dist} };
}

sub available_arch {
    return @{ $_[0]->__info->{arch} };
}

sub available_lang {
    return @{ $_[0]->__info->{lang} };
}

=item $vnc->enable( $os, $arch, $lang )

Prepare the VNC installation with the specified distribution, architecture
and language.

=cut

sub enable {
    my ($self, $dist, $arch, $lang) = @_;
    return $self->__conf(dist => $dist, arch => $arch, lang => $lang);
}

=item $vnc->disable

Disable the VNC installer.

=back
=cut
1;

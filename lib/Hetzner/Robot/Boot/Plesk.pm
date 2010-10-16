package Hetzner::Robot::Boot::Plesk;
use base "Hetzner::Robot::Boot";
use strict;

=head1 NAME

Hetzner::Robot::Boot::Plesk - Configure the Hetzner Plesk installer

=head1 SYNOPSIS

    my $robot = new Hetzner::Robot( "user", "password" );
    my $plesk = new Hetzner::Robot::Boot::Plesk( $robot, "1.2.3.4" );
    
    # enable Plesk installation for server 1.2.3.4
    $plesk->enable( "Debian 5.0 minimal", 64, "de", "foo.hostname.example" );
    print "Password is: ", $plesk->password, "\n";

=head1 METHODS

=over

=item Hetzner::Robot::Boot::Plesk->new( $robot, $address )

Returns the Plesk installer handle for the specified server address.

=item $plesk->active

Returns whether the Plesk installation is activated.

=item $plesk->password

Returns the password generated for the activated Pleask installer.

=item $plesk->dist

=item $plesk->arch

=item $plesk->lang

Returns the set distribution, architecture or language of the active installer.

=cut

sub dist {
    return $_[0]->__info->{dist};
}

sub arch {
    return $_[0]->__info->{arch};
}


sub lang {
    return $_[0]->__info->{lang};
}

=item $plesk->available_dist

=item $plesk->available_arch

=item $plesk->available_lang

Returns a list of all available distributions, architectures or languages.

=cut

sub available_dist {
    return $_[0]->__aslist( $_[0]->__info->{dist} );
}

sub available_arch {
    return $_[0]->__aslist( $_[0]->__info->{arch} );
}

sub available_lang {
    return $_[0]->__aslist( $_[0]->__info->{lang} );
}

=item $plesk->enable( $dist, $arch, $lang, $hostname )

Activate the Plesk installer.

=cut

sub enable {
    my ($self, $dist, $arch, $lang, $hostname) = @_;
    return $self->__conf(dist => $dist, arch => $arch, lang => $lang, hostname => $hostname);
}

=item $plesk->disable

Disable the Plesk installer.

=back
=cut
1;

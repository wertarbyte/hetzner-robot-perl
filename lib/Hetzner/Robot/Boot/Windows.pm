package Hetzner::Robot::Boot::Windows;
use base "Hetzner::Robot::Boot";
use strict;

=head1 NAME

Hetzner::Robot::Boot::Windows - Configure the Hetzner Windows installation

=head1 SYNOPSIS

    my $robot = new Hetzner::Robot( "user", "password" );
    my $win = new Hetzner::Robot::Boot::Windows( $robot, "1.2.3.4" );
    
    # enable Windows installation for server 1.2.3.4
    $win->enable( "de" );
    print "Password is: ", $win->password, "\n";

=head1 METHODS

=over

=item Hetzner::Robot::Boot::Windows->new( $robot, $address )

Returns the Windows installer handle for the specified server address.

=item $win->active

Returns whether the Windows installation is activated.

=item $win->password

Returns the password generated for the activated Windows installer.

=item $win->dist

=item $win->lang

Returns the set distribution or language of the active installer.

=cut

sub dist {
    return $_[0]->__info->{dist};
}

sub lang {
    return $_[0]->__info->{lang};
}

=item $win->available_dist

=item $win->available_lang

Returns a list of all available distributions or languages.

=cut

sub available_dist {
    return $_[0]->__aslist( $_[0]->__info->{dist} );
}

sub available_lang {
    return $_[0]->__aslist( $_[0]->__info->{lang} );
}

=item $win->enable( $lang )

Activate the Windows installer the specified language.

=cut

sub enable {
    my ($self, $lang) = @_;
    return $self->__conf(lang => $lang);
}

=item $win->disable

Disable the Windows installer.

=back
=cut
1;

package Hetzner::Robot::RDNS;
use base "Hetzner::Robot::Item::Enumerable";
use strict;

=head1 NAME

Hetzner::Robot::RDNS - Class representing RDNS entries

=head1 SYNOPSIS

    use Hetzner::Robot;
    use Hetzner::Robot::RDNS;
    my $robot = new Hetzner::Robot("user", "password");
    my $entry = new Hetzner::Robot::RDNS($robot, "1.2.3.4");
    # get rdns entry
    print $entry->ptr;
    # set entry
    $entry->ptr("myhost.example.org");

=head1 DESCRIPTION

This class encapsulates access to a rdns object as provided by the
webservice.

=head1 METHODS

=over

=item Hetzner::Robot::RDNS->new( $robot, $address )

Instantiates a new RDNS object by specifying the Hetzner::Robot object
and the IP address.

=item Hetzner::Robot::RDNS->enumerate( $robot )

Returns a list of all reverse DNS entries known to the L<Hetzner::Robot>
account.

=item $entry->address

Returns the IP address of the entry.

=cut

sub address {
    my ($self) = @_;
    return $self->key;
}

# overload __info method
sub __info {
    my ($self) = @_;
    my $res = { ip => $self->address, ptr => undef };
    eval {
        # try to retrieve the real results
        $res = $self->SUPER::__info(@_);
    };
    if ($@ && ref($@) ne "Hetzner::Robot::NotFoundException") {
        # in case of this exception, the RDNS entry
        # probably has not been created yet, so we
        # return an empty "dummy" result;
        # otherwise, just re-die the exception
        die $@
    }
    return $res;
}

sub __idkey { return "ip"; }

=item $entry->ptr

=item $entry->ptr( $hostname )

Gets or sets the reverse entry.

=cut

sub ptr {
    my ($self, $val) = @_;
    if (defined $val) {
        $self->__conf( ptr => $val );
    }
    return $self->__info->{ptr};
}

=item $entry->del

Delete the reverse entry.

=cut

sub del {
    my ($self) = @_;
    return $self->req("DELETE", $self->__url);
}
1;

=back

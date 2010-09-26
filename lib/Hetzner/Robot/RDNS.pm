package Hetzner::Robot::RDNS;
use base "Hetzner::Robot::Item::Enumerable";
use strict;
use Net::IP;

sub enumerate {
    my ($this, $robot) = @_;
    my $cls = ref($this) || $this;
    # get a list of all addresses known to the Robot
    my @servers = $robot->servers;
    my @addr = map {$_->address} map {$_->addresses} @servers;
    # expand networks to lists of IP addresses
    for my $n (map {$_->networks} @servers) {
        my $ip = new Net::IP($n->address."/".$n->netmask);
        # we do not enumerate subnets with more than 1024 addresses (IPv6) for
        # obvious reasons; let's hope that Hetzner implements a better way to access
        # rdns entries as a whole
        if ($ip->size > 1024) {
            #print STDERR "Not expanding subnet ".$ip->short." containing ".$ip->size." addresses.\n";
        } else {
            do { push @addr, $ip->ip; } while (++$ip);
        }
    }
    map {$cls->new($robot, $_)} @addr;
}

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

sub ptr {
    my ($self, $val) = @_;
    if (defined $val) {
        $self->__conf( ptr => $val );
    }
    return $self->__info->{ptr};
}

sub del {
    my ($self) = @_;
    return $self->req("DELETE", $self->__url);
}
1;

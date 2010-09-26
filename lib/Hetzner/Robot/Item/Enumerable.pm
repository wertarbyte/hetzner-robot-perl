package Hetzner::Robot::Item::Enumerable;
use base "Hetzner::Robot::Item";
use strict;

# enumerate all instances of an object type
sub enumerate {
    my ($this, $robot) = @_;
    my $cls = ref($this) || $this;
    my $l = $robot->req("GET", "/".$cls->__section);
    return map { $cls->new($robot, $_->{$cls->__section}{$cls->__idkey}) } @$l;
}

# the id item in a returned data structure
sub __idkey {
    my ($this) = @_;
    my $class = ref($this) || $this;
    die "Method __idkey has to be overridden by $class";
}

1;

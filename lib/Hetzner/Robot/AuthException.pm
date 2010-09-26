package Hetzner::Robot::AuthException;
use base "Hetzner::Robot::Exception";
use strict;

sub new {
    my ($this) = @_;
    my $cls = ref($this) || $this;
    return $cls->SUPER::new("Authentication failed");
}

1;

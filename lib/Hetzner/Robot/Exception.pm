package Hetzner::Robot::Exception;
use strict;
use overload '""' => \&msg;

sub new {
    my ($this, $msg) = @_;
    my $cls = ref($this) || $this;
    bless {msg=>$msg}, $cls;
}

sub msg {
    return shift->{msg};
}

1;

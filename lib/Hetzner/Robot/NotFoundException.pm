package Hetzner::Robot::NotFoundException;
use base "Hetzner::Robot::Exception";
use strict;

sub new {
    my ($this, $doc) = @_;
    my $cls = ref($this) || $this;
    my $self = $cls->SUPER::new("Ressource not found");
    $self->{doc} = $doc;
    return $self;
}

sub msg {
    my $self = shift;
    return $self->SUPER::msg.": ".$self->{doc};
}

1;

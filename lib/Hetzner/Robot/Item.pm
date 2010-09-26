package Hetzner::Robot::Item;
use strict;

sub new {
    my ($this, $robot, $key) = @_;
    my $class = ref($this) || $this;
    my $self = { robot => $robot, key => $key };
    bless $self, $class;
}
sub req {
    my ($self, @params) = @_;
    $self->robot->req(@params);
}
sub robot {
    my ($self) = @_;
    return $self->{robot};
}
sub key {
    my ($self) = @_;
    return $self->{key};
}

sub __section {
    my ($self) = @_;
    # extract section name from class name
    my @c = split /::/, ( ref($self) || $self );
    return lc $c[2];
}

sub __subsection {
    my ($self) = @_;
    my @c = split /::/, ( ref($self) || $self );
    return lc $c[3];
}

# root item in retrieved data structures
sub __root {
    my ($self) = @_;
    return $self->__subsection || $self->__section;
}

sub __url {
    my ($self) = @_;
    my $url = "/".$self->__section."/".$self->key;
    if ($self->__subsection) {
        $url .= "/".$self->__subsection;
    }
    return $url;
}

sub __info {
    my ($self) = @_;
    return $self->req("GET", $self->__url)->{$self->__root};
}

sub __conf {
    my ($self, %vars) = @_;
    return $self->req("POST", $self->__url, \%vars)->{$self->__root};
}

1;

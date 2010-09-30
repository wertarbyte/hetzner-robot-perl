package Hetzner::MetaRobot;
use strict;

use Hetzner::Robot;

sub new {
    my ($this, $user, $password) = @_;
    my $cls = ref($this) || $this;
    my $self = { robots => [] };
    my $me = bless $self, $cls;

    if ($user) {
        # initialize first sub-robot
        $me->add_credentials( $user, $password );
    }

    return $me;
}

sub add_credentials {
    my ($self, $user, $password) = @_;
    my $r = new Hetzner::Robot($user, $password);
    push @{$self->{robots}}, $r;
    # return $self so the command can be chained
    return $self;
}

sub req {
    my ($self, @params) = @_;

    for my $r (@{ $self->{robots}}) {
        my $result = eval {
            $r->req(@params);
        };
        # Not found? Try the next robot, otherwise rethrow exception.
        if ($@){
            if (ref($@) ne "Hetzner::Robot::NotFoundException") {
                die $@;
            } else {
                next;
            }
        } else {
            return $result;
        }
    }
}

sub server {
    my ($self, $addr) = @_;
    for my $r (@{ $self->{robots}}) {
        my $s = $r->server($addr);
        return $s if $s->is_valid;
    }
    # Fallback
    return new Hetzner::Robot::Server($self, $addr);
}

sub servers {
    my ($self) = @_;
    return map {$_->servers} @{ $self->{robots} };
}

1;

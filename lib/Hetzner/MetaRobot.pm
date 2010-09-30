package Hetzner::MetaRobot;
use strict;

use Hetzner::Robot;

sub new {
    my ($this) = @_;
    my $cls = ref($this) || $this;
    my $self = { robots => [] };
    bless $self, $cls;
}

sub add_credentials {
    my ($self, $user, $password) = @_;
    my $r = new Hetzner::Robot($user, $password);
    push @{$self->{robots}}, $r;
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
    return new Hetzner::Server($self, $addr);
}

sub servers {
    my ($self) = @_;
    return map {$_->servers} @{ $self->{robots} };
}

1;

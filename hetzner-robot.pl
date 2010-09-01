#!/usr/bin/perl
use strict;

package Hetzner::Robot;
use LWP::UserAgent;
use HTTP::Request::Common;
use JSON;
our $BASEURL = "https://robot-ws.your-server.de";

sub new {
    my ($class, $user, $password) = @_;
    my $self = { user => $user, pass => $password };
    $self->{ua} = new LWP::UserAgent();
    bless $self, $class;
}
sub req {
    my ($self, $type, $url, $data) = @_;
    my $req;
    {
        no strict 'refs';
        $req = &{"HTTP::Request::Common::".$type}($BASEURL.$url, $data);
    }
    $req->authorization_basic($self->{user}, $self->{pass});
    my $res = $self->{ua}->request($req);
    if ($res->is_success) {
        return from_json($res->decoded_content);
    } else {
        die $res->code.": ".$res->message."\n";
        return undef;
    }
}
1;

package Hetzner::Robot::Item;

sub new {
    my ($class, $robot, $key) = @_;
    my $self = { robot => $robot, key => $key };
    bless $self, $class;
}
1;

package Hetzner::Robot::RDNS;
use base "Hetzner::Robot::Item";

sub addr {
    my ($self) = @_;
    return $self->{key};
}

sub ptr {
    my ($self, $val) = @_;
    my $bot = $self->{robot};
    if (defined $val) {
        return $bot->req("POST", "/rdns/".$self->{key}, { ptr => $val })->{rdns}{ptr};
    } else {
        return $bot->req("GET", "/rdns/".$self->{key})->{rdns}{ptr};
    }
}

sub del {
    my ($self) = @_;
    my $bot = $self->{robot};
    return $bot->req("DELETE", "/rdns/".$self->{key});
}
1;

package Hetzner::Robot::Rescue;
use base "Hetzner::Robot::Item";

sub status {
    my ($self) = @_;
    my $bot = $self->{robot};
    return $bot->req("GET", "/boot/".$self->{key});
}

sub active {
    return ( $_[0]->status()->{boot}{rescue}{active} ? 1 : 0 );
}

sub password {
    return $_[0]->status()->{boot}{rescue}{password};
}

sub enable {
    my ($self, $os, $arch) = @_;
    my $bot = $self->{robot};
    return $bot->req("POST", "/boot/".$self->{key}."/rescue", {os => $os, arch => $arch});
}

sub disable {
    my ($self, $os, $arch) = @_;
    my $bot = $self->{robot};
    return $bot->req("DELETE", "/boot/".$self->{key}."/rescue");
}
1;

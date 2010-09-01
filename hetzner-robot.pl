#!/usr/bin/perl
#
# Perl interface for the webservice interface
# provided by Hetzner
#
# by Stefan Tomanek <stefan.tomanek@wertarbyte.de>
#

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
sub req {
    my ($self, @params) = @_;
    $self->{robot}->req(@params);
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
    if (defined $val) {
        return $self->req("POST", "/rdns/".$self->{key}, { ptr => $val })->{rdns}{ptr};
    } else {
        return $self->req("GET", "/rdns/".$self->{key})->{rdns}{ptr};
    }
}

sub del {
    my ($self) = @_;
    return $self->req("DELETE", "/rdns/".$self->{key});
}
1;

package Hetzner::Robot::Rescue;
use base "Hetzner::Robot::Item";

sub status {
    my ($self) = @_;
    return $self->req("GET", "/boot/".$self->{key});
}

sub active {
    return ( $_[0]->status()->{boot}{rescue}{active} ? 1 : 0 );
}

sub password {
    return $_[0]->status()->{boot}{rescue}{password};
}

sub available_os {
    return @{ $_[0]->status()->{boot}{rescue}{os} };
}

sub available_arch {
    return @{ $_[0]->status()->{boot}{rescue}{arch} };
}

sub enable {
    my ($self, $os, $arch) = @_;
    return $self->req("POST", "/boot/".$self->{key}."/rescue", {os => $os, arch => $arch});
}

sub disable {
    my ($self) = @_;
    return $self->req("DELETE", "/boot/".$self->{key}."/rescue");
}
1;

##################################

package Hetzner::Robot::main;
use Getopt::Long;

my $user = undef;
my $pass = undef;

my ($get, $set, $del);
my ($addr, $name);

sub abort {
    my ($msg) = @_;
    print STDERR $msg,"\n" if $msg;
    exit 1;
}

GetOptions (
    'username|user|u=s' => \$user,
    'password|pass|p=s' => \$pass,
    'get|g' => \$get,
    'set|s' => \$set,
    'delete|del|d' => \$del,
    'hostname|name|n=s' => \$name,
    'address|addr|a=s' => \$addr
) || abort;
# check command line
abort "No user credentials specified!" unless (defined $user && defined $pass);
abort "No operation specified!" unless ($get ^ $set ^ $del);
abort "No address specified!" if (($get||$set||$del) && !defined $addr);
abort "No hostname specified!" if ($set && !defined $name);

my $robot = new Hetzner::Robot($user, $pass);
my $rdns = new Hetzner::Robot::RDNS($robot, $addr);
if ($get || $set) {
    if ($set) {
        $rdns->ptr($name);
    }
    print $rdns->addr, "\t", $rdns->ptr, "\n";
}

1;

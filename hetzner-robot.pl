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
use JSON;
use HTTP::Request;
use URI::Escape;

our $BASEURL = "https://robot-ws.your-server.de";

sub new {
    my ($this, $user, $password) = @_;
    my $class = ref($this) || $this;
    my $self = { user => $user, pass => $password };
    $self->{ua} = new LWP::UserAgent();
    $self->{ua}->env_proxy;
    bless $self, $class;
}
sub req {
    my ($self, $type, $url, $data) = @_;
    my $req = new HTTP::Request($type => $BASEURL.$url);
    $req->authorization_basic($self->{user}, $self->{pass});
    if ($data) {
        my @token = map( { uri_escape($_)."=".uri_escape($data->{$_}) } keys %$data );
        $req->content_type('application/x-www-form-urlencoded');
        $req->content( join("&", @token) );
    }
    my $res = $self->{ua}->request($req);
    if ($res->is_success) {
        if ($res->decoded_content) {
            return from_json($res->decoded_content);
        } else {
            return 1;
        }
    } else {
        die $res->code.": ".$res->message."\n";
        return undef;
    }
}

sub server {
    my ($self, $addr) = @_;
    return Hetzner::Robot::Server->new($self, $addr);
}

sub servers {
    my ($self) = @_;
    return Hetzner::Robot::Server->instances($self);
}

1;

package Hetzner::Robot::Item;

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
1;

package Hetzner::Robot::RDNS;
use base "Hetzner::Robot::Item";

sub address {
    my ($self) = @_;
    return $self->key;
}

sub ptr {
    my ($self, $val) = @_;
    if (defined $val) {
        return $self->req("POST", "/rdns/".$self->key, { ptr => $val })->{rdns}{ptr};
    } else {
        return $self->req("GET", "/rdns/".$self->key)->{rdns}{ptr};
    }
}

sub del {
    my ($self) = @_;
    return $self->req("DELETE", "/rdns/".$self->key);
}
1;

package Hetzner::Robot::Failover;
use base "Hetzner::Robot::Item";

sub address {
    my ($self) = @_;
    return $self->key;
}

sub netmask {
    my ($self) = @_;
    return $self->req("GET", "/failover/".$self->key)->{failover}{netmask};
}

sub server {
    my ($self) = @_;
    my $addr = $self->req("GET", "/failover/".$self->key)->{failover}{server_ip};
    return $self->robot->server($addr);
}

sub target {
    my ($self, $route) = @_;
    if ($route) {
        my $ta = $route->address;
        $self->req("POST", "/failover/".$self->key, {active_server_ip=>$ta});
    }
    my $addr = $self->req("GET", "/failover/".$self->key)->{failover}{active_server_ip};
    return $self->robot->server($addr);
}

1;

package Hetzner::Robot::Rescue;
use base "Hetzner::Robot::Item";

sub status {
    my ($self) = @_;
    return $self->req("GET", "/boot/".$self->key)->{boot}{rescue};
}

sub active {
    return ( $_[0]->status()->{active} ? 1 : 0 );
}

sub password {
    return $_[0]->status()->{password};
}

sub os {
    return $_[0]->status()->{os};
}

sub arch {
    return $_[0]->status()->{arch};
}

sub available_os {
    return @{ $_[0]->status()->{os} };
}

sub available_arch {
    return @{ $_[0]->status()->{arch} };
}

sub enable {
    my ($self, $os, $arch) = @_;
    return $self->req("POST", "/boot/".$self->key."/rescue", {os => $os, arch => $arch});
}

sub disable {
    my ($self) = @_;
    return $self->req("DELETE", "/boot/".$self->key."/rescue");
}
1;

package Hetzner::Robot::Reset;
use base "Hetzner::Robot::Item";

sub available_methods {
    my ($self) = @_;
    return $self->req("GET", "/reset/".$self->key)->{"reset"}{"type"};
}

sub execute {
    my ($self, $method) = @_;
    $method = "sw" unless $method;
    return $self->req("POST", "/reset/".$self->key, {type=>$method});
}
1;

package Hetzner::Robot::WOL;
use base "Hetzner::Robot::Item";

sub execute {
    my ($self) = @_;
    return $self->req("POST", "/wol/".$self->key, {});
}
1;

package Hetzner::Robot::Server;
use base "Hetzner::Robot::Item";

sub instances {
    my ($this, $robot) = @_;
    my $class = ref($this) || $this;
    my $l = $robot->req("GET", "/server");
    return map { $class->new($robot, $_->{server}{server_ip}) } @$l;
}

sub address {
    my ($self) = @_;
    return $self->key;
}

sub wol {
    my ($self) = @_;
    return new Hetzner::Robot::WOL($self->robot, $self->key);
}

sub reset {
    my ($self) = @_;
    return new Hetzner::Robot::Reset($self->robot, $self->key);
}

sub rescue {
    my ($self) = @_;
    return new Hetzner::Robot::Rescue($self->robot, $self->key);
}

sub __info {
    my ($self) = @_;
    return $self->req("GET", "/server/".$self->key)->{"server"};
}

sub addresses {
    my ($self) = @_;
    return map { Hetzner::Robot::Address->new($self->robot, $_) } @{$self->__info()->{ip}};
}

sub networks {
    my ($self) = @_;
    return map { Hetzner::Robot::Subnet->new($self->robot, $_->{ip}) } @{$self->__info()->{subnet}};
}

1;

package Hetzner::Robot::Address;
use base "Hetzner::Robot::Item";

sub __section { return "ip"; }

sub __info {
    my ($self) = @_;
    return $self->req("GET", "/".$self->__section."/".$self->key)->{$self->__section};
}

sub address {
    my ($self) = @_;
    return $self->key;
}

sub server {
    my ($self) = @_;
    return $self->robot->server($self->__info->{server_ip});
}

sub is_locked {
    my ($self) = @_;
    return $self->__info->{locked};
}

sub __conf {
    my ($self, $var, $val) = @_;
    if (defined $val) {
        my $v = $val ? "true" : "false";
        return $self->req("POST", "/".$self->__section."/".$self->key, {$var => $v})->{$self->__section}{$var};
    } else {
        return $self->__info->{$var};
    }
}

sub traffic_warnings {
    return $_[0]->__conf("traffic_warnings", $_[1]);
}

sub traffic_hourly {
    return $_[0]->__conf("traffic_hourly", $_[1]);
}

sub traffic_daily {
    return $_[0]->__conf("traffic_daily", $_[1]);
}

sub traffic_monthly {
    return $_[0]->__conf("traffic_monthly", $_[1]);
}

1;

package Hetzner::Robot::Subnet;
use base "Hetzner::Robot::Address";

sub __section { return "subnet"; }

sub netmask {
    my ($self) = @_;
    return $self->__info->{mask};
}

sub failover {
    my ($self) = @_;
    if ($self->__info->{failover}) {
        return Hetzner::Robot::Failover->new($self->address);
    } else {
        return undef;
    }
}

1;

##################################

package Hetzner::Robot::RDNS::main;
use Getopt::Long;

sub run {
    my ($robot) = @_;

    my ($get, $set, $del);
    my ($addr, $name);

    my $batch = 0;

    GetOptions (
        'get|g' => \$get,
        'set|s' => \$set,
        'delete|del|d' => \$del,
        'hostname|name|n=s' => \$name,
        'address|addr|a=s' => \$addr,
        'batch' => \$batch
    ) || Hetzner::Robot::main::abort();
    # check command line
    Hetzner::Robot::main::abort("No operation specified!") unless ($get ^ $set ^ $del ^ $batch);
    unless ($batch) {
        Hetzner::Robot::main::abort("No address specified!") if (($get||$set||$del) && !defined $addr);
        Hetzner::Robot::main::abort("No hostname specified!") if ($set && !defined $name);
    }

    sub process {
        my ($addr, $name) = @_;
        my $rdns = new Hetzner::Robot::RDNS($robot, $addr);

        if ($get || $set) {
            if ($set) {
                print STDERR "Setting $addr to $name...\n";
                $rdns->ptr($name);
            }
            print $rdns->addr, "\t", $rdns->ptr, "\n";
        }
        if ($del) {
            print STDERR "Removing RDNS entry for $addr...\n";
            $rdns->del;
        }
    }

    if ($batch) {
        while (<STDIN>) {
            s/[[:space:]]*#.*$//;
            next if (/^$/);
            my ($addr, $name) = split(/[[:space:]]+/);
            my $i = new Hetzner::Robot::RDNS($robot, $addr);
            if ($name ne "") {
                print STDERR "Setting RDNS entry for $addr to $name...\n";
                $i->ptr($name);
            } else {
                print STDERR "Removing RDNS entry for $addr...\n";
                $i->del;
            }
            print $i->address, "\t", $i->ptr, "\n";
        }
    } else {
        # handle a single change
        process($addr, $name);
    }
}

1;

package Hetzner::Robot::Failover::main;
use Getopt::Long;

sub run {
    my ($robot) = @_;
    
    my $addr;
    my $target;
    my $status;

    GetOptions (
        'address|addr|a=s' => \$addr,
        'target=s' => \$target,
        'status' => \$status
    ) || Hetzner::Robot::main::abort();
    Hetzner::Robot::main::abort("No failover address specified!") unless defined $addr;
    
    my $fo = new Hetzner::Robot::Failover($robot, $addr);
    if ($target) {
        my $t = $robot->server($target);
        $fo->target($fo);
    }
    if ($status) {
        print "address:\t".$fo->address."\n";
        print "netmask:\t".$fo->netmask."\n";
        print "server:\t".$fo->server->address."\n";
        print "target:\t".$fo->target->address."\n";
    }
}

1;

package Hetzner::Robot::WOL::main;
use Getopt::Long;

sub run {
    my ($robot) = @_;
    
    my $addr;

    GetOptions (
        'address|addr|a=s' => \$addr,
    ) || Hetzner::Robot::main::abort();
    Hetzner::Robot::main::abort("No server address specified!") unless defined $addr;

    $robot->server($addr)->wol->execute;
}

1;

package Hetzner::Robot::Reset::main;
use Getopt::Long;

sub run {
    my ($robot) = @_;
    
    my $addr;
    my $force = 0;
    my $method = 'sw';

    GetOptions (
        'address|addr|a=s' => \$addr,
        'method' => \$method,
        'force!' => \$force
    ) || Hetzner::Robot::main::abort();
    Hetzner::Robot::main::abort("No server address specified!") unless defined $addr;

    if ($force || confirm_reset($addr, $method)) {
        $robot->server($addr)->reset->execute($method);
    }
}

sub confirm_reset {
    my ($addr, $m) = @_;
    my $magic = "Do as I say!";
    print STDERR "Are you sure you want to reboot the server <$addr> ($m)?\nPlease enter the sentence '$magic'\n> ";
    my $answer = <STDIN>;
    chomp($answer);
    if (lc $answer eq lc $magic) {
        print STDERR "Thank you.\n";
        return 1;
    } else {
        Hetzner::Robot::main::abort("Reset aborted.");
    }
}

1;

package Hetzner::Robot::Rescue::main;
use Getopt::Long;

sub run {
    my ($robot) = @_;
    
    my $enable;
    my $disable;
    my $status;
    my $addr;
    my $arch;
    my $sys;

    GetOptions (
        'enable' => \$enable,
        'disable' => \$disable,
        'status' => \$status,
        'address|addr|a=s' => \$addr,
        'architecture|arch=s' => \$arch,
        'system|sys=s' => \$sys
    ) || Hetzner::Robot::main::abort();
    Hetzner::Robot::main::abort("No server address specified!") unless defined $addr;
    Hetzner::Robot::main::abort("No action (disable/enable/status) specified!") unless ($enable || $disable || $status);
    
    my $rescue = $robot->server($addr)->rescue;
    if ($enable) {
        Hetzner::Robot::main::abort("No operating system specified!") unless defined $sys;
        Hetzner::Robot::main::abort("No architecture specified!") unless defined $arch;
        if ($rescue->enable($sys, $arch)) {
            print "Rescue system enabled, password is:\n";
            print $rescue->password(), "\n";
        }
    }
    if ($disable) {
        $rescue->disable;
    }
    if ($status) {
        my $r = $rescue;
        print "active:\t".$r->active."\n";
        if ($r->active) {
            print "os:\t".$r->os."\n";
            print "arch:\t".$r->arch."\n";
            print "password:\t".$r->password."\n";
        } else {
            print "archs:\t".join(" ", $r->available_arch)."\n";
            print "systems:\t".join(" ", $r->available_os)."\n";
        }
    }
}

1;


package Hetzner::Robot::main;
use Getopt::Long;

sub abort {
    my ($msg) = @_;
    print STDERR $msg,"\n" if $msg;
    exit 1;
}

sub run {
    # available operation modes
    my %modes = (
        rdns      => "RDNS",
        failover  => "Failover",
        wol       => "WOL",
        reset     => "Reset",
        rescue    => "Rescue"
    );
    
    my $p = new Getopt::Long::Parser;
    $p->configure("pass_through");

    my ($user, $pass, $mode);
    $p->getoptions (
        'username|user|u=s' => \$user,
        'password|pass|p=s' => \$pass,
        'mode=s' => \$mode
    ) || abort;
    abort "No user credentials specified!" unless (defined $user && defined $pass);
    abort "No valid operation mode (".join("/", keys %modes).") specified!" unless defined $mode or defined $modes{lc $mode};

    my $robot = new Hetzner::Robot($user, $pass);
    
    if (exists $modes{lc $mode}) {
        no strict 'refs';
        &{"Hetzner::Robot::".$modes{$mode}."::main::run"}($robot);
    } else {
        abort "Unknown mode '$mode'";
    }
}

1;

package default;
# Are we "required" or called as a stand-alone program?
if( ! (caller(0))[7]) {
    Hetzner::Robot::main::run();
}
1;

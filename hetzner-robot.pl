#!/usr/bin/perl
#
# Perl interface for the webservice interface
# provided by Hetzner
#
# by Stefan Tomanek <stefan.tomanek@wertarbyte.de>
#

use strict;
use lib "lib/";

##################################

package Hetzner::Robot::RDNS::main;
use Hetzner::Robot::RDNS;
use Getopt::Long;

sub run {
    my ($robot) = @_;

    my ($get, $set, $del);
    my ($addr, $name);

    my $batch = 0;
    my $all = 0;

    GetOptions (
        'get|g' => \$get,
        'all!' => \$all,
        'set|s' => \$set,
        'delete|del|d' => \$del,
        'hostname|name|n=s' => \$name,
        'address|addr|a=s' => \$addr,
        'batch!' => \$batch
    ) || Hetzner::Robot::main::abort();
    # check command line
    Hetzner::Robot::main::abort("No operation specified!") unless ($get ^ $set ^ $del ^ $batch);
    unless ($batch || ($get && $all)) {
        Hetzner::Robot::main::abort("No address specified!") if (($get||$set||$del) && (!defined $addr));
        Hetzner::Robot::main::abort("No hostname specified!") if ($set && !defined $name);
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
    } elsif ($get && $all) {
        # dump all host entries
        print $_->address."\t".$_->ptr."\n" for Hetzner::Robot::RDNS->enumerate($robot);
    } else {
        # handle a single change
        my $rdns = new Hetzner::Robot::RDNS($robot, $addr);

        if ($get || $set) {
            if ($set) {
                print STDERR "Setting $addr to $name...\n";
                $rdns->ptr($name);
            }
            print $rdns->address, "\t", $rdns->ptr, "\n";
        }
        if ($del) {
            print STDERR "Removing RDNS entry for $addr...\n";
            $rdns->del;
        }
    }
}

1;

package Hetzner::Robot::Failover::main;
use Hetzner::Robot::Failover;
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
        $fo->target($t);
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
use Hetzner::Robot::WOL;
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
use Hetzner::Robot::Reset;
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

package Hetzner::Robot::Boot::Rescue::main;
use Hetzner::Robot::Boot::Rescue;
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
use Hetzner::Robot;
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
        rescue    => "Boot::Rescue"
    );
    
    my $p = new Getopt::Long::Parser;
    $p->configure("pass_through");

    my ($user, $pass, $readpw, $mode);
    $p->getoptions (
        'username|user|u=s' => \$user,
        'password|pass|p=s' => \$pass,
        'readpw' => \$readpw,
        'mode=s' => \$mode
    ) || abort;
    if ($readpw) {
        print STDERR "Reading password from STDIN: ";
        $pass = <STDIN>;
        print STDERR "Thank you.\n";
    }
    abort "No user credentials specified!" unless (defined $user && defined $pass);
    abort "No valid operation mode (".join("/", keys %modes).") specified!" unless defined $mode or defined $modes{lc $mode};

    my $robot = new Hetzner::Robot($user, $pass);
    
    if (exists $modes{lc $mode}) {
        eval {
            no strict 'refs';
            &{"Hetzner::Robot::".$modes{$mode}."::main::run"}($robot);
        };
        die (ref($@) ? $@->msg."\n" : $@) if $@;
    } else {
        abort "Unknown mode '$mode'";
    }
}

1;

package default;
Hetzner::Robot::main::run();

#!/usr/bin/perl
#
# hetzner-rdns.pl
# By Stefan Tomanek <stefan.tomanek@wertarbyte.de>
# http://wertarbyte.de/

use strict;
use LWP::UserAgent;
use Getopt::Long;

my $prot = "https";
my $host = "robot.your-server.de";
my $base = "$prot://$host/";

my $user = undef;
my $pass = undef;

my $get = 0;
my $all = 0;
my $del = 0;
my $set = 0;
my $replace = 0;
my $host = undef;
my $ip = undef;
my $batch = 0;

my $ua = LWP::UserAgent->new;
$ua->cookie_jar( {} );
push @{ $ua->requests_redirectable }, 'POST';
$ua->env_proxy;


sub show_help {
    print STDERR <<EOF;
hetzner-rdns.pl by Stefan Tomanek <stefan.tomanek\@wertarbyte.de>

Authentication:
    --user <login>      Hetzner Robot username
    --password <pass>   Hetzner Robot password
Operation mode:
    --get               Retrieve reverse DNS entries
    --set               Set a new reverse DNS entry
    --delete            Delete an existing DNS entry
    
    --batch             Read list of ip addresses and hostnames from STDIN
                        and transmit all mappings to Hetzner

Parameters:
    --ip <address>      IP address
    --hostname          Hostname to set
    --replace           Replace existing DNS entry
    --all               Retrieve all ip addresses
EOF
    exit 1;
}

sub checkInput {

    unless (defined $user && defined $pass) {
        return 0;
    }
    
    ($batch xor $set xor $del xor $get) || return 0;

    ( $set &&
        (
            not defined $host ||
            not defined $ip ||
            not ($host =~ /^[[:alnum:].]+$/) || 
            not ($ip =~ /^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/)
        )
    ) && return 0;
    ( $del &&
        (
            not defined $ip || 
            not ($ip =~ /[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/)
        )
    ) && return 0;

    ( $batch && (defined $host || defined $ip) ) && return 0;
    return 1;
}

GetOptions (
    'username|user|u=s' => \$user,
    'password|pass|p=s' => \$pass,
    'get|g' => \$get,
    'set|s' => \$set,
    'replace|r!' => \$replace,
    'delete|del|d' => \$del,
    'host|hostname|name|h|n=s' => \$host,
    'ip|i=s' => \$ip,
    'batch|b' => \$batch,
    'all!' => \$all
) || show_help();

checkInput || show_help();

sub start {
    my $r = $ua->get($base);
    die $r->status_line unless $r->is_success();
}

sub login {
    my $r = $ua->post(
        "$base/login/check",
        {
            user            => $user,
            password        => $pass
        }
    );

    if ($r->is_success()) {
        if ($r->decoded_content =~ /Please check your login data/) {
            return 0;
        } else {
            return 1
        };
    } else {
        die $r->status_line;
    }
}

sub get_hosts {
    my %hosts = ();
    my @sid = get_server_ids();
    for my $server_id (@sid) {
        %hosts = (%hosts, %{ get_addresses($server_id) });
        for my $subnet_id (get_subnet_ids($server_id)) {
            %hosts = (%hosts, %{ get_addresses($server_id, $subnet_id) });
        }
    }
    return \%hosts;
}

sub get_addresses {
    my ($server_id, $subnet_id) = @_;
    my %addresses = ();
    my $url = "$base/server/ip/id/$server_id";
    if (defined $subnet_id) {
        $url = "$base/server/net/id/$server_id?net_id=$subnet_id"
    }
    my $r = $ua->post($url);
    if ($r->is_success()) {
        my $d = $r->decoded_content();
        my @addr = ($d =~ m!<strong>([0-9.]+)</strong>!g);
        my @hosts = ($d =~ m!<div id="rdns_[0-9]+(?:_[0-9]+)?" class="rdns_input">([^<]*)<!g);
        while (@addr) {
            my $a = pop @addr;
            my $h = pop @hosts;

            $addresses{$a} = { server_id => $server_id, hostname => $h, subnet_id => $subnet_id };
        }
    }
    return \%addresses;
}

sub get_server_ids {
    my $r = $ua->get("$base/server");
    if ($r->is_success()) {
        my %id = ();
        for ($r->decoded_content =~ m!'/server/ip/id/([0-9]+)'!g) {
            $id{$1} = 1;
        }
        return sort keys %id;
    } else {
        die $r->status_line;
    }
}

sub get_subnet_ids {
    my ($server_id) = @_;
    my $r = $ua->get("$base/server/ip/id/$server_id");
    if ($r->is_success()) {
        my %id = ();
        for ($r->decoded_content =~ m!id="subnet_([0-9]+)_button"!g) {
            $id{$1} = 1;
        }
        return sort keys %id;
    } else {
        die $r->status_line;
    }
}

sub set_host {
    my ($ip, $host, $hosts) = @_;
    
    unless (defined $hosts->{$ip}) {
        print STDERR "Unable to handle address $ip\n";
        return 0;
    }

    if (defined $hosts->{$ip}{hostname}) {
        if ($hosts->{$ip}{hostname} eq $host) {
            print STDERR "No change to address $ip necessary, already mapped to '$host'\n";
            return 1;
        }
        if ($hosts->{$ip}{hostname} ne "") {
            if ($replace) {
                print STDERR "Address $ip already assigned, replacing existing reverse entry\n";
            } else {
                print STDERR "Address $ip already assigned, not replacing it!\n";
                return 0;
            }
        }
    }
    
    print STDERR "Changing $ip to $host (prior: ".$hosts->{$ip}{hostname}.")\n";

    my $sid = $hosts->{$ip}{server_id};
    my $r = $ua->get("$base/server/reversedns/id/$sid?value=$host&ip=$ip");

    unless ($r->is_success()) {
        die $r->status_line;
    } else {
        # check returned data
        if ($r->decoded_content() =~ /<span class=\\"embedded_msgbox_error\\"/) {
            print STDERR "Error setting reverse entry '$host' for address '$ip'!\n";
            return 0;
        } else {
            return 1;
        }
    }
}

sub ip_to_n {
    my ($ip) = @_;
    my $i = 1;
    my $n = 0;
    for my $q (reverse split /\./, $ip) {
        $n += (256**$i)*$q;
        $i++;
    }
    return $n;
}

sub ip_sort {
    ip_to_n($a) <=> ip_to_n($b);
}

sub batch_process {
    my $hosts = get_hosts();
    # read STDIN
    while (<STDIN>) {
        my ($i, $h) = split /\s+/;
        if ( set_host( $i, $h, $hosts ) ) {
            # change local cache on successful update
            $hosts->{$i}{hostname} = $h;
        }
    }
}

start();
unless (login()) {
    print STDERR "Invalid login data\n";
    exit 1;
}

if ($set) {
    set_host( $ip, $host, get_hosts() );
} elsif ($del) {
    set_host( $ip, '', get_hosts() );
} elsif ($get) {
    my %hosts = %{ get_hosts() };

    for my $i (sort ip_sort keys %hosts) {
        my $h = $hosts{$i}{hostname};
        next if (defined $ip && $i ne $ip);
        next if ($h eq "" && ! $all);
        print STDOUT "$i\t$h\n";
    }
} elsif ($batch) {
    batch_process();
}

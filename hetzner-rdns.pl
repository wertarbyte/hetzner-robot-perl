#!/usr/bin/perl
#
# hetzner-rdns.pl
# By Stefan Tomanek <stefan.tomanek@wertarbyte.de>
# http://wertarbyte.de/

use strict;
use LWP::UserAgent;
use Getopt::Long;
use Net::IP;

my $robot_host = "robot.your-server.de";
my $robot_base = "https://$robot_host/";

# cache the robot data
my $robot_data = undef;

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
my $v4 = 1;
my $v6 = 0;

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
    --ipv4 | -4         Handle IPv4 addresses (default)
    --ipv6 | -6         Handle IPv6 addresses as well
EOF
    exit 1;
}

sub valid_v4_address {
    Net::IP::ip_is_ipv4($_[0]);
}

sub valid_v6_address {
    Net::IP::ip_is_ipv6($_[0]);
}

sub valid_hostname {
    $_[0] =~ /^[[:alnum:].-]+$/i;
}

sub checkInput {

    unless (defined $user && defined $pass) {
        return 0;
    }
    
    ($batch xor $set xor $del xor $get) || return 0;

    ( $set &&
        (
            !defined $host ||
            !defined $ip ||
            ! valid_hostname($host) ||
            !( valid_v4_address($ip) || ($v6 && valid_v6_address($ip)))
        )
    ) && return 0;
    ( $del &&
        (
            !defined $ip ||
            !( valid_v4_address($ip) || ($v6 && valid_v6_address($ip)))
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
    'all!' => \$all,
    'ipv4|4!' => \$v4,
    'ipv6|6!' => \$v6
) || show_help();

checkInput || show_help();

sub start {
    my $r = $ua->get($robot_base);
    die $r->status_line unless $r->is_success();
}

sub login {
    my $r = $ua->post(
        "$robot_base/login/check",
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

sub get_robot_data {
    my %data = ();
    if (defined $robot_data) {
        return $robot_data;
    }

    # fetch robot data
    my @sid = get_server_ids();
    # addresses and reverse entries
    my %hosts = ();
    # networks associated with the servers
    my %net = ();
    for my $server_id (@sid) {
        # gather host addresses for each host
        %hosts = (%hosts, %{ get_addresses($server_id) });
        # subnets assigned to the host
        my %snets = %{ get_subnets($server_id) };
        # existing reverse entries
        for my $net_id (keys %snets) {
            %hosts = (%hosts, %{ get_addresses($server_id, $net_id) });
        }
        %net = (%net, %snets);
    }
    $data{host} = \%hosts;
    $data{net} = \%net;
    $robot_data = \%data;
    return $robot_data;
}

sub get_hosts {
    my $data = get_robot_data();
    return $data->{host};
}

sub get_addresses {
    my ($server_id, $subnet_id) = @_;
    my %addresses = ();
    my $url = "$robot_base/server/ip/id/$server_id";
    if (defined $subnet_id) {
        $url = "$robot_base/server/net/id/$server_id?net_id=$subnet_id"
    }
    my $r = $ua->post($url);
    if ($r->is_success()) {
        my $d = $r->decoded_content();
        my @addr = ($d =~ m!<strong>([a-f:0-9.]+)</strong>!g);
        my @hosts = ($d =~ m!<div id="rdns_[0-9]+(?:_[0-9]+)?" ?class="rdns_input">([^<]*)<!g);
        while (@addr) {
            my $a = pop @addr;
            my $h = pop @hosts;

            $addresses{$a} = { server_id => $server_id, hostname => $h, subnet_id => $subnet_id };
        }
    }
    return \%addresses;
}

sub get_server_ids {
    my $r = $ua->get("$robot_base/server");
    if ($r->is_success()) {
        my %id = ();
        my $content = $r->decoded_content;
        while ($content =~ /'\/server\/ip\/id\/([0-9]+)'/g) {
            $id{$1} = 1;
        }
        return sort keys %id;
    } else {
        die $r->status_line;
    }
}

sub get_subnets {
    my ($server_id) = @_;
    my $r = $ua->get("$robot_base/server/ip/id/$server_id");
    if ($r->is_success()) {
        my %id = ();
        my $content = $r->decoded_content;
        
        my @cidr = ($content =~ m!(?:^|[[:space:]]*)([a-f0-9.:]+ / [0-9]{1,3}) *</strong>!ig);
        my @ids = ($content =~ m!'/server/net/id/$server_id\?net_id=([0-9]+)'!g);
        while (@cidr) {
            my $c = pop @cidr;
            my $i = pop @ids;

            my ($prefix, $mask) = ($c =~ m!^([^ /]+) */ *([0-9]+)!);
            $id{$i} = { address => $prefix, mask => $mask, server_id => $server_id, subnet_id => $i };
        }
        return \%id;
    } else {
        die $r->status_line;
    }
}

sub find_server_id {
    my ($addr) = @_;
    my $data = get_robot_data();
    # for addresses directly assigned to the server, we search the address database
    if (defined $data->{host}{$addr}{server_id}) {
        return $data->{host}{$addr}{server_id};
    }
    # for subnets, we might have to compare the netmasks
    my $subnet_id = find_subnet_id($addr);
    return $data->{net}{$subnet_id}{server_id};
}

sub find_subnet_id {
    my ($addr) = @_;
    my $data = get_robot_data();
    my $ip = new Net::IP($addr);
    for my $id (keys %{ $data->{net} }) {
        my $net = new Net::IP($data->{net}{$id}{address}."/".$data->{net}{$id}{mask});
        if ($net->overlaps( $ip ) == $IP_B_IN_A_OVERLAP) {
            return $id;
        }
    }
    return undef;
}

sub set_host {
    my ($ip, $host, $preserve_cache) = @_;

    my $hosts = get_robot_data()->{host};
    
    if (valid_v4_address($ip) && !defined $hosts->{$ip}) {
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
    
    my $sid = find_server_id($ip);
    print STDERR "Changing $ip to $host (prior: ".$hosts->{$ip}{hostname}.")\n";

    my $r = $ua->get("$robot_base/server/reversedns/id/$sid?value=$host&ip=$ip");
    
    unless ($preserve_cache) {
        # invalidate cached data
        $robot_data = undef;
    }

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
    return new Net::IP($ip)->intip();
}

sub ip_sort {
    ip_to_n($a) <=> ip_to_n($b);
}

sub batch_process {
    my $hosts = get_hosts();
    # read STDIN
    while (<STDIN>) {
        my ($i, $h) = split /\s+/;
        if ( set_host( $i, $h, 1) ) {
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
    set_host( $ip, $host);
} elsif ($del) {
    set_host( $ip, '');
} elsif ($get) {
    my %hosts = %{ get_hosts() };

    for my $i (sort ip_sort keys %hosts) {
        next if (!$v4 && valid_v4_address($i));
        next if (!$v6 && valid_v6_address($i));
        my $h = $hosts{$i}{hostname};
        next if (defined $ip && $i ne $ip);
        next if ($h eq "" && ! $all);
        print STDOUT "$i\t$h\n";
    }
} elsif ($batch) {
    batch_process();
}

#!/usr/bin/perl

use strict;
use CGI qw/:standard/;
use IO::File;

my $ADDRESS_FILE = $ENV{RDNSUSERS};
my $ROBOT_NAME = $ENV{ROBOT_USER};
my $ROBOT_PASSWORD = $ENV{ROBOT_PASSWORD};

# clear environment
delete $ENV{ROBOT_USER};
delete $ENV{ROBOT_PASSWORD};

require "hetzner-robot.pl";

my $robot = Hetzner::Robot->new($ROBOT_NAME, $ROBOT_PASSWORD);

sub ptr {
    my ($addr, $name) = @_;
    my $rdns = new Hetzner::Robot::RDNS($robot, $addr);
    return $rdns->ptr($name);
}

sub addresses {
    my ($client) = @_;
    my @l;
    my $fh = new IO::File($ADDRESS_FILE, "r");
    while (<$fh>) {
        s/#.*$//;
        my ($user, @addr) = split /[[:space:]]+/;
        if ($client eq $user) {
            push @l, @addr;
        }
    }
    $fh->close;
    return @l;
}

my $q = new CGI;

print $q->header("text/html");


print start_html;

print start_body;

print $q->h1("Willkommen, ".$q->remote_user);

print start_form;

if ($q->param("change")) {
    for my $a (addresses($q->remote_user)) {
        my $new = $q->param("rdns-$a");
        next unless defined $new;
        # entry changed?
        my $old = ptr($a);
        if ($old ne $new) {
            # set the new value
            ptr($a, $new);
            print p("Changed RDNS entry for $a from $old to $new");
        }
    }
}

my $i = 0;
print table (
    { -border => 1 },
    map {$i++; Tr( td(
        [$i,
        $_,
        textfield(-name=>"rdns-$_", -default=>ptr($_) )]
        ) )
        } addresses($q->remote_user)
);
print hidden(-name=>"change", -default=>"1");
print submit;
print end_form;

print end_body;
print end_html;

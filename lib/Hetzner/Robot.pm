package Hetzner::Robot;
use strict;
use Hetzner::Robot::Server;
use Hetzner::Robot::Exception;
use Hetzner::Robot::AuthException;
use Hetzner::Robot::NotFoundException;

use LWP::UserAgent;
use JSON;
use HTTP::Request;
use HTTP::Status qw(:constants);
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
        # something bad happened, throw an exception
        if ($res->code == HTTP_UNAUTHORIZED) {
            die Hetzner::Robot::AuthException->new();
        }
        if ($res->code == HTTP_NOT_FOUND) {
            die Hetzner::Robot::NotFoundException->new($url);
        }
        # what else might try to ruin our day?
        die Hetzner::Robot::Exception->new("Unable to access ".$url.": [".$res->code."]".$res->status_line);
    }
}

sub server {
    my ($self, $addr) = @_;
    return Hetzner::Robot::Server->new($self, $addr);
}

sub servers {
    my ($self) = @_;
    return Hetzner::Robot::Server->enumerate($self);
}

1;

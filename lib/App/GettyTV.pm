package App::GettyTV;
# ABSTRACT: Control your XBMC like a TV station

use Moo;
use MooX::Options flavour => [qw( pass_through )];
use AnyEvent;
use AnyEvent::WebSocket::Client;
use App::GettyTV::Web;
use App::GettyTV::DB;
use App::GettyTV::XBMC;
use Twiggy::Server;
use Cwd;

option host => (
  is => 'ro',
  predicate => 1,
  format => 's',
  doc => 'host to listen on',
);

option root => (
  is => 'ro',
  lazy => 1,
  default => sub { getcwd },
  format => 's',
  doc => 'root directory (where .gettytv will be made)',
);

option playerhost => (
  is => 'ro',
  lazy => 1,
  default => sub { 'localhost' },
  format => 's',
  doc => 'xbmc websocket url',
);

option playerport => (
  is => 'ro',
  lazy => 1,
  default => sub { 9090 },
  format => 'i',
  doc => 'port to listen on',
);

sub playerws { 'ws://'.join(':',$_[0]->playerhost,$_[0]->playerport).'/jsonrpc' }

option port => (
  is => 'ro',
  lazy => 1,
  default => sub { 9999 },
  format => 'i',
  doc => 'port to listen on',
);

option noweb => (
  is => 'ro',
  lazy => 1,
  default => sub { 0 },
  doc => 'dont startup admin webserver',
);

has db => (
  is => 'ro',
  lazy => 1,
  default => sub { App::GettyTV::DB->connect($_[0]) },
  handles => [qw( resultset )],
);

has twiggy => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my ( $self ) = @_;
    my $server = Twiggy::Server->new(
      $self->has_host ? ( host => $self->host ) : (),
      port => $self->port,
    );
    $server->register_service($self->web->to_psgi_app);
    return $server;
  },
);

has web => (
  is => 'ro',
  lazy => 1,
  default => sub { App::GettyTV::Web->new( gettytv => $_[0] ) },
);

has ws => (
  is => 'ro',
  lazy => 1,
  default => sub { AnyEvent::WebSocket::Client->new },
);

sub BUILD {
  my ( $self ) = @_;
  $self->db;
  unless ($self->noweb) {
    $self->twiggy;
  }
  $self->connect_xbmc;
}

has xbmc => (
  is => 'rw',
  clearer => 1,
  predicate => 1,
);

sub connect_xbmc {
  my ( $self ) = @_;
  return if $self->xbmc;
  print "Connecting to: ".$self->playerws."\n";
  $self->ws->connect($self->playerws)->cb(sub {
    my $connection = eval { shift->recv };
    $self->xbmc(App::GettyTV::XBMC->new(
      gettytv => $self,
      connection => $connection,
    ));
  });
}

sub run { AE::cv->recv }

1;
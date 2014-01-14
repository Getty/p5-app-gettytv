package App::GettyTV::XBMC;

use Moo;
use JSON::MaybeXS;
use Time::HiRes qw( time );

with qw( App::GettyTV::Role );

has connection => (
  is => 'ro',
  lazy => 1,
  required => 1,
);

sub BUILD {
  my ( $self ) = @_;
  $self->connection->on( each_message => sub {
    use DDP; p($_[1]->body);
    $self->incoming_message(decode_json($_[1]->body));
  });
  $self->get_activate_players;
}

sub incoming_message {
  my ( $self, $message ) = @_;
  my $id = $message->{id} ? $message->{id} : $message->{method};
  use DDP; p($message);
  if ($message->{error}) {
    use DDP; p($message);
  } else {
    my @args = defined $message->{result}
      ? ($message->{result})
      : defined $message->{params}
        ? ($message->{params}) : ();
    if (defined $self->callbacks->{$id}) {
      $self->callbacks->{$id}->(@args);
    } else {
      my $method = 'on_'.lc($id);
      $method =~ s/\./_/g;
      if ($self->can($method)) {
        $self->$method(@args);
      }
    }
  }
  delete $self->callbacks->{$id} if defined $self->callbacks->{$id};
}

has current_item => (
  is => 'rw',
  clearer => 1,
);

sub on_player_getactiveplayers {
  my ( $self, $result ) = @_;
  if ($result && scalar @{$result}) {
    my $playerid = $result->[0]->{playerid};
    $self->get_item($playerid, sub {
      my $item = $_[0];
      $self->send('Player.GetProperties',{
        playerid => $playerid,
        properties => [qw( totaltime time audiostreams )],
      },sub {
        $item->{$_} = $_[0]->{$_} for (keys %{$_[0]});
        $self->current_item($item);
      });
    });
  } else {
    $self->gettytv->next;
  }
}

sub on_player_onstop { 
  my ( $self, $result ) = @_;
  my $end = $result->{data}->{end} ? 1 : 0;
  unless ($end) {
    $_[0]->get_activate_players;
  }
}

sub on_player_onplay { $_[0]->get_activate_players }

has callbacks => (
  is => 'ro',
  lazy => 1,
  default => sub {{}},
);

sub next_id {
  my ( $self ) = @_;
  my $next_id = ( time * 100000 );
  while (defined $self->callbacks->{$next_id}) {
    $next_id++;
  }
  return $next_id;
}

sub send {
  my ( $self, $method, $params_ref, $callback ) = @_;
  if (ref $params_ref eq 'CODE') {
    $callback = $params_ref;
    $params_ref = undef;
  }
  my %params = $params_ref ? (%{$params_ref}) : ();
  my $id;
  if (defined $callback) {
    $id = $self->next_id;
    $self->callbacks->{$id} = $callback;
  } else {
    $id = $method;
  }
  my $message = {
    jsonrpc => "2.0",
    method => $method,
    id => $id,
    %params ? ( params => \%params ) : (),
  };
  use DDP; p($message);
  $self->connection->send(encode_json($message));
}

sub show_notification {
  my ( $self, $title, $message, $image ) = @_;
  $self->send(
    'GUI.ShowNotification',
    title => $title,
    message => $message
  );
}

sub get_activate_players {
  my ( $self ) = @_;
  $self->send('Player.GetActivePlayers');
}

sub get_item {
  my ( $self, $playerid, $callback ) = @_;
  $self->send('Player.GetItem',{
    playerid => $playerid,
    properties => [qw( file streamdetails )],
  },$callback);
}
#      directory => "smb://ZINI/Videos/GermanTV/The Following (2013-)",

sub open {
  my ( $self, %item ) = @_;
  $self->clear_current_item;
  $self->send('Player.Open',{ item => { %item }});
}

1;
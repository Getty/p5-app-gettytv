package App::GettyTV::Web;

use Moo;
use Web::Simple;
use Plack::Middleware::Static;

with qw( App::GettyTV::Role );

sub dispatch_request {
  sub (GET) {
    [ 200, [ 'Content-type', 'text/plain' ], [ 'Hello world!' ] ]
  },
  sub () {
    # Plack::Middleware::Static->new(
    # path => $from,
    # root => path($root)->absolute,
    # pass_through => $pass_through ? 1 : 0,
    # defined $content_type
    # ? ( content_type => $content_type )
    # : $self->has_content_type
    # ? ( content_type => $self->content_type )
    # : (),
    # );
  }
}

1;
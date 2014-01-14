package App::GettyTV::DB;
# ABSTRACT: Database schema for GettyTV

use Moo;
extends 'DBIx::Class::Schema';

use DateTime;

__PACKAGE__->load_namespaces;

has gettytv => ( is => 'rw' );

sub connect {
  my ( $self, $gettytv ) = @_;
  $gettytv = $self->gettytv if ref $self;

  my $sqlite_file = $gettytv->root.'/.gettytv.db.sqlite';

  my $dsn = 'dbi:SQLite:'.$sqlite_file;
  my $schema = $self->next::method($dsn, "", "", {
    quote_char => '"',
    name_sep => '.',
    sqlite_unicode => 1,
  });
  $schema->gettytv($gettytv);
  $schema->deploy unless -f $sqlite_file;

  my $share = $schema->resultset('Share')->create({
    path => "bla",
    playlist => "blub",
  });
  my $file = $share->create_related('files',{
    path => "bla",
    last_played => DateTime->now,
  });

  my $ff = $schema->resultset('File')->find($file->id);
  use DDP; p($ff->last_played);

  return $schema;
}

1;

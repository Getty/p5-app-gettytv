package App::GettyTV::Role;

use Moo::Role;

has gettytv => (
  is => 'ro',
  required => 1,
);
sub g { shift->gettytv }

1;
package App::GettyTV::DB::Result::Share;

use DBIx::Class::Candy -components => [
  'TimeStamp', 'InflateColumn::DateTime', 'InflateColumn::Serializer'
];

table "share";

primary_column id => {
  data_type => 'int',
  is_auto_increment => 1,
};

column playlist => {
  data_type => 'text',
  is_nullable => 0,
};

column path => {
  data_type => 'text',
  is_nullable => 0,
};

has_many files => 'App::GettyTV::DB::Result::File', 'share_id';

1;
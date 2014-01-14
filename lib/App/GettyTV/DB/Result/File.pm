package App::GettyTV::DB::Result::File;

use DBIx::Class::Candy -components => [
  'TimeStamp', 'InflateColumn::DateTime', 'InflateColumn::Serializer'
];

table "file";

primary_column id => {
  data_type => 'int',
  is_auto_increment => 1,
};

column path => {
  data_type => 'text',
  is_nullable => 0,
};

column share_id => {
  data_type => 'bigint',
  is_nullable => 0,
};

column last_played => {
  data_type => 'datetime',
  is_nullable => 1,
};

column play_history => {
  data_type => 'text',
  is_nullable => 0,
  serializer_class => 'JSON',
  default_value => '[]',
};

belongs_to 'share', 'App::GettyTV::DB::Result::Share', 'share_id', {
  on_delete => 'cascade',
};

1;
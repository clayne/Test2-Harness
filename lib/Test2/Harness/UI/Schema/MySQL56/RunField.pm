use utf8;
package Test2::Harness::UI::Schema::Result::RunField;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY ANY PART OF THIS FILE

use strict;
use warnings;

use base 'Test2::Harness::UI::Schema::ResultBase';
__PACKAGE__->load_components(
  "InflateColumn::DateTime",
  "InflateColumn::Serializer",
  "InflateColumn::Serializer::JSON",
  "Tree::AdjacencyList",
  "UUIDColumns",
);
__PACKAGE__->table("run_fields");
__PACKAGE__->add_columns(
  "run_field_id",
  { data_type => "binary", is_nullable => 0, size => 16 },
  "run_id",
  { data_type => "binary", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "data",
  { data_type => "longtext", is_nullable => 1 },
  "details",
  { data_type => "text", is_nullable => 1 },
  "raw",
  { data_type => "text", is_nullable => 1 },
  "link",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("run_field_id");
__PACKAGE__->add_unique_constraint("run_id", ["run_id", "name"]);
__PACKAGE__->belongs_to(
  "run",
  "Test2::Harness::UI::Schema::Result::Run",
  { run_id => "run_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2023-03-02 16:05:19
use Test2::Harness::UI::UUID qw/uuid_inflate uuid_deflate/;
__PACKAGE__->inflate_column('run_field_id' => { inflate => \&uuid_inflate, deflate => \&uuid_deflate });
__PACKAGE__->inflate_column('run_id' => { inflate => \&uuid_inflate, deflate => \&uuid_deflate });
# DO NOT MODIFY ANY PART OF THIS FILE

1;

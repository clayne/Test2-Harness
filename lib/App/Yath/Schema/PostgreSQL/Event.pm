use utf8;
package App::Yath::Schema::PostgreSQL::Event;
our $VERSION = '2.000000';

package
    App::Yath::Schema::Result::Event;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY ANY PART OF THIS FILE

use strict;
use warnings;

use parent 'App::Yath::Schema::ResultBase';
__PACKAGE__->load_components(
  "InflateColumn::DateTime",
  "InflateColumn::Serializer",
  "InflateColumn::Serializer::JSON",
  "UUIDColumns",
);
__PACKAGE__->table("events");
__PACKAGE__->add_columns(
  "event_uuid",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "trace_uuid",
  { data_type => "uuid", is_nullable => 1, size => 16 },
  "parent_uuid",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 1, size => 16 },
  "event_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "events_event_id_seq",
  },
  "job_try_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "parent_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "event_idx",
  { data_type => "integer", is_nullable => 0 },
  "event_sdx",
  { data_type => "integer", is_nullable => 0 },
  "stamp",
  {
    data_type     => "timestamp with time zone",
    default_value => \"null",
    is_nullable   => 1,
  },
  "nested",
  { data_type => "smallint", is_nullable => 0 },
  "is_subtest",
  { data_type => "boolean", is_nullable => 0 },
  "is_diag",
  { data_type => "boolean", is_nullable => 0 },
  "is_harness",
  { data_type => "boolean", is_nullable => 0 },
  "is_time",
  { data_type => "boolean", is_nullable => 0 },
  "is_orphan",
  { data_type => "boolean", is_nullable => 0 },
  "causes_fail",
  { data_type => "boolean", is_nullable => 0 },
  "has_facets",
  { data_type => "boolean", is_nullable => 0 },
  "has_binary",
  { data_type => "boolean", is_nullable => 0 },
  "facets",
  { data_type => "jsonb", is_nullable => 1 },
  "rendered",
  { data_type => "jsonb", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("event_id");
__PACKAGE__->add_unique_constraint("events_event_uuid_key", ["event_uuid"]);
__PACKAGE__->add_unique_constraint(
  "events_job_try_id_event_idx_event_sdx_key",
  ["job_try_id", "event_idx", "event_sdx"],
);
__PACKAGE__->has_many(
  "binaries",
  "App::Yath::Schema::Result::Binary",
  { "foreign.event_id" => "self.event_id" },
  { cascade_copy => 0, cascade_delete => 1 },
);
__PACKAGE__->has_many(
  "events_parent_uuids",
  "App::Yath::Schema::Result::Event",
  { "foreign.parent_uuid" => "self.event_uuid" },
  { cascade_copy => 0, cascade_delete => 1 },
);
__PACKAGE__->has_many(
  "events_parents",
  "App::Yath::Schema::Result::Event",
  { "foreign.parent_id" => "self.event_id" },
  { cascade_copy => 0, cascade_delete => 1 },
);
__PACKAGE__->belongs_to(
  "job_try",
  "App::Yath::Schema::Result::JobTry",
  { job_try_id => "job_try_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);
__PACKAGE__->belongs_to(
  "parent",
  "App::Yath::Schema::Result::Event",
  { event_id => "parent_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);
__PACKAGE__->belongs_to(
  "parent_uuid",
  "App::Yath::Schema::Result::Event",
  { event_uuid => "parent_uuid" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-07-29 09:21:17
# DO NOT MODIFY ANY PART OF THIS FILE

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Schema::PostgreSQL::Event - Autogenerated result class for Event in PostgreSQL.

=head1 SOURCE

The source code repository for Test2-Harness can be found at
L<http://github.com/Test-More/Test2-Harness/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut

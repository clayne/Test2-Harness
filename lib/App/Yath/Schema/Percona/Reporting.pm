use utf8;
package App::Yath::Schema::Percona::Reporting;
our $VERSION = '2.000000';

package
    App::Yath::Schema::Result::Reporting;

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
__PACKAGE__->table("reporting");
__PACKAGE__->add_columns(
  "reporting_id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "job_try_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "test_file_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "project_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "user_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "run_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "job_try",
  { data_type => "smallint", is_nullable => 1 },
  "retry",
  { data_type => "smallint", is_nullable => 0 },
  "abort",
  { data_type => "smallint", is_nullable => 0 },
  "fail",
  { data_type => "smallint", is_nullable => 0 },
  "pass",
  { data_type => "smallint", is_nullable => 0 },
  "subtest",
  { data_type => "varchar", is_nullable => 1, size => 512 },
  "duration",
  { data_type => "decimal", is_nullable => 0, size => [14, 4] },
);
__PACKAGE__->set_primary_key("reporting_id");
__PACKAGE__->belongs_to(
  "job_try",
  "App::Yath::Schema::Result::JobTry",
  { job_try_id => "job_try_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "RESTRICT",
  },
);
__PACKAGE__->belongs_to(
  "project",
  "App::Yath::Schema::Result::Project",
  { project_id => "project_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);
__PACKAGE__->belongs_to(
  "run",
  "App::Yath::Schema::Result::Run",
  { run_id => "run_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);
__PACKAGE__->belongs_to(
  "test_file",
  "App::Yath::Schema::Result::TestFile",
  { test_file_id => "test_file_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "RESTRICT",
  },
);
__PACKAGE__->belongs_to(
  "user",
  "App::Yath::Schema::Result::User",
  { user_id => "user_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-07-29 09:21:14
# DO NOT MODIFY ANY PART OF THIS FILE

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Schema::Percona::Reporting - Autogenerated result class for Reporting in Percona.

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

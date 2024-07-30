use utf8;
package App::Yath::Schema::MySQL::User;
our $VERSION = '2.000001';

package
    App::Yath::Schema::Result::User;

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
__PACKAGE__->table("users");
__PACKAGE__->add_columns(
  "user_id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "pw_hash",
  { data_type => "varchar", is_nullable => 1, size => 31 },
  "pw_salt",
  { data_type => "varchar", is_nullable => 1, size => 22 },
  "role",
  {
    data_type => "enum",
    default_value => "user",
    extra => { list => ["admin", "user"] },
    is_nullable => 0,
  },
  "username",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "realname",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("user_id");
__PACKAGE__->add_unique_constraint("username", ["username"]);
__PACKAGE__->has_many(
  "api_keys",
  "App::Yath::Schema::Result::ApiKey",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 1 },
);
__PACKAGE__->has_many(
  "emails",
  "App::Yath::Schema::Result::Email",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 1 },
);
__PACKAGE__->has_many(
  "permissions",
  "App::Yath::Schema::Result::Permission",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 1 },
);
__PACKAGE__->might_have(
  "primary_email",
  "App::Yath::Schema::Result::PrimaryEmail",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 1 },
);
__PACKAGE__->has_many(
  "projects",
  "App::Yath::Schema::Result::Project",
  { "foreign.owner" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 1 },
);
__PACKAGE__->has_many(
  "reports",
  "App::Yath::Schema::Result::Reporting",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 1 },
);
__PACKAGE__->has_many(
  "runs",
  "App::Yath::Schema::Result::Run",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 1 },
);
__PACKAGE__->has_many(
  "session_hosts",
  "App::Yath::Schema::Result::SessionHost",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-07-29 09:21:09
# DO NOT MODIFY ANY PART OF THIS FILE

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Schema::MySQL::User - Autogenerated result class for User in MySQL.

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

use utf8;
package App::Yath::Schema::SQLite::SessionHost;
our $VERSION = '2.000000';

package
    App::Yath::Schema::Result::SessionHost;

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
__PACKAGE__->table("session_hosts");
__PACKAGE__->add_columns(
  "session_host_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "session_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created",
  {
    data_type => "datetime",
    default_value => \"now",
    is_nullable => 0,
    size => 6,
  },
  "accessed",
  {
    data_type => "datetime",
    default_value => \"now",
    is_nullable => 0,
    size => 6,
  },
  "address",
  { data_type => "text", is_nullable => 0 },
  "agent",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("session_host_id");
__PACKAGE__->add_unique_constraint(
  "address_agent_session_id_unique",
  ["address", "agent", "session_id"],
);
__PACKAGE__->belongs_to(
  "session",
  "App::Yath::Schema::Result::Session",
  { session_id => "session_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);
__PACKAGE__->belongs_to(
  "user",
  "App::Yath::Schema::Result::User",
  { user_id => "user_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-07-29 09:21:18
# DO NOT MODIFY ANY PART OF THIS FILE

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Schema::SQLite::SessionHost - Autogenerated result class for SessionHost in SQLite.

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

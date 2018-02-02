use utf8;
package Test2::Harness::UI::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Test2::Harness::UI::Schema::Result::User

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::InflateColumn::Serializer>

=item * L<DBIx::Class::InflateColumn::Serializer::JSON>

=back

=cut

__PACKAGE__->load_components(
  "InflateColumn::DateTime",
  "InflateColumn::Serializer",
  "InflateColumn::Serializer::JSON",
);

=head1 TABLE: C<users>

=cut

__PACKAGE__->table("users");

=head1 ACCESSORS

=head2 user_ui_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'users_user_ui_id_seq'

=head2 username

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 pw_hash

  data_type: 'varchar'
  is_nullable: 0
  size: 31

=head2 pw_salt

  data_type: 'varchar'
  is_nullable: 0
  size: 22

=head2 is_admin

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "user_ui_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "users_user_ui_id_seq",
  },
  "username",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "pw_hash",
  { data_type => "varchar", is_nullable => 0, size => 31 },
  "pw_salt",
  { data_type => "varchar", is_nullable => 0, size => 22 },
  "is_admin",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_ui_id>

=back

=cut

__PACKAGE__->set_primary_key("user_ui_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<users_username_key>

=over 4

=item * L</username>

=back

=cut

__PACKAGE__->add_unique_constraint("users_username_key", ["username"]);

=head1 RELATIONS

=head2 api_keys

Type: has_many

Related object: L<Test2::Harness::UI::Schema::Result::ApiKey>

=cut

__PACKAGE__->has_many(
  "api_keys",
  "Test2::Harness::UI::Schema::Result::ApiKey",
  { "foreign.user_ui_id" => "self.user_ui_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feeds

Type: has_many

Related object: L<Test2::Harness::UI::Schema::Result::Feed>

=cut

__PACKAGE__->has_many(
  "feeds",
  "Test2::Harness::UI::Schema::Result::Feed",
  { "foreign.user_ui_id" => "self.user_ui_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 session_hosts

Type: has_many

Related object: L<Test2::Harness::UI::Schema::Result::SessionHost>

=cut

__PACKAGE__->has_many(
  "session_hosts",
  "Test2::Harness::UI::Schema::Result::SessionHost",
  { "foreign.user_ui_id" => "self.user_ui_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07048 @ 2018-02-02 15:01:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JNL128M9p/80UscOd1ZP2g

sub new {
    my $class = shift;
    my ($attrs) = @_;

    if (my $pw = delete $attrs->{password}) {
        my $salt = $class->gen_salt;
        my $hash = bcrypt_hash({key_nul => 1, cost => COST, salt => $salt}, $pw);

        $attrs->{pw_hash} = en_base64($hash);
        $attrs->{pw_salt} = en_base64($salt);
    }

    my $new = $class->next::method($attrs);

    return $new;
}

sub verify_password {
    my $self = shift;
    my ($pw) = @_;

    my $hash = en_base64(bcrypt_hash({key_nul => 1, cost => COST, salt => de_base64($self->pw_salt)}, $pw));
    return $hash eq $self->pw_hash;
}

sub set_password {
    my $self = shift;
    my ($pw) = @_;

    my $salt = $self->gen_salt;
    my $hash = bcrypt_hash({key_nul => 1, cost => COST, salt => $salt}, $pw);

    $self->update({pw_hash => en_base64($hash), pw_salt => en_base64($salt)});
}

sub gen_salt {
    my $salt = '';
    $salt .= chr(rand() * 256) while length($salt) < 16;
    return $salt;
}

sub gen_api_key {
    my $self = shift;
    my ($name) = @_;

    croak "Must provide a key name"
        unless defined($name);

    my $guid = Data::GUID->new;
    my $val  = $guid->as_string;

    return $self->result_source->schema->resultset('ApiKey')->create(
        {
            user_ui_id => $self->user_ui_id,
            value      => $val,
            status     => 'active',
            name       => $name,
        }
    );
}

1;

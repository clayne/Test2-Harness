package App::Yath::Schema::Overlay::Coverage;
our $VERSION = '2.000002';

package
    App::Yath::Schema::Result::Coverage;
use utf8;
use strict;
use warnings;

use Carp qw/confess/;
confess "You must first load a App::Yath::Schema::NAME module"
    unless $App::Yath::Schema::LOADED;

__PACKAGE__->inflate_column(
    metadata => {
        inflate => DBIx::Class::InflateColumn::Serializer::JSON->get_unfreezer('metadata', {}),
        deflate => DBIx::Class::InflateColumn::Serializer::JSON->get_freezer('metadata', {}),
    },
);

sub human_fields {
    my $self = shift;

    my %cols = $self->get_all_fields;

    $cols{test_file}   //= $self->test_filename;
    $cols{source_file} //= $self->source_filename;
    $cols{source_sub}  //= $self->source_subname;
    $cols{manager}     //= $self->manager_package;

    $cols{metadata} = $self->metadata // ['*'];

    return {map { $_ => $cols{$_} } qw/test_file source_file source_sub manager metadata/};
}

sub test_filename {
    my $self = shift;
    my %cols = $self->get_all_fields;

    return $cols{test_file} // $self->test_file->filename;
}

sub source_filename {
    my $self = shift;
    my %cols = $self->get_all_fields;

    return $cols{source_file} // $self->source_file->filename;
}

sub source_subname {
    my $self = shift;
    my %cols = $self->get_all_fields;

    return $cols{source_sub} // $self->source_sub->subname;
}

sub manager_package {
    my $self = shift;
    my %cols = $self->get_all_fields;

    return $cols{manager} if $cols{manager};
    my $manager = $self->coverage_manager or return undef;
    return $manager->package;
}

1;
__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Schema::Overlay::Coverage - Overlay for Coverage result class.

=head1 DESCRIPTION

This is where custom (not autogenerated) code for the Coverage result class lives.

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

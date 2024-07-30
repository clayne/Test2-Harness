package App::Yath::Schema::Overlay::JobTry;
our $VERSION = '2.000001';

package
    App::Yath::Schema::Result::JobTry;
use utf8;
use strict;
use warnings;

use App::Yath::Schema::ImportModes qw/record_all_events mode_check/;

use Carp qw/confess/;
confess "You must first load a App::Yath::Schema::NAME module"
    unless $App::Yath::Schema::LOADED;

__PACKAGE__->inflate_column(
    parameters => {
        inflate => DBIx::Class::InflateColumn::Serializer::JSON->get_unfreezer('parameters', {}),
        deflate => DBIx::Class::InflateColumn::Serializer::JSON->get_freezer('parameters', {}),
    },
);

sub normalize_to_mode {
    my $self = shift;
    my %params = @_;

    my $mode = $params{mode} // $self->job->run->mode;

    # No need to purge anything
    return if record_all_events(mode => $mode, job => $self->job, try => $self);
    return if mode_check($mode, 'complete');

    if (mode_check($mode, 'summary', 'qvf')) {
        $self->events->delete;
        return;
    }

    my $query = {
        is_diag => 0,
        is_harness => 0,
        is_time => 0,
    };

    if (mode_check($mode, 'qvfds')) {
        $query->{'-not'} = {is_subtest => 1, nested => 0};
    }
    elsif(!mode_check($mode, 'qvfd')) {
        die "Unknown mode '$mode'";
    }

    $self->events->search($query)->delete();
}

sub short_job_try_fields {
    my $self = shift;
    my %params = @_;

    my @fields = $params{prefetched_fields} ? $self->job_try_fields : $self->job_try_fields->search(
        undef, {
            remove_columns => ['data'],
            '+select'      => ['data IS NOT NULL AS has_data'],
            '+as'          => ['has_data'],
        }
    )->all;

    my @out;
    for my $jf (@fields) {
        my $fields = {$jf->get_all_fields};

        my $has_data = delete $fields->{data};
        $fields->{has_data} //= $has_data ? \'1' : \'0';

        push @out => $fields;
    }

    return \@out;
}

my @GLANCE_FIELDS = qw{ exit_code fail job_try_ord job_try_id retry fail_count pass_count status duration };

sub sig {
    my $self = shift;

    my %cols = $self->get_all_fields;

    return join ':' => map { $_ // '' } @cols{@GLANCE_FIELDS};
}

sub glance_data {
    my $self = shift;
    my %params = @_;

    my %cols = $self->get_all_fields;

    my %data;
    @data{@GLANCE_FIELDS} = @cols{@GLANCE_FIELDS};

    $data{fields} = $self->short_job_try_fields;

    return \%data;
}

my %COMPLETE_STATUS = (complete => 1, failed => 1, canceled => 1, broken => 1);
sub complete { return $COMPLETE_STATUS{$_[0]->status} // 0 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Schema::Overlay::JobTry - Overlay for JobTry result class.

=head1 DESCRIPTION

This is where custom (not autogenerated) code for the JobTry result class lives.

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

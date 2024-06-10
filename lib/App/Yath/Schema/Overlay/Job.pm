package App::Yath::Schema::Overlay::Job;
our $VERSION = '2.000000';

package
    App::Yath::Schema::Result::Job;
use utf8;
use strict;
use warnings;

use Carp qw/confess/;
confess "You must first load a App::Yath::Schema::NAME module"
    unless $App::Yath::Schema::LOADED;

*job_tries = *jobs_tries;

sub file {
    my $self = shift;
    my %cols = $self->get_all_fields;

    return $cols{file}     if exists $cols{file};
    return $cols{filename} if exists $cols{filename};

    my $test_file = $self->test_file or return undef;
    return $test_file->filename;
}

sub shortest_file {
    my $self = shift;
    my $file = $self->file or return undef;

    return $1 if $file =~ m{([^/]+)$};
    return $file;
}

sub short_file {
    my $self = shift;
    my $file = $self->file or return undef;

    return $1 if $file =~ m{/(t2?/.*)$}i;
    return $1 if $file =~ m{([^/\\]+\.(?:t2?|pl))$}i;
    return $file;
}

sub complete {
    my $self = shift;

    my @tries = $self->job_tries or return 0;

    my $to_see = 1;
    for my $try (@tries) {
        $to_see--;
        return 0 unless $try->complete;
        $to_see++ if $try->retry;
    }

    return $to_see ? 0 : 1;
}

sub sig {
    my $self = shift;

    my $out = join ';' => map { $_->sig } sort { $a->job_try_ord <=> $b->job_try_ord } $self->jobs_tries;
    $out //= ';';
}

sub TO_JSON {
    my $self = shift;
    my %cols = $self->get_all_fields;

    $cols{short_file}    = $self->short_file;
    $cols{shortest_file} = $self->shortest_file;

    return \%cols;
}

my @GLANCE_FIELDS = qw{ job_uuid is_harness_out };

sub glance_data {
    my $self = shift;
    my %params = @_;

    my $try_id = $params{try_id};

    my %cols = $self->get_all_fields;

    my %data;
    @data{@GLANCE_FIELDS} = @cols{@GLANCE_FIELDS};

    $data{file}          = $self->file;
    $data{short_file}    = $self->short_file;
    $data{shortest_file} = $self->shortest_file;

    my @out;

    for my $try ($self->jobs_tries) {
        next if $try_id && $try->job_try_id != $try_id;
        push @out => {%data, %{$try->glance_data}};
    }

    unless (@out) {
        push @out => {%data, status => 'pending'}
    }

    return @out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Schema::Result::Job - Overlay for Job result class.

=head1 DESCRIPTION

This is where custom (not autogenerated) code for the Job result class lives.

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

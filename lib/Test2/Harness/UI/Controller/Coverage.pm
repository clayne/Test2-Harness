package Test2::Harness::UI::Controller::Coverage;
use strict;
use warnings;

our $VERSION = '0.000065';

use Data::GUID;
use List::Util qw/max/;
use Test2::Harness::UI::Response qw/resp error/;
use Test2::Harness::Util::JSON qw/encode_json encode_pretty_json decode_json/;

use parent 'Test2::Harness::UI::Controller';
use Test2::Harness::UI::Util::HashBase;

sub title { 'Coverage' }

sub handle {
    my $self = shift;
    my ($route) = @_;

    my $req = $self->{+REQUEST};
    my $res = resp(200);

    die error(404 => 'Missing route') unless $route;
    my $source = $route->{source} or die error(404 => 'No source');

    my $schema = $self->{+CONFIG}->schema;

    my $data;
    if (my $project = $schema->resultset('Project')->find({name => $source})) {
        my $run = $project->runs->search({coverage => {'IS NOT' => undef}}, {order_by => {'-desc' => 'run_ord'}, limit => 1})->first;
        $data = $run ? $run->coverage // {} : {};
    }
    elsif (my $run = $schema->resultset('Run')->find({run_id => $source})) {
        $data = $run->coverage // {};
    }
    else {
        die error(405);
    }

    $res->content_type('application/json');
    $res->raw_body($data);

    return $res;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Harness::UI::Controller::Coverage

=head1 DESCRIPTION

=head1 SYNOPSIS

TODO

=head1 SOURCE

The source code repository for Test2-Harness-UI can be found at
F<http://github.com/Test-More/Test2-Harness-UI/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2019 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut

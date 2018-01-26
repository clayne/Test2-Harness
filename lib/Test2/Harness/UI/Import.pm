package Test2::Harness::UI::Import;
use strict;
use warnings;

use DateTime;

use Carp qw/croak/;

use Test2::Harness::Util::JSON qw/encode_json decode_json/;

use Test2::Harness::UI::Util::HashBase qw/-schema/;

sub init {
    my $self = shift;

    croak "'schema' is a required attribute"
        unless $self->{+SCHEMA};
}

sub import_events {
    my $self = shift;

    my $schema = $self->{+SCHEMA};
    $schema->txn_begin;

    my $out;
    my $ok = eval { $out = $self->process_params(@_); 1 };
    my $err = $@;

    if (!$ok) {
        warn $@;
        $schema->txn_rollback;
        return { errors => ['Internal Error'], internal_error => 1 };
    }

    if   ($out->{success}) { $schema->txn_commit }
    else                   { $schema->txn_rollback }

    return $out;
}

sub process_params {
    my $self = shift;
    my ($params) = @_;

    $params = decode_json($params) unless ref $params;

    # Verify credentials
    my $key = $self->verify_credentials($params->{api_key})
        or return {errors => ["Incorrect credentials"]};

    # Verify or create feed
    my ($feed, $error) = $self->find_feed($key, $params);
    return $error if $error;

    my $cnt = 0;
    for my $event (@{$params->{events}}) {
        my $error = $self->import_event($feed, $event);
        return {errors => ["error processing event number $cnt: $error"]} if $error;
        $cnt++;
    }

    return {success => 1, events_added => $cnt, feed => $feed->feed_ui_id};
}

sub find_feed {
    my $self = shift;
    my ($key, $params) = @_;

    my $perms = $params->{permissions} || 'private';

    my $schema = $self->{+SCHEMA};

    # New feed!
    my $feed_ui_id = $params->{feed}
        or return $schema->resultset('Feed')->create({api_key_ui_id => $key->api_key_ui_id, user_ui_id => $key->user_ui_id, permissions => $perms});

    # Verify existing feed

    my $feed = $schema->resultset('Feed')->find({feed_ui_id => $feed_ui_id});

    return (undef, {errors => ["Invalid feed"]}) unless $feed && $feed->user_ui_id == $key->user_ui_id;

    return (undef, {errors => ["permissions ($perms) do not match established permissions (" . $feed->permissions . ") for this feed ($feed_ui_id)"]})
        unless $feed->permissions eq $perms;

    return $feed;
}

sub verify_credentials {
    my $self = shift;
    my ($api_key) = @_;

    return unless $api_key;

    my $schema = $self->{+SCHEMA};
    my $key = $schema->resultset('APIKey')->find({value => $api_key})
        or return undef;

    return undef unless $key->status eq 'active';

    return $key;
}

sub format_stamp {
    my $stamp = shift;
    return undef unless $stamp;
    return DateTime->from_epoch(epoch => $stamp);
}

sub vivify_row {
    my $self = shift;
    my ($type, $field, $find, $create) = @_;

    return (undef, "No $field provided") unless defined $find->{$field};

    my $schema = $self->{+SCHEMA};
    my $row = $schema->resultset($type)->find($find);
    return $row if $row;

    return $schema->resultset($type)->create({%$find, %$create}) || die "Unable to find/add $type: $find->{$field}";
}

sub unique_row {
    my $self = shift;
    my ($type, $field, $find, $create) = @_;

    return (undef, "No $field provided") unless defined $find->{$field};

    my $schema = $self->{+SCHEMA};
    return (undef, "Duplicate $type") if $schema->resultset($type)->find($find);
    return $schema->resultset($type)->create({%$find, %$create}) || die "Could not create $type";
}

sub import_event {
    my $self = shift;
    my ($feed, $event_data) = @_;

    my ($run, $run_error) = $self->vivify_row(
        'Run' => 'run_id',
        {feed_ui_id  => $feed->feed_ui_id, run_id => $event_data->{run_id}},
        {permissions => $feed->permissions},
    );
    return $run_error if $run_error;

    my ($job, $job_error) = $self->vivify_row(
        'Job' => 'job_id',
        {run_ui_id   => $run->run_ui_id, job_id => $event_data->{job_id}},
        {permissions => $feed->permissions},
    );
    return $job_error if $job_error;

    return "No event_id provided" unless $event_data->{event_id};

    my ($event, $error) = $self->unique_row(
        'Event' => 'event_id',
        {job_ui_id => $job->job_ui_id,                    event_id => $event_data->{event_id}},
        {stamp     => format_stamp($event_data->{stamp}), stream_id => $event_data->{stream_id}},
    );
    return $error if $error;

    return $self->import_facets($run, $job, $event, $event_data->{facet_data});
}

sub import_facets {
    my $self = shift;
    my ($run, $job, $event, $facets) = @_;

    return unless $facets;

    my $cnt = 0;
    for my $facet_name (keys %$facets) {
        my $val = $facets->{$facet_name} or next;

        unless (ref($val) eq 'ARRAY') {
            $self->import_facet($run, $job, $event, $facet_name, $val, $cnt++);
            next;
        }

        $self->import_facet($run, $job, $event, $facet_name, $_, $cnt++) for @$val;
    }

    return;
}

sub import_facet {
    my $self = shift;
    my ($run, $job, $event, $facet_name, $val, $cnt) = @_;

    my $schema = $self->{+SCHEMA};

    my $facet = $schema->resultset('Facet')->create(
        {
            event_ui_id => $event->event_ui_id,
            facet_name  => $facet_name,
            facet_value => encode_json($val),
        }
    );
    die "Could not add facet '$facet_name' number $cnt" unless $facet;

    $run->update({facet_ui_id     => $facet->facet_ui_id}) if $facet_name eq 'harness_run' && !$run->facet_ui_id;
    $job->update({job_facet_ui_id => $facet->facet_ui_id}) if $facet_name eq 'harness_job' && !$job->job_facet_ui_id;
    $job->update({end_facet_ui_id => $facet->facet_ui_id, file => $val->{file}, fail => $val->{fail}}) if $facet_name eq 'harness_job_end' && !$job->end_facet_ui_id;
}

1;

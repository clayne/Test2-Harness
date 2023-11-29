package Test2::Harness::Collector;
use strict;
use warnings;

use IO::Select;
use Atomic::Pipe;

use Carp qw/croak/;
use POSIX ":sys_wait_h";
use File::Temp qw/tempfile/;
use Time::HiRes qw/time sleep/;
use Scalar::Util qw/blessed/;

use Test2::Harness::Collector::Auditor;
use Test2::Harness::Collector::IOParser::Stream;

use Test2::Harness::Util qw/mod2file parse_exit open_file/;
use Test2::Harness::Util::JSON qw/decode_json encode_json/;
use Test2::Harness::IPC::Util qw/pid_is_running swap_io start_process ipc_connect/;

our $VERSION = '2.000000';

use Test2::Harness::Util::HashBase qw{
    merge_outputs

    <handles

    <end_callback

    <parser
    <auditor
    <output
    <output_cb

    root_pid

    <run
    <job
    <test_settings

    <workdir

    <start_times

    <run_id
    <job_id
    <job_try

    +clean
    +buffer

    <tempdir

    <interactive
};

sub init {
    my $self = shift;

    croak "'parser' is a required attribute"
        unless $self->{+PARSER};

    croak "'output' is a required attribute"
        unless $self->{+OUTPUT};

    my $ref = ref($self->{+OUTPUT});

    if ($ref eq 'CODE') {
        $self->{+OUTPUT_CB} = $self->{+OUTPUT};
    }
    elsif ($ref eq 'GLOB') {
        my $fh = $self->{+OUTPUT};
        $self->{+OUTPUT_CB} = sub { print $fh encode_json($_) . "\n" for @_ };
    }
    elsif ($self->{+OUTPUT}->isa('Atomic::Pipe')) {
        my $wp = $self->{+OUTPUT};
        $self->{+OUTPUT_CB} = sub { $wp->write_message(encode_json($_)) for @_ };
    }
    else {
        croak "Unknown output type: $self->{+OUTPUT} ($ref)";
    }

    $self->{+START_TIMES} //= [times()];

    $self->{+RUN_ID}        //= 0;
    $self->{+JOB_ID}        //= 0;
    $self->{+JOB_TRY}       //= 0;
    $self->{+MERGE_OUTPUTS} //= 0;

    my ($out_r, $out_w) = Atomic::Pipe->pair(mixed_data_mode => 1);
    my ($err_r, $err_w) = $self->{+MERGE_OUTPUTS} ? ($out_r, $out_w) : Atomic::Pipe->pair(mixed_data_mode => 1);

    $self->{+HANDLES} = {
        out_r => $out_r,
        out_w => $out_w,
        err_r => $err_r,
        err_w => $err_w,
    };
}

my $warned = 0;
sub collect {
    my $class = shift;
    my (%params) = @_;
    my $data = $params{data} //= decode_json($params{json});

    my $root_pid = $data->{root_pid} or die "No root pid";

    # Disconnect from parent group so that a test cannot kill the harness.
    unless ($params{no_setsid}) {
        POSIX::setsid() or die "Could not setsid: $!";
        my $pid = fork // die "Could not fork: $!";
        exit(0) if $pid;
    }

    my $ts = $data->{test_settings} or die "No test_settings provided";
    unless (blessed($ts)) {
        my $tsclass = $ts->{class} // 'Test2::Harness::TestSettings';
        require(mod2file($tsclass));
        $ts = $tsclass->new($ts);
        $params{test_settings} = $ts;
    }

    my $run = $data->{run} or die "No run provided";
    unless(blessed($run)) {
        my $rclass = $run->{run_class} // 'Test2::Harness::Run';
        require(mod2file($rclass));
        $run = $rclass->new($run);
        $params{run} = $run;
    }

    my $job = $data->{job} or die "No job provided";
    unless(blessed($job)) {
        my $jclass = $job->{job_class} // 'Test2::Harness::Run::Job';
        require(mod2file($jclass));
        $job = $jclass->new($job);
        $params{job} = $job;
    }

    $params{workdir} = $data->{workdir} // die "No workdir provided";
    $params{tempdir} = File::Temp::tempdir(DIR => $params{workdir}, CLEANUP => 1, TEMPLATE => "tmp-$$-XXXX");

    my ($inst_ipc, $inst_con) = ipc_connect($run->{instance_ipc});
    my ($agg_ipc,  $agg_con)  = ipc_connect($run->{aggregator_ipc});

    my $inst_handler = sub {
        my ($e) = @_;

        my $fd = $e->{facet_data};

        my ($halt, $result);
        $halt = $fd->{control}->{details} || 'halt' if $fd->{control} && $fd->{control}->{halt};

        if (my $end = $fd->{harness_job_end}) {
            $result = {
                fail => $end->{fail},
                retry => $end->{retry},
            };
        }

        return unless $halt || $result;

        $inst_con->send_and_get(
            job_update => {
                run_id => $run->run_id,
                job_id => $job->job_id,
                result => $result,
                halt   => $halt,
            },
        );
    };

    my $child_pid;
    my $handler;
    if ($agg_con) {
        $handler = sub {
            for my $e (@_) {
                unless (eval { $agg_con->send_message({event => $e}); 1 }) {
                    my $err = $@;
                    die $err unless $err =~ m/Disconnected pipe/;

                    kill('TERM', $child_pid) if $child_pid;
                    exit(255);
                }

                $inst_handler->($e) if $inst_con;
            }
        };
    }
    else {
        $handler = sub {
            for my $e (@_) {
                print STDOUT encode_json($e), "\n";
                $inst_handler->($e) if $inst_con;
            }
        };
    }

    my %create_params = (
        run_id  => $run->run_id,
        job_id  => $job->job_id,
        job_try => $job->try,
        file    => $job->test_file->file,
        name    => $job->test_file->relative,
    );

    my $auditor = Test2::Harness::Collector::Auditor->new(%create_params);
    my $parser  = Test2::Harness::Collector::IOParser::Stream->new(%create_params, type => 'test');

    my $collector = $class->new(
        %create_params,
        %params,
        parser   => $parser,
        auditor  => $auditor,
        output   => $handler,
        root_pid => $root_pid,
    );

    open(our $stderr, '>&', \*STDERR) or die "Could not clone STDERR";

    $SIG{__WARN__} = sub { print $stderr @_ };

    my $ok = eval {
        $collector->launch_and_process(sub {
            my $pid = shift;

            $child_pid = $pid;

            $inst_con->send_and_get(
                job_update => {
                    run_id => $run->run_id,
                    job_id => $job->job_id,
                    pid    => $pid,
                },
            );
        });

        1;
    };

    my $err = $@;

    if (!$ok) {
        $collector->_die($err, no_exit => 1);
        print $stderr $err;
        print STDERR "Test2 Harness Collector Error: $err";
        return 255;
    }

    return 0;
}

sub event_timeout     { my $ts = shift->test_settings or return; $ts->event_timeout }
sub post_exit_timeout { my $ts = shift->test_settings or return; $ts->post_exit_timeout }

sub launch_and_process {
    my $self = shift;
    my ($parent_cb) = @_;

    my $run = $self->{+RUN};
    my $ts  = $self->{+TEST_SETTINGS};
    my $job = $self->{+JOB};

    $self->setup_child();
    my $pid = start_process(@{$job->launch_command($run, $ts)});

    $0 = "yath-collector $pid";

    $parent_cb->($pid) if $parent_cb;
    $self->process($pid);
}

sub _pre_event {
    my $self = shift;
    my (%data) = @_;

    my @events = $self->{+PARSER}->parse_io(\%data);
    @events = $self->{+AUDITOR}->audit(@events) if $self->{+AUDITOR};

    $self->{+OUTPUT_CB}->(@events);

    return;
}

sub _die {
    my $self = shift;
    my ($msg, %params) = @_;

    my @caller = caller();
    $msg .= " at $caller[1] line $caller[2].\n" unless $msg =~ m/\n$/;

    my $stamp = time;
    $self->_pre_event(
        %{$params{event_data} // {}},
        stream => 'process',
        stamp  => $stamp,
        event  => {
            facet_data => {
                %{$params{facets} // {}},
                errors => [{tag => 'ERROR', details => $msg, fail => 1}],
                trace  => {frame => \@caller, stamp => $stamp},
            },
        },
    );

    exit(255) unless $params{no_exit};
}

sub _warn {
    my $self = shift;
    my ($msg, %params) = @_;

    my @caller = caller();
    $msg .= " at $caller[1] line $caller[2].\n" unless $msg =~ m/\n$/;

    my $stamp = time;
    $self->_pre_event(
        %{$params{event_data} // {}},
        stream => 'process',
        stamp  => $stamp,
        event  => {
            facet_data => {
                %{$params{facets} // {}},
                info  => [{tag => 'WARNING', details => $msg, debug => 1}],
                trace => {frame => \@caller, stamp => $stamp}
            },
        },
    );
}

sub setup_child {
    my $self = shift;

    $self->setup_child_env_vars();
    $self->setup_child_output();
    $self->setup_child_input();
}

sub setup_child_output {
    my $self = shift;

    my $handles = $self->handles;

    swap_io(\*STDOUT, $handles->{out_w}->wh, sub { $self->_die(@_) });
    swap_io(\*STDERR, $handles->{err_w}->wh, sub { $self->_die(@_) });

    STDOUT->autoflush();
    STDERR->autoflush();

    select STDOUT;

    $ENV{T2_HARNESS_PIPE_COUNT} = $self->{+MERGE_OUTPUTS} ? 1 : 2;
    {
        no warnings 'once';
        $Test2::Harness::STDOUT_APIPE = $handles->{out_w};
        $Test2::Harness::STDERR_APIPE = $handles->{err_w} unless $self->{+MERGE_OUTPUTS};
    }

    return;
}

sub setup_child_input {
    my $self = shift;

    my $ts = $self->{+TEST_SETTINGS};

    if (my $in_file = $ts->input_file) {
        my $in_fh = open_file($in_file, '<') if $in_file;
        swap_io(\*STDIN, $in_fh, sub { $self->_die(@_) });
    }
    else {
        my $input = $ts->input // "";
        my ($fh, $file) = tempfile("input-$$-XXXX", TMPDIR => 1, UNLINK => 1);
        print $fh $input;
        close($fh);
        open($fh, '<', $file) or die "Could not open '$file' for reading: $!";
        swap_io(\*STDIN, $fh, sub { $self->_die(@_) });
    }

    return;
}

sub setup_child_env_vars {
    my $self = shift;

    my $ts = $self->{+TEST_SETTINGS};

    $ENV{TMPDIR} = $self->tempdir;
    $ENV{T2_TRACE_STAMPS} = 1;

    my $env = $ts->env_vars;
    {
        no warnings 'uninitialized';
        $ENV{$_} = $env->{$_} for keys %$env;
    }

    return;
}

sub close_parent_handles {
    my $self = shift;

    my $handles = $self->handles;

    delete($handles->{out_r})->close();
    delete($handles->{err_r})->close();

    1;
}

sub process {
    my $self = shift;
    my ($child_pid) = @_;

    delete($self->handles->{out_w})->close();
    delete($self->handles->{err_w})->close();

    if (my $job = $self->{+JOB}) {
        my $file   = $job->test_file;
        my $job_id = $job->job_id;

        my $stamp = time;
        $self->_pre_event(
            stream => 'process',
            stamp  => $stamp,
            event  => {
                facet_data => {
                    trace => {frame => [__PACKAGE__, __FILE__, __LINE__], stamp => $stamp},

                    harness_job => {
                        %{$job->process_info},

                        test_file     => $file->process_info,
                        test_settings => $self->{+TEST_SETTINGS},

                        # For compatibility
                        file   => $file->relative,
                        job_id => $job_id,
                    },

                    harness_job_launch => {
                        job_id => $job_id,
                        stamp  => $stamp,
                        retry  => $job->try,
                        pid    => $child_pid,
                    },

                    harness_job_start => {
                        file     => $file->file,
                        abs_file => $file->file,
                        rel_file => $file->relative,

                        stamp   => $stamp,
                        job_id  => $job_id,
                        details => "Launched " . $file->relative . " as job $job_id.",
                    },
                },
            },
        );
    }

    my $sig_stamp;
    $SIG{INT} = sub {
        $sig_stamp //= time;
        $self->_warn("$$: Got SIGINT, forwarding to child process $child_pid.\n");
        kill('INT', $child_pid);

        if (time - $sig_stamp > 5) {
            $SIG{INT} = 'DEFAULT';
            kill('INT', $$);
        }
    };

    $SIG{TERM} = sub {
        $sig_stamp //= time;
        $self->_warn("$$: Got SIGTERM, forwarding to child process $child_pid.\n");
        kill('TERM', $child_pid);

        if (time - $sig_stamp > 5) {
            $SIG{TERM} = 'DEFAULT';
            kill('TERM', $$);
        }
    };

    $SIG{PIPE} = 'IGNORE';

    my $exit = 0;
    my $ok = eval { $exit = $self->_process($child_pid); 1 };
    my $err = $@;

    if ($self->end_callback) {
        my $ok2 = eval { $self->end_callback->($self); 1};
        $err = $ok ? $@ : "$err\n$@";
        $ok &&= $ok2;
    }

    die $err unless $ok;

    return $exit;
}

sub _add_item {
    my $self = shift;
    my ($stream, $val) = @_;

    my $buffer = $self->{+BUFFER} //= {};
    my $seen   = $buffer->{seen}  //= {};

    push @{$buffer->{$stream}} => [time, $val];

    $self->_flush() unless keys(%$seen);

    return unless ref($val);

    my $event_id = $val->{event_id} or die "Event has no ID!";

    my $count = ++($seen->{$event_id});
    return unless $count >= ($self->{+MERGE_OUTPUTS} ? 1 : 2);

    $self->_flush(to => $event_id);
}

sub _flush {
    my $self = shift;
    my %params = @_;

    my $to = $params{to};

    my $buffer = $self->{+BUFFER} //= {};
    my $seen   = $buffer->{seen}  //= {};

    for my $stream (qw/stderr stdout/) {
        while (1) {
            my $set = shift(@{$buffer->{$stream}}) or last;
            my ($stamp, $val) = @$set;
            if (ref($val)) {
                # Send the event, unless it came via STDERR in which case it should only be a hashref with an event_id
                $self->_pre_event(stream => $stream, data => $val, stamp => $stamp)
                    unless $stream eq 'stderr';

                last if $to && $val->{event_id} eq $to;
            }
            else {
                $self->_pre_event(stream => $stream, line => $val, stamp => $stamp);
            }
        }
    }
}

sub _process {
    my $self = shift;
    my ($pid) = @_;

    $self->{+BUFFER} = {seen => {}, stderr => [], stdout => []};

    my $stdout = $self->handles->{out_r};
    my $stderr = $self->handles->{err_r};

    $stdout->blocking(0);
    $stderr->blocking(0);

    my $ios = IO::Select->new;

    my %sets = ($stdout->rh => ['stdout', $stdout]);
    $ios->add($stdout->rh);

    unless ($self->{+MERGE_OUTPUTS}) {
        $sets{$stderr->rh} = ['stderr', $stderr];
        $ios->add($stderr->rh);
    }

    my $last_event = time;

    my ($exited, $exit);
    my $reap = sub {
        my ($flags) = @_;

        return 1 if $exited;
        return 1 if defined $exit;

        local ($!, $?);

        my $check = waitpid($pid, $flags);
        my $code = $?;

        return 0 if $check < 0;
        return 0 if $check == 0 && $flags == WNOHANG;

        die("waitpid returned $check, expected $pid") if $check != $pid;

        $exit = $code;
        $exited = time;
        $last_event = $exited;

        return 1;
    };

    local $SIG{CHLD} = sub { $reap->(0) };

    my $auditor = $self->{+AUDITOR};
    my $ev_timeout = $self->event_timeout;
    my $pe_timeout = $self->post_exit_timeout;

    while (1) {
        my @sets = $ios->can_read(0.2);

        my $did_work = 0;

        while (@sets) {
            for my $io (@sets) {
                my ($name, $fh) = @{$sets{$io}};

                my ($type, $val) = $fh->get_line_burst_or_data;
                unless ($type) {
                    @sets = grep { $_ ne $io } @sets;
                    next;
                }

                $last_event = time;
                $did_work++;

                if ($type eq 'message') {
                    my $decoded = decode_json($val);
                    $self->_add_item($name => $decoded);
                }
                elsif ($type eq 'line') {
                    chomp($val);
                    $self->_add_item($name => $val);
                }
                else {
                    chomp($val);
                    die("Invalid type '$type': $val");
                }
            }

            $self->_flush() if $self->{+INTERACTIVE};
        }

        next if $did_work;

        $reap->(WNOHANG);

        if ($self->{+ROOT_PID} && !pid_is_running($self->{+ROOT_PID})) {
            $self->_warn("Yath exited, killing process.");
            kill('TERM', $pid);
            last;
        }

        if (defined $exited) {
            last if !$auditor;
            last if $auditor->has_plan;
            last if $exit; # If the exit value is not true we do not wait for post-exit timeout
            last unless $pe_timeout;
            my $delta = int(time - $last_event);
            next unless $delta > $pe_timeout;

            $self->_die(
                "Post-exit timeout after $delta seconds. This means your test exited without a issuing plan, but STDOUT remained open, possibly in a child process. At timestamp '$last_event' the output stopped and the test has since timed out.\n",
                facets  => {harness => {timeout => {post_exit => $delta}}},
                no_exit => 1,
            );

            last;
        }

        if ($ev_timeout) {
            my $delta = int(time - $last_event);
            next unless $delta > $ev_timeout;

            $self->_die(
                "Event timeout after $delta seconds. This means your test stopped producing output too long and will be terminated forcefully.\n",
                facets  => {harness => {timeout => {events => $delta}}},
                no_exit => 1,
            );

            last;
        }
    }

    $self->_flush();

    $SIG{CHLD} = 'IGNORE';
    unless (defined($exit // $exited) || $reap->(WNOHANG)) {
        $self->_die("Sending 'TERM' signal to process...\n", no_exit => 1);
        my $did_kill = kill('TERM', $pid);

        my $start = time;
        while ($did_kill) {
            my $delta = time - $start;
            if ($delta > 10) {
                $self->_die("Sending 'KILL' signal to process...\n", no_exit => 1);
                last unless kill('KILL', $pid);

                $reap->(0);
                $exit   //= 255;
                $exited //= 0;
                last;
            }

            last if $reap->(WNOHANG);

            sleep(0.2);
        }
    }

    my $start_times = $self->{+START_TIMES};
    my $end_times = [times];
    my $times = [];
    while (@$start_times) {
        push @$times => shift(@$end_times) - shift(@$start_times);
    }

    $self->_pre_event(
        stream => 'process',
        stamp  => $exited,
        event  => {
            facet_data => {
                trace => {frame => [__PACKAGE__, __FILE__, __LINE__], stamp => $exited},

                harness_job_exit => {
                    job_id => $self->job_id,
                    exit   => $exit,
                    codes  => parse_exit($exit),
                    stamp  => $exited,
                    retry  => $self->should_retry($exit),
                    times  => $times,
                },
            },
        },
    );

    return $exit ? 1 : 0;
}

sub should_retry {
    my $self = shift;
    my ($exit) = @_;
    return 0 unless $exit;

    my $ts = $self->test_settings or return 0;
    return 0 unless $ts->allow_retry;
    return 0 unless $ts->retry;
    return 1 if $self->job_try < $ts->retry;
    return 0;
}

1;

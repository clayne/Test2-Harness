package Test2::Harness::UI::Schema::Result::Job;
use strict;
use warnings;

use parent qw/DBIx::Class::Core/;

__PACKAGE__->table('jobs');
__PACKAGE__->add_columns(qw/job_ui_id run_ui_id facet_ui_id job_id file/);
__PACKAGE__->set_primary_key('job_ui_id');

__PACKAGE__->belongs_to(run => 'Test2::Harness::UI::Schema::Result::Run', 'run_ui_id');
__PACKAGE__->belongs_to(facet => 'Test2::Harness::UI::Schema::Result::Facet', 'facet_ui_id');

__PACKAGE__->has_many(events => 'Test2::Harness::UI::Schema::Result::Event', 'job_ui_id');

1;

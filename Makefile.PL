# This Makefile.PL for Test2-Harness was generated by
# Dist::Zilla::Plugin::MakeMaker::Awesome 0.49.
# Don't edit it but the dist.ini and plugins used to construct it.

use strict;
use warnings;

use 5.010000;
use ExtUtils::MakeMaker;

use Config qw/%Config/;
die "OS unsupported\nTest2-Harness currently only works on systems that support true forking.\n"
    unless $Config{d_fork};
if ($ENV{AUTOMATED_TESTING}) {
    my $is_njh = 0;
    $is_njh ||= -d '/export/home/njh';
    $is_njh ||= -d '/home/njh';
    $is_njh ||= lc($ENV{USER} // 'na') eq 'njh';
    $is_njh ||= lc($ENV{HOME} // 'na') =~ m{njh$};
    $is_njh ||= lc($ENV{PATH} // 'na') =~ m{/njh/};
    die "OS unsupported\nNJH smokers are broken, aborting tests.\n"
        if $is_njh;
}

my %WriteMakefileArgs = (
  "ABSTRACT" => "A new and improved test harness with better Test2 integration.",
  "AUTHOR" => "Chad Granum <exodist\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Test2-Harness",
  "EXE_FILES" => [
    "scripts/yath"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010000",
  "NAME" => "Test2::Harness",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Config" => 0,
    "Cwd" => 0,
    "Data::Dumper" => 0,
    "Data::UUID" => 0,
    "Exporter" => 0,
    "Fcntl" => 0,
    "File::Find" => 0,
    "File::Path" => "2.11",
    "File::Spec" => 0,
    "File::Temp" => 0,
    "Filter::Util::Call" => 0,
    "IO::Compress::Bzip2" => 0,
    "IO::Compress::Gzip" => 0,
    "IO::Handle" => "1.27",
    "IO::Uncompress::Bunzip2" => 0,
    "IO::Uncompress::Gunzip" => 0,
    "IPC::Cmd" => 0,
    "Importer" => "0.025",
    "JSON::PP" => 0,
    "List::Util" => "1.44",
    "Long::Jump" => "0.000001",
    "POSIX" => 0,
    "Scalar::Util" => 0,
    "Scope::Guard" => 0,
    "Symbol" => 0,
    "Sys::Hostname" => 0,
    "Term::Table" => "0.015",
    "Test2" => "1.302170",
    "Test2::API" => "1.302170",
    "Test2::Bundle::Extended" => "0.000127",
    "Test2::Event" => "1.302170",
    "Test2::Event::V2" => "1.302170",
    "Test2::Formatter" => "1.302170",
    "Test2::Plugin::MemUsage" => "0.002003",
    "Test2::Plugin::UUID" => "0.002001",
    "Test2::Tools::AsyncSubtest" => "0.000127",
    "Test2::Tools::Subtest" => "0.000127",
    "Test2::Util" => "1.302170",
    "Test2::Util::Term" => "0.000127",
    "Test2::V0" => "0.000127",
    "Test::Builder" => "1.302170",
    "Test::Builder::Formatter" => "1.302170",
    "Test::More" => "1.302170",
    "Text::ParseWords" => 0,
    "Time::HiRes" => 0,
    "YAML::Tiny" => 0,
    "base" => 0,
    "constant" => 0,
    "goto::file" => "0.005",
    "parent" => 0
  },
  "TEST_REQUIRES" => {
    "File::Copy" => 0
  },
  "VERSION" => "1.000162",
  "test" => {
    "TESTS" => "t/*.t t/integration/*.t t/integration/signals/*.t t/unit/App/*.t t/unit/App/Yath/*.t t/unit/App/Yath/Command/*.t t/unit/App/Yath/Plugin/*.t t/unit/Test2/Harness/*.t t/unit/Test2/Harness/Runner/*.t t/unit/Test2/Harness/Runner/Resource/SharedJobSlots/*.t t/unit/Test2/Harness/Settings/*.t t/unit/Test2/Harness/Util/*.t t/unit/Test2/Harness/Util/File/*.t t/unit/Test2/Tools/*.t"
  }
);

my %FallbackPrereqs = (
  "Carp" => 0,
  "Config" => 0,
  "Cwd" => 0,
  "Data::Dumper" => 0,
  "Data::UUID" => 0,
  "Exporter" => 0,
  "Fcntl" => 0,
  "File::Copy" => 0,
  "File::Find" => 0,
  "File::Path" => "2.11",
  "File::Spec" => 0,
  "File::Temp" => 0,
  "Filter::Util::Call" => 0,
  "IO::Compress::Bzip2" => 0,
  "IO::Compress::Gzip" => 0,
  "IO::Handle" => "1.27",
  "IO::Uncompress::Bunzip2" => 0,
  "IO::Uncompress::Gunzip" => 0,
  "IPC::Cmd" => 0,
  "Importer" => "0.025",
  "JSON::PP" => 0,
  "List::Util" => "1.44",
  "Long::Jump" => "0.000001",
  "POSIX" => 0,
  "Scalar::Util" => 0,
  "Scope::Guard" => 0,
  "Symbol" => 0,
  "Sys::Hostname" => 0,
  "Term::Table" => "0.015",
  "Test2" => "1.302170",
  "Test2::API" => "1.302170",
  "Test2::Bundle::Extended" => "0.000127",
  "Test2::Event" => "1.302170",
  "Test2::Event::V2" => "1.302170",
  "Test2::Formatter" => "1.302170",
  "Test2::Plugin::MemUsage" => "0.002003",
  "Test2::Plugin::UUID" => "0.002001",
  "Test2::Tools::AsyncSubtest" => "0.000127",
  "Test2::Tools::Subtest" => "0.000127",
  "Test2::Util" => "1.302170",
  "Test2::Util::Term" => "0.000127",
  "Test2::V0" => "0.000127",
  "Test::Builder" => "1.302170",
  "Test::Builder::Formatter" => "1.302170",
  "Test::More" => "1.302170",
  "Text::ParseWords" => 0,
  "Time::HiRes" => 0,
  "YAML::Tiny" => 0,
  "base" => 0,
  "constant" => 0,
  "goto::file" => "0.005",
  "parent" => 0
);

unless ( eval { ExtUtils::MakeMaker->VERSION('6.63_03') } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

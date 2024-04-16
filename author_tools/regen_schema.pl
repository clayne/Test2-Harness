use strict;
use warnings;

use DBIx::QuickDB;

use Test2::Harness::UI::Util qw/qdb_driver dbd_driver/;
my $version = Test2::Harness::UI::Util->VERSION;

my $schemadir = './share/schema/';

opendir(my $dh, $schemadir) or die "Could not open schema dir: $!";
for my $schema_file (sort readdir($dh)) {
    next unless $schema_file =~ m/\.sql$/;

    my $schema = $schema_file;
    $schema =~ s/\.sql$//;

    my $qdb_driver = qdb_driver($schema_file);
    my $dbd_driver = dbd_driver($schema_file);

    print "Generating $schema using qdb driver '$qdb_driver' and dbd driver '$dbd_driver'\n";

    my $db = DBIx::QuickDB->build_db($schema => {driver => $qdb_driver, dbd_driver => $dbd_driver});
    {
        my $dbh = $db->connect('quickdb', AutoCommit => 1, RaiseError => 1);
        $dbh->do('CREATE DATABASE harness_ui') or die "Could not create db " . $dbh->errstr;
        $db->load_sql(harness_ui => "${schemadir}/${schema_file}");
    }

    mkdir("./tmp");
    system('rm', '-rf', "./tmp/$schema");
    mkdir("./tmp/$schema");
    system(
        'dbicdump',
        '-o' => 'dump_directory=./tmp/' . $schema,
        '-o' => 'components=["InflateColumn::DateTime", "InflateColumn::Serializer", "InflateColumn::Serializer::JSON", "Tree::AdjacencyList", "UUIDColumns"]',
        '-o' => 'debug=0',
        '-o' => 'generate_pod=0',
        '-o' => 'skip_load_external=1',
        'Test2::Harness::UI::Schema',
        $db->connect_string('harness_ui'),
        '',
        ''
    ) and die "Error";

    system("rm -rf lib/Test2/Harness/UI/Schema/${schema}");
    mkdir "lib/Test2/Harness/UI/Schema/${schema}";
    open(my $fh, '>', "lib/Test2/Harness/UI/Schema/${schema}.pm") or die "Could not open file: $!";
    print {$fh} <<"    EOT";
package Test2::Harness::UI::Schema::${schema};
use utf8;
use strict;
use warnings;
use Carp();

our \$VERSION = '$version';

# DO NOT MODIFY THIS FILE, GENERATED BY ${ \__FILE__ }\n

Carp::confess("Already loaded schema '\$Test2::Harness::UI::Schema::LOADED'") if \$Test2::Harness::UI::Schema::LOADED;

\$Test2::Harness::UI::Schema::LOADED = "${schema}";

require Test2::Harness::UI::Schema;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Harness::UI::Schema::${schema} - Autogenerated schema file for ${schema}.

=head1 SOURCE

The source code repository for Test2-Harness can be found at
L<http://github.com/Test-More/Test2-Harness/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist\@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist\@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7\@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
    EOT
    close($fh);

    opendir(my $dh, "tmp/$schema/Test2/Harness/UI/Schema/Result/") or die "Could not open dir: $!";
    for my $file (sort readdir($dh)) {
        next unless $file =~ m/(.+)\.pm$/;
        my $pkg = $1;

        my $dest = "lib/Test2/Harness/UI/Schema/${schema}/$file";
        print "Found ${file}\n";

        my $from = "tmp/$schema/Test2/Harness/UI/Schema/Result/$file";
        process_uuid($from);
        process_pkg($from, $schema);
        open(my $fh, '>>', $from) or die "Could not open '$from': $!";
        print $fh <<"        EOT";

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Harness::UI::Schema::${schema}::${pkg} - Autogenerated result class for ${pkg} in ${schema}.

=head1 SOURCE

The source code repository for Test2-Harness can be found at
L<http://github.com/Test-More/Test2-Harness/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist\@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist\@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7\@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
        EOT
        close($fh);
        rename($from, $dest) or die "Could not move ${file}: $!";

        my $result = "lib/Test2/Harness/UI/Schema/Result/$file";
        unless (-e $result) {
            print "Adding 'result' file '$result'\n";
            open(my $oh, '>', $result) or die "Could not open result file: $!\n";
            my $ver = Test2::Harness::UI::Util->VERSION;
            print $oh <<"            EOT";
package Test2::Harness::UI::Schema::Result::$pkg;
use utf8;
use strict;
use warnings;

use Carp qw/confess/;
confess "You must first load a Test2::Harness::UI::Schema::NAME module"
    unless \$Test2::Harness::UI::Schema::LOADED;

our \$VERSION = '$ver';

require "Test2/Harness/UI/Schema/\${Test2::Harness::UI::Schema::LOADED}/${pkg}.pm";
require "Test2/Harness/UI/Schema/Overlay/${pkg}.pm";

with 'Test2::Harness::UI::Schema::Roles::Columns';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Harness::UI::Schema::Result::$pkg - Autogenerated result class for $pkg.

=head1 SOURCE

The source code repository for Test2-Harness can be found at
L<http://github.com/Test-More/Test2-Harness/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist\@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist\@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7\@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
            EOT
            close($oh);
        }

        my $override = "lib/Test2/Harness/UI/Schema/Overlay/$file";
        unless (-e $override) {
            print "Adding 'override' file '$override'\n";
            open(my $oh, '>', $override) or die "Could not open override file: $!\n";
            my $pkg = $file;
            $pkg =~ s/\.pm$//;
            my $ver = Test2::Harness::UI::Util->VERSION;
            print $oh <<"            EOT";
package Test2::Harness::UI::Schema::Result::$pkg;
use utf8;
use strict;
use warnings;

use Carp qw/confess/;
confess "You must first load a Test2::Harness::UI::Schema::NAME module"
    unless \$Test2::Harness::UI::Schema::LOADED;

our \$VERSION = '$ver';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Harness::UI::Schema::Result::$pkg - Overlay for $pkg result class.

=head1 DESCRIPTION

This is where custom (not autogenerated) code for the $pkg result class lives.

=head1 SOURCE

The source code repository for Test2-Harness can be found at
L<http://github.com/Test-More/Test2-Harness/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist\@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist\@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7\@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
            EOT
            close($oh);
        }
    }
}

sub process_pkg {
    my ($file, $schema) = @_;

    open(my $fh, "<", $file) or die "Could not open file '$file': $!";

    my @lines;
    for my $line (<$fh>) {
        if ($line =~ m/^package (.*);$/) {
            my $pkg = $1;
            my $real_pkg = $pkg;
            $real_pkg =~ s/::Result::/::${schema}::/g;

            push @lines => (
                "package $real_pkg;\n",
                "package\n    $pkg;\n",
            );
        }
        else {
            push @lines => $line;
        }
    }

    close($fh);
    open($fh, '>', $file) or die "Could not open file '$file': $!";
    print $fh @lines;
    close($fh);
}

sub process_uuid {
    my ($file) = @_;

    open(my $fh, "<", $file) or die "Could not open file '$file': $!";

    my ($found, $end) = (0, 0);
    my $columns = '';
    my @lines;
    while (my $line = <$fh>) {
        if ($line =~ m/DO NOT MODIFY THE FIRST PART OF THIS FILE/) {
            push @lines => "# DO NOT MODIFY ANY PART OF THIS FILE\n";
            next;
        }

        if ($line =~ m/DO NOT MODIFY THIS OR ANYTHING ABOVE/) {
            last;
        }

        if ($line =~ m/use base 'DBIx::Class::Core';/) {
            push @lines => "use base 'Test2::Harness::UI::Schema::ResultBase';\n";
            next;
        }

        push @lines => $line;

        if ($line =~ m/^__PACKAGE__->add_columns\(/) {
            $found ||= $.;
            next;
        }

        next if $end;
        next unless $found;

        if ($line =~ m/^\);/) {
            $end = 1;
            next;
        }

        $columns .= $line;
    }
    close($fh);

    $columns = "(\n#line $found $file\n$columns)";
    my %cols = eval $columns or die $@;

    my @uuids;
    for my $col (keys %cols) {
        my $data = $cols{$col} or next;
        next unless $col eq 'owner' || $col =~ m/_(id|key)$/;
        next unless $data->{data_type} eq 'binary';
        next unless $data->{size} == 16;
        push @uuids => $col;
    };

    open($fh, '>', $file) or die "Could not open file '$file': $!";
    print $fh @lines;

    if (@uuids) {
        my $specs = join "\n" => map { "__PACKAGE__->inflate_column('$_' => { inflate => \\&uuid_inflate, deflate => \\&uuid_deflate });" } @uuids;

        print $fh <<"        EOT";
use Test2::Harness::UI::UUID qw/uuid_inflate uuid_deflate/;
$specs
        EOT
    }

    print $fh "# DO NOT MODIFY ANY PART OF THIS FILE\n";
    print $fh "\n1;\n";
    close($fh);
}

system('rm -rf ./tmp');

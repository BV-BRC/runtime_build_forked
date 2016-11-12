#!/disks/patric-common/runtime/bin/perl
#!/usr/bin/perl

use File::Basename;
use strict;
use Cwd qw(abs_path getcwd);
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;

our $have_template;
eval {
	require Template;
	$have_template++;
};

my($help, $dest, $module_dat);
my $rpm_name;
my $build_rpm;
my $rpm_sandbox = "rpm-sandbox";
my $rpm_version;

my $installwatch;

my($help, $dest, $module_dat);
my @added_path;
GetOptions('h'    => \$help,
	   'help' => \$help,
	   'd=s'    => \$dest,
	   'm=s'    => \$module_dat,
	   "build-rpm" => \$build_rpm,
	   "rpm-name=s" => \$rpm_name,
	   "rpm-version=s" => \$rpm_version,
	   "rpm-sandbox=s" => \$rpm_sandbox,
	   "path=s" => \@added_path,
    ) or pod2usage(0);

pod2usage(-exitstatus => 0,
          -output => \*STDOUT,
          -verbose => 2,
          -noperldoc => 1,
    ) if (defined $help or (!defined $dest) or (!defined $module_dat));

if ($build_rpm)
{
    if (! -d $rpm_sandbox)
    {
	die "RPM sandbox directory $rpm_sandbox does not exist\n";
    }
    $rpm_sandbox = abs_path($rpm_sandbox);

    for my $p (qw(BUILD RPMS SOURCES SPECS SRPMS))
    {
	if (! -d "$rpm_sandbox/$p")
	{
	    mkdir($p) or die "Cannot mkdir $p: $!\n";
	}
    }
}

$ENV{PATH} = join(":", "$dest/bin", @added_path, $ENV{PATH});
$ENV{CPATH} = "$dest/include";
$ENV{LIBRARY_PATH} = "$dest/lib";

my $mbase = basename($module_dat);

my $start_cwd = getcwd();
my $log_dir = "$start_cwd/logs.$mbase";
-d $log_dir || mkdir $log_dir || die "Cannot mkdir $log_dir: $!";
my $log_dir = abs_path($log_dir);

$ENV{TARGET} = $dest;

if (! -d $dest)
{
    mkdir $dest or die "Cannot mkdir $dest: $!";
}

for my $dir (qw(bin lib etc man))
{
    if (! -d "$dest/$dir")
    {
	mkdir "$dest/$dir" or die "Cannot mkdir $dest/$dir: $!";
    }
}

open(DAT, "<", $module_dat) or die "Cannot open $module_dat: $!";

$| = 1;

my @modules;

my %modules;
my %attribs;

while (<DAT>)
{
    chomp;
    s/^\s*//;
    if (/^\#\s+(\S+)\s+(.*)$/)
    {
	$attribs{$1} = $2;
    }
    next if /^\#/;
    my($dir, $cmd) = split(/\s+/, $_, 2);
    die "error parsing $module_dat" unless ($dir && $cmd);
    die "directory $dir does not exist" unless -d $dir;
    die "directory $dir is not executable" unless -e $dir;
    die "directory $dir is not writable" unless -w $dir;

    my $rec = [$dir, $dir, $cmd, { %attribs }];
    push(@modules, $rec);
    push(@{$modules{$dir}}, $rec);
    %attribs = ();
}
close(DAT);

$rpm_version = $attribs{'rpm-version'} if $attribs{'rpm-version'} && !$rpm_version;
$rpm_name = $attribs{'rpm-name'} if $attribs{'rpm-name'} && !$rpm_name;

#
# Rewrite dir-tag element ($rec[1]) for the
# directories that have more than one build record.
#

for my $dir (keys %modules)
{
    my $l = $modules{$dir};
    if (@$l > 1)
    {
	for my $i (0..$#$l)
	{
	    my $n = $i + 1;
	    $l->[$i]->[1] = "${dir}_$n";
	}
    }
}

#die Dumper(\@modules);

my %save = %ENV;

for my $mod (@modules)
{
    my($dir, $tag, $cmd, $attribs) = @$mod;

    if (-f "$log_dir/built.$tag")
    {
	print "$tag already built\n";
	next;
    }

    %ENV = %save;
    for my $env (keys %$attribs)
    {
	print "setenv $env = $attribs->{$env}\n";
	$ENV{$env} = $attribs->{$env};
    }

    my $to_run;
    if ($installwatch)
    {
	$to_run = "cd $dir; $installwatch -o $log_dir/install_data.$tag $cmd 2>&1";
    }
    else
    {
	$to_run = "cd $dir; $cmd 2>&1";
    }
    
    open(LOG, ">", "$log_dir/$tag") or die "Cannot open logfile $log_dir/$tag: $!";
    open(RUN, "$to_run |") or die "Cannot open pipe $to_run: $!";

    print LOG "$to_run\n";
    print "$to_run\n";

    while (<RUN>)
    {
	s/%/%%/g;
	printf "%-10s $_", $tag;
	print LOG $_;
    }
    if (!close(RUN))
    {
	if ($!)
	{
	    die "Error running $to_run: $!\n";
	}
	else
	{
	    die "Command $to_run failed with nonzero status $?\n";
	}
    }
    system("touch", "$log_dir/built.$tag");
    close(LOG);
}

system("git describe --always --tags > $dest/VERSION") == 0 or die "could not write VERSION file to $dest";

&build_rpm if $build_rpm;

sub build_rpm
{
    my $spec_dir = "$rpm_sandbox/SPECS";
    my $rpm_name_base = "$rpm_name-$rpm_version";
    my $rel;

    die "RPM build requires a perl with Template installed\n" unless $have_template;
    for my $p (<$spec_dir/$rpm_name_base*>)
    {
	my($r) = $p =~ /$rpm_name_base-(\d+)/;
	$rel = $r if ($r > $rel);
    }
    $rel++;
    my $spec = "$spec_dir/$rpm_name-$rpm_version-$rel.spec";
    print "Create $spec\n";

    my $templ = Template->new(RELATIVE => 1);

    my $build_root = dirname($dest);
    my $base_name = basename($dest);
    my $vars = {
	name => $rpm_name,
	version => $rpm_version,
	release => $rel,
	summary => "Bootstrap build from $module_dat",
	root_path => $build_root,
	base_name => $base_name,
    };
    $templ->process("bootstrap_spec.tt", $vars, $spec);

    my @cmd = ("rpmbuild",
	       -D => "_topdir $rpm_sandbox",
	       -D => "_builddir $rpm_sandbox/BUILD",
	       -D => "_rpmdir $rpm_sandbox/RPMS",
	       -D => "_sourcedir $rpm_sandbox/SOURCES",
	       -D => "_specdir $rpm_sandbox/SPECS",
	       -D => "_srcrpmdir $rpm_sandbox/SRPMS",
	       '-bb', $spec);
    print "@cmd\n";
    my $rc = system(@cmd);
    if ($rc != 0)
    {
	die "Error $rc building RPM  with @cmd\n";
    }
}

=pod

=head1  NAME

bootstrap_modules.pl

=head1  SYNOPSIS

=over

=item bootstrap_modules.pl -d /kb/runtime -m ./my_modules.dat

=back

=head1  DESCRIPTION

The bootstrap.pl script reads a module.dat and runs a builder for each module. A module is defined as a directory that contains a builder script. For example, kb_blast is a directory that represents a blast module. In that directory is a script that installs blast.

=head1  CONVENTIONS

The module directory may contain a suffix. If there is no suffix, it is assumed that the installer inside that directory will properly install the module on all supported operating systems. If there is a suffix on the module directory in the form _ubuntu and _centos, then the installer inside that directory will properly install the module on the named operating system.

Examples include bootstrap_ubuntu and bootstrap_centos. In side bootstrap_ubuntu the builder script could use apt-get to install ubuntu modules and inside the bootstrap_centos directory the builder script could use yum to install centos modules.

=head1 MODULES FILE

The modules.dat file contains a space delimited set of module directories and builer scripts. You can think of this as the module directory being the key and the name of the builder script being the value if you want. In sort, the named builder script associated with each module directory will be executed.

=head1  COMMAND-LINE OPTIONS

=over

=item -h, --help  This documentation

=item -d Destination target for runtime (ie /kb/runtime)

=item -m Name of the modules.dat file

=back

=head1  AUTHORS

Robert Olson, Tom Brettin

=cut

#!/usr/bin/env perl

use strict;

use Carp;
use File::Basename;
use Cwd 'abs_path';

my $parallel = "-j6";

my $here = abs_path(".");
my $dest = $ENV{TARGET} ? $ENV{TARGET} : "/kb/runtime";

if (@ARGV)
{
    $dest = shift;
    print STDERR "Overriding destination to $dest\n";
}

-d $dest || mkdir $dest;

#my $perl_url = "http://www.cpan.org/src/perl-5.12.4.tar.gz";
#my $perl_url = "http://www.cpan.org/src/5.0/perl-5.16.2.tar.gz";
#my $perl_url = "http://www.cpan.org/src/5.0/perl-5.20.2.tar.gz";
#my $perl_url = "http://www.cpan.org/src/5.0/perl-5.30.2.tar.gz";
#my $perl_url = "http://www.cpan.org/src/5.0/perl-5.36.0.tar.gz";
# 26.3 is needed for the older Gary alignment manipulation code
#my $perl_url = "http://www.cpan.org/src/5.0/perl-5.26.3.tar.gz";
my $perl_url = "http://www.cpan.org/src/5.0/perl-5.38.0.tar.gz";

my $perl_tgz = basename($perl_url);
my $perl_vers = basename($perl_tgz, ".tar.gz");
print "tgz=$perl_tgz vers=$perl_vers\n";

if (! -f $perl_tgz)
{
    run("curl", "-o", $perl_tgz, "-L", $perl_url);
}
if (! -f $perl_tgz)
{
    die "could not get perl\n";
}

run("rm", "-rf", $perl_vers);

if (! -d $perl_vers)
{
    run("tar", "xzf", $perl_tgz);
}

chdir $perl_vers;

my @reloc = ();

my @thread = ('-Dusethreads');

my @opts;

if (0)
{
    push(@opts, @thread);
}

push(@opts, "-Dcc=gcc");

#
# If we're on a mac, assume we are building for the mac DMG.
#
if (-d "/Library")
{
    @reloc = ("-Duserelocatableinc", "-Dusesitecustomize");
    my @startperl = ('-Dstartperl=#!/usr/bin/env kbperl');
    my @for32;
    #@for32 = ("-A", "ld=-m32", "-Dcc=cc -m32"); 
    run("./Configure", "-de", "-Dprefix=$dest", @for32, @reloc, @startperl, @opts);

    # run("./Configure", "-de", "-Dprefix=$dest", );
}
else
{
    run("./Configure", "-de", "-Dprefix=$dest", @reloc, @opts);
}

run("make", $parallel);
run("make install > $here/install.out 2>&1");
#
# Make a symlink kbperl to our real perl. For use initially
# in the mac DMG, but might be useful for forcing use of
# the KB perl in other contexts.
#
symlink("perl", "$dest/bin/kbperl");
sub run
{
    my(@cmd) = @_;
    print "@cmd\n";
    my $rc = system(@cmd);
    $rc == 0 or croak "Failed with rc=$rc: @cmd";
}

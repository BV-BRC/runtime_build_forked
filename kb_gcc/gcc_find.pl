


if(!system("bash", "-c", "module avail > /dev/null 2>&1")) {
  # have module installed so use latest version
  my $cmd = "./gcc_module.sh";
  my $modules = `$cmd`;
  foreach my $line (split /[\n\s]+/, $modules) {
    $line =~ s/\(default\)//;
    push @gccs, $1 if $line =~ /(gcc\S+)/i;
  }

  foreach my $gcc (@gccs) {
    my $ver = find_ver($gcc);
    push @vers, $ver;
    print $gcc, "is at ver ", $ver, "\n";
  }

  my $latest = find_latest(@vers);
  my @module = grep /$latest/, @gccs;
  my $cmd = "./gcc_load.sh \"$module[0]\"";
  my $path = `$cmd` or die;
  chomp $path;
  print "ln -s $path somewhere\n";
}

sub find_ver {
  my $r = $1 if $_[0] =~ /([\d\.]+)/;
  warn "could not find_ver" unless $r;
  return $r;
}

sub find_latest {
  my $latest = 0;
  foreach my $ver (@_) {
    $num = $ver;
    $num =~ s/\.//g;
    if ($latest < $num) {
      $highest = $num;
      $latest = $ver;
    }
  }
  return $latest;
}

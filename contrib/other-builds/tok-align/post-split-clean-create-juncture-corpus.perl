#!/usr/bin/env perl

use warnings;
use strict;
use FindBin qw($RealBin);
use Getopt::Long "GetOptions";

my $DO_FILTER = 0;
my $BIN_SPLIT = 0;

GetOptions(
  "no-filter" => \$DO_FILTER,
  "binary-split" => \$BIN_SPLIT
    );

die("Must provide 8 args: unsplit.input.stem split.input.stem source target output.stem min.length max.length lines-retained \n") if (scalar(@ARGV) != 8);

$DO_FILTER = ! $DO_FILTER;

my $UNSPLIT_INPUT_STEM = $ARGV[0];
my $SPLIT_INPUT_STEM = $ARGV[1];
my $SOURCE		 = $ARGV[2];
my $TARGET		 = $ARGV[3];
my $OUTPUT_STEM = $ARGV[4];
my $MIN_LENGTH = $ARGV[5];
my $MAX_LENGTH = $ARGV[6];
my $LINES_RETAINED = $ARGV[7];

my $MOSES_DIR = "$RealBin/../../..";
my $MOSES_SCRIPT_DIR = "$MOSES_DIR/scripts";
my $cmd;

#add juncture to target side of corpus
$cmd = "$MOSES_DIR/contrib/other-builds/tok-align/tok-align $SPLIT_INPUT_STEM.$TARGET $UNSPLIT_INPUT_STEM.$TARGET --method 2 --junctured-path $SPLIT_INPUT_STEM.juncture.$TARGET ";
if ($BIN_SPLIT) {
  $cmd .= " --binary-split ";
}
$cmd .=" > /dev/null";
safesystem($cmd);

$cmd = "rm -f $SPLIT_INPUT_STEM.juncture.$SOURCE";
safesystem($cmd);

$cmd = "rm -f $SPLIT_INPUT_STEM.juncture.$SOURCE  &&  ln -s $SPLIT_INPUT_STEM.$SOURCE $SPLIT_INPUT_STEM.juncture.$SOURCE";
safesystem($cmd);

# normal clean
if ($DO_FILTER) {
  $cmd = "$MOSES_SCRIPT_DIR/training/clean-corpus-n.perl $SPLIT_INPUT_STEM.juncture $SOURCE $TARGET $OUTPUT_STEM $MIN_LENGTH $MAX_LENGTH $LINES_RETAINED";
  safesystem($cmd);
}
else {
    $cmd = "rm -f $OUTPUT_STEM.$SOURCE  &&  ln -s $SPLIT_INPUT_STEM.juncture.$SOURCE $OUTPUT_STEM.$SOURCE";
    safesystem($cmd);

    $cmd = "rm -f $OUTPUT_STEM.$TARGET  &&  ln -s $SPLIT_INPUT_STEM.juncture.$TARGET $OUTPUT_STEM.$TARGET";
    safesystem($cmd);
}

##################################
sub safesystem {
  print STDERR "Executing: @_\n";
  system(@_);
  if ($? == -1) {
      print STDERR "ERROR: Failed to execute: @_\n  $!\n";
      exit(1);
  }
  elsif ($? & 127) {
      printf STDERR "ERROR: Execution of: @_\n  died with signal %d, %s coredump\n",
          ($? & 127),  ($? & 128) ? 'with' : 'without';
      exit(1);
  }
  else {
    my $exitcode = $? >> 8;
    print STDERR "Exit code: $exitcode\n" if $exitcode;
    return ! $exitcode;
  }
}

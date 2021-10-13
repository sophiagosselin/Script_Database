#!/usr/bin/perl -w

#input: csv table
#make sure your csv input is using commas as the seperator

my $in = $ARGV[0];
open(IN, "< $in");
open(OUT, "+> $in.mrkd");
while(<IN>){
  chomp;
  my @split = split(/\,/, $_);
  foreach my $entries (@split){
    print OUT "\|$entries";
  }
  print OUT "\|\n";
}
close IN;
close OUT;

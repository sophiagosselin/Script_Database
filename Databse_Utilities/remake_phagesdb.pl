#!/usr/bin/perl -w
use strict;
use warnings;

#Sophia Gosselin 03/04/2022
#INPUT: PhagesDB nucleotide multifasta
#OUTPUT: Reannotated multifasta with Phage name and cluster
#You may experience problems if new phages are added
#that have annotation lines that don't match any existing ones
#in that scenaria, please add a line to the nested if statements

my @fastafiles = glob"*.fasta";
my @allnames;
open(OUT, "+> temp.fasta");
foreach my $infile (@fastafiles){
  my($pham)=($infile=~/(.*?)\_.*/);
  open(IN, "< $infile");
  while(<IN>){
    if($_=~/\>/){
      my($phage,$cluster)=($_=~/\>.*\ phage\ ?(.*?)\ .*?Cluster\ (.*?)\n/);
      if(!defined $phage){
        ($phage)=($_=~/\>.*\ phage\ (.*?)[\ \,].*/);
        if(!defined $phage){
          ($phage)=($_=~/\>.*?\ (.*?)\ complete.*/);
          if(!defined $phage){
            ($phage)=($_=~/\>.*?phage\ (.*?)\n/);
            if(!defined $phage){
              ($phage)=($_=~/\>(.*?)\ .*/);
            }
          }
        }
      }

      if(!defined $phage){
        die "Phage name not recognized on annotation line: $_\n";
      }
      $phage=~s/,//g;
      if($phage=~/Phage/){
        ($phage)=($phage=~/Phage (.*)/);
      }
      if($phage=~/_complete/){
        ($phage)=($phage=~/(.*)\_complete/);
      }
      if(!defined $cluster){
        $cluster = "Unknown";
        push(@allnames,$phage);
      }
      print OUT ">Phage:$phage Cluster:$cluster\n";
    }
    else{
      chomp;
      print OUT "$_\n";
    }
  }
  close IN
}
close OUT;

my @metadata;
foreach my $pname (@allnames){
  print "$pname downloading\n";
  system("curl https://phagesdb.org/api/phages/$pname/ > temp_api.out");
  open(API, "< temp_api.out");
  while(<API>){
    my($name)=($_=~/"phage_name"\:(.*?)[\,\}]/);
    my($cluster)=($_=~/"cluster"\:(.*?)[\,\}]/);
    push(@metadata,"$name\t$cluster");
  }
  close API;
  system("rm temp_api.out");
}

my %phageclusters;

foreach(@metadata){
  $_=~ s/"//g;
  my @split = split;
  if(!defined $split[1]){
    $split[1]="Unknown";
  }
  $split[0] = uc $split[0];
  $phageclusters{$split[0]}=$split[1];
}
open(DB, "< temp.fasta");
open(OUT, "+> reannottated_phagedb.fasta");
while(<DB>){
  if($_=~/\>/){
    my($phage,$cluster)=($_=~/\>Phage\:(.*?)\ Cluster\:(.*)/);
    $phage = uc $phage;
    if($cluster eq "Unknown"){
      if(!defined $phageclusters{$phage}){
        print OUT "$_";
        next;
      }
      print OUT ">Phage:$phage\ Cluster:$phageclusters{$phage}\n";
    }
    else{
      print OUT $_;
    }
  }
  else{
    print OUT $_;
  }
}
close OUT;
close DB;

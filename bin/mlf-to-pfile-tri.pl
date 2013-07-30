#!/usr/bin/perl -w
#
# Copyright 2013 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#

# Converts the state-level aligned MLF file (obtained using HVite)
# to the labels in pfile format, required by quicknet toolkit.

use strict ;

if ($#ARGV != 3)
{
    print $#ARGV;
    die ("USAGE: $0 <in-labels (mlf)> <phoneme list> <ID list (for the output order)> <out-labels (pfile)>\n") ;
}

my $in_lab_mlf_fname = $ARGV[0];
my $in_phn_list_fname = $ARGV[1];
my $out_order_list = $ARGV[2];
my $out_lab_pfile_fname = $ARGV[3];

my $sample_period = "100000" ;
my $extn = ".lab" ;

open F, "$in_lab_mlf_fname" or die ("Cannot open $in_lab_mlf_fname for reading\n") ;

my $head = <F>; # Read the #!MLF!#
my $path = "";
my %mlf;
while (my $line = <F>)
{

    if ($path eq "")
    {
        $path = $line;
        chomp $path;
        $path =~ s/^\"//;
        $path =~ s/\"$//;
        $mlf{$path} = []; # A reference to an empty array
    }
    else
    {
        if ($line =~ /^\./) # Starts with a .
        {
            $path = "";
        }
        else
        {
            push @{$mlf{$path}}, $line; # @{} = dereference to an array
        }
    }
}
close F;

# Read the phoneme list
my %phoneme_list = () ;
my $n_phonemes = 0 ;
open F, "$in_phn_list_fname" or die ("Cannot open $in_phn_list_fname for reading\n") ;
while ( <F> )
{
    chomp ;
    $phoneme_list{$_} = $n_phonemes ;
    $n_phonemes ++ ;
}
close F ;
print "No. of phonemes = $n_phonemes\n" ;


open F, "$out_order_list" or die ("Cannot open $out_order_list for reading\n") ;
open G, " | pfile_create -f 0 -l 1 -i - -o $out_lab_pfile_fname" or die $! ;
my $line;
my $current_ID;
my $tbeg_ind = 0 ; my $tend_ind = 0 ; my $state_id ; my $ii ; my $phn;
my $sent_id = 0 ; my $frame_id = 0 ; my $phn_id = 0 ; my $lab_id = 0 ;
my @tmp_arr ;
while ( $current_ID = <F> )
{
    chomp $current_ID;
    $frame_id = 0;
    $current_ID.=$extn;
    foreach $line (@{$mlf{$current_ID}})
    {
        chomp $line ;
        @tmp_arr = split (/\s+/, $line) ;
        if ($#tmp_arr == 2)
        {
            $phn=$tmp_arr[2];
            $phn =~ s/.*-//;
            $phn =~ s/\+.*//;
            $phn =~ s/sp/sil/;
            $phn_id = $phoneme_list{$phn};
        }
        $tbeg_ind = int($tmp_arr[0] / $sample_period + 0.5) ;
        $tend_ind = int($tmp_arr[1] / $sample_period + 0.5) ;

        for ($ii = $tbeg_ind ; $ii < $tend_ind ; $ii ++)
        {
            print G "$sent_id $frame_id $phn_id\n" ;
            $frame_id ++ ;
        }
    }
    $sent_id ++;
}
close F;
close G;

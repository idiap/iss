#!/bin/zsh (not executable, just for editor mode)
#
# Copyright 2010 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#

#
# Splits a file across multiple files contiguously so that concatenating the
# output files the original file is obtained
#
# Marc Ferras, February 2012
#

zmodload zsh/mathfunc

# Check the usage
if [[ $# < 1 ]]
then
    echo "Usage: dealc <infile> <outfile1> <outfile2> ..."
    exit 1
fi

# Variables
local file=$1; shift
local b
local l
local line
local lfile=`cat $file | wc -l`
local blockSize
(( blockSize = float($lfile) / float($#) ))
local toLine=$blockSize


# Pipe the input file into a loop that cycles the output files
rm -f $*
l=0
b=1
while read line
do
    if (( $l < $toLine )) ; then
        echo $line >> $argv[$b]
    else
        # switch to next file
        (( b = b + 1 ))
        (( toLine = b * blockSize ))
        echo $line >> $argv[$b]
    fi
    (( l++ ))
done < $file

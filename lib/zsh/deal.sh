#!/bin/zsh (not executable, just for editor mode)
#
# Copyright 2010 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#

#
# Splits a file across multiple files in the manner that a card dealer
# would do, i.e., cycles through the output files.  The advantage over
# a "cut" is that each target file gets the same number of lines.  It
# fragments the order, which may be good (for randomisation) or bad
# (for fragmentation).  It's slower than split.
#
# Phil Garner, October 2010
#

# Check the usage
if [[ $# < 1 ]]
then
    echo "Usage: deal <infile> <outfile1> <outfile2> ..."
    exit 1
fi

# Variables
local file=$1; shift
local i
local nextLine

# Pipe the input file into a loop that cycles the output files
rm -f $*
while read nextLine
do
    echo $nextLine >> $argv[$((++i))]
    if (( $i == $# ))
    then
        i=0
    fi
done < $file

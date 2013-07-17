#!/bin/zsh
#
# Copyright 2011 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, September 2011
#

#
# Re-estimate models.  Can be called by any script that requires
# re-estimation.  Always writes stats.
#
# Doesn't use Split() Array() Merge() so it can be tagged onto
# something that does use those functions.
#

autoload deal.sh

# Check the usage
if [[ $# < 3 ]]
then
    echo "Usage: reestimate.sh <modelDir> <MLF> <fileList>"
    exit 1
fi

local modelDir=$1
local mlf=$2
local list=$3

# Use a mixture binary model if it exists
bin=-B
mmf=mmf-$mixOrder.bin
if [[ ! -e $modelDir/$mmf ]]
then
    bin=
    mmf=mmf.txt
fi

#
# Split()
#
if [[ $gridMode == serial ]] || [[ $gridMode == split ]]
then
    echo Re-estimating $mmf against $mlf in $modelDir
    deal.sh $list deal/$list.{01..$nJobs}
fi

opts=(
    $bin
    $htsOptions
    -C $htsConfig
    -t $prune
    -I $mlf
    -H $modelDir/$mmf
    -M $modelDir
)

#
# Serial job.  Emulate the grid.
#
if [[ $gridMode == serial ]]
then
    for iter in {1..$nIter}
    do
        for i in {01..$nJobs}
        do
            $herest -p $i -S deal/$list.$i $opts $modelDir/hmm-list.txt &
        done
        echo Waiting for iteration $iter processes
        wait
        echo Done
        $herest -p 0 -s $modelDir/stats.txt $opts $modelDir/hmm-list.txt \
            $modelDir/HER{1..$nJobs}.hmm.acc
    done
    rm $modelDir/HER{1..$nJobs}.hmm.acc
fi

#
# Array()
#
if [[ $gridMode == array ]]
then
    $herest -p $gridTask -S deal/$list.$grid0Task $opts \
        $modelDir/hmm-list.txt
fi

#
# Merge()
#
if [[ $gridMode == merge ]]
then
    $herest -p 0 -s $modelDir/stats.txt $opts $modelDir/hmm-list.txt \
        $modelDir/HER{1..$nJobs}.hmm.acc
    rm $modelDir/HER{1..$nJobs}.hmm.acc
fi

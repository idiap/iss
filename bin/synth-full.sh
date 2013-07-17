#!/bin/zsh
#
# Copyright 2010 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#

#
# Generate a model set suitable for evaluations
# Phil Garner, October 2010
#
this=$0
source $(dirname $0)/config.sh
source $(dirname $0)/grid.sh

autoload create-phone-list.sh

# Generate the exhaustive triphone list
mkdir -p $evalModelDir
create-phone-list.sh $evalModelDir/mono-list.txt

trifle=trifle-list.txt
echo Generating exhaustive triphone list $trifle
if $useMono; then
    echo -n "" > $trifle
else
    echo $silModel > $trifle
fi
if $useSP; then
    echo $spModel >> $trifle
fi

for c in $(cat $evalModelDir/mono-list.txt)
do
    [[ $c == $silModel ]] && continue
    for l in $(cat $evalModelDir/mono-list.txt)
    do
        for r in $(cat $evalModelDir/mono-list.txt)
        do
            echo $l-$c+$r >> $trifle
        done
    done
done

if $useMono; then
    cat $evalModelDir/mono-list.txt >> $trifle
fi
echo Generating model $evalModelDir with full triphone coverage
hed=$evalModelDir/synth.hed
echo LT \"$tiedTrees\" > $hed
echo AU \"$trifle\"    >> $hed
echo CO \"$evalModelDir/hmm-list.txt\" >> $hed
$hhed -A \
    -H $evalSourceDir/mmf-$evalOrder.bin \
    -w $evalModelDir/mmf.txt \
    $hed $evalSourceDir/hmm-list.txt

# Add the sp phone to mono-list.txt so it's a genuine list for WFST
# building and the like.
if $useSP; then
    echo $spModel >> $evalModelDir/mono-list.txt
fi

# Just copy the stats
cp $evalSourceDir/stats.txt $evalModelDir/stats.txt

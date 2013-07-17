#!/bin/zsh
#
# Copyright 2010 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#

#
# Retrain tied models using a linear transform
# Marc Ferras, October 2011
# Phil Garner, October 2010
#
this=$0

function usage
cat << EOF
needs:
$mixModelDir monogaussian content at least

creates:
$mixModelDir new models

EOF

source $(dirname $0)/config.sh

# Grid
nIter=5
array=( $nJobs $nIter )
source $(dirname $0)/grid.sh

autoload deal.sh

if [[ $gridMode == serial ]] || [[ $gridMode == split ]]
then
    # Find the previous highest order MMF
    if [[ $retrainInSuffix != "" ]]
    then
        indir=$tiedModelDir-$retrainInSuffix
    else
        indir=$tiedModelDir
    fi
    oldMMF=$indir/mmf-$mixOrder.bin

    if [[ $retrainOutSuffix != "" ]]
    then
        outdir=$tiedModelDir-$retrainOutSuffix
    else
        outdir=$tiedModelDir
    fi
    mmf=$outdir/mmf-$mixOrder.bin
    mkdir -p $outdir
    echo Creating $mmf from $oldMMF
    cp $oldMMF $mmf
    oldMMF=$mmf
    cp $indir/hmm-list.txt $outdir/hmm-list.txt

    # Training scripts
    deal.sh $trainList deal/$trainList.{01..$nJobs}

    if [[ -f $indir/stats.txt  ]]
    then
        cp -f $indir/stats.txt $outdir/stats.txt
    fi
fi

# Generate stats for possible adaptation later
opts=(
    -B
    -C $htsConfig $htsOptions
    -t $prune
    -I $cdMLF
    -H $outdir/mmf-$mixOrder.bin
    -M $outdir
    -s $outdir/stats.txt 
    -h $decodePattern
)


# add additional dependency directory (for parent xforms)
if [[ $depTransDir != "" ]]
then
    opts+=(
        -J $depTransDir
    )
fi

if [[ $satTransDir != "" ]] && [[ ! $inputTransDir != "" ]]
then
    opts+=(
        -J $satTransDir $satTransExt
        -E $satTransDir $satTransExt
        -a
    )
fi

if [[ $inputTransDir != "" ]] && [[ ! $satTransDir != "" ]]
then
    opts+=(
        -J $inputTransDir $inputTransExt
        -a
    )
fi

if [[ $inputTransDir != "" ]] && [[ $satTransDir != "" ]]
then
    opts+=(
        -J $inputTransDir $inputTransExt
        -J $satTransDir
        -E $satTransDir $satTransExt
        -a
    )
fi

if [[ $gridMode == serial ]]
then
    for iter in {1..$nIter}
    do
        for i in {01..$nJobs}
        do
            $herest -p $i -S deal/$trainList.$i $opts \
                $indir/hmm-list.txt &
        done
        echo Waiting for iteration $iter processes
        wait
        echo Done
        $herest -p 0 -s $modelDir/stats.txt $opts $indir/hmm-list.txt \
            $outdir/HER{1..$nJobs}.hmm.acc
    done
    rm $outdir/HER{1..$nJobs}.hmm.acc
fi

if [[ $gridMode == array ]]
then
    $herest -p $gridTask -S deal/$trainList.$grid0Task $opts \
        $indir/hmm-list.txt
fi

if [[ $gridMode == merge ]]
then
    $herest -p 0 -s $modelDir/stats.txt $opts $indir/hmm-list.txt \
        $outdir/HER{1..$nJobs}.hmm.acc
    rm $outdir/HER{1..$nJobs}.hmm.acc
fi

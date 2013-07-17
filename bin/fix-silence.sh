#!/bin/zsh
#
# Copyright 2010 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#

#
# Fix silence models
# Phil Garner, October 2010
#
this=$0

function usage
cat <<EOF
This is $0
\$WORD_MLF: The raw word-mlf file (no silence, just the words).

needs:
$wordMLF
$flatPhoneList
$flatDict.txt
$targetKind
$featDimension
$ciSourceDir (mmf.txt)

creates:
$mainDict
$mainMLF
$ciModelDir and content
iterations?
EOF

source $(dirname $0)/config.sh

# Grid
nIter=2
array=( $nJobs $nIter )
source $(dirname $0)/grid.sh

autoload prototype.sh deal.sh
autoload create-phone-list.sh

function silHed
cat <<EOF
AT 2 4 0.2 {$silModel.transP}
AT 4 2 0.2 {$silModel.transP}
AT 1 3 0.3 {$spModel.transP}
TI ST_${silModel}_2 {$silModel.state[2]}
TI ST_${silModel}_3 {$silModel.state[3],$spModel.state[2]}
TI ST_${silModel}_4 {$silModel.state[4]}
EOF

function monoLed
cat <<EOF
IS $sentBegin $sentEnd
EX
ME $silModel $spModel $silModel
EOF

if [[ $gridMode == serial ]] || [[ $gridMode == split ]]
then
    # Create phonelist (contains flatPhonelist and sp)
    mkdir -p $ciModelDir
    create-phone-list.sh $ciModelDir/hmm-list.txt
    echo $spModel  >> $ciModelDir/hmm-list.txt

    # Create dictionary to fix silence 
    #echo AS sp > global.ded
    #echo MP sil sil sp >> global.ded
    #$hdman -m -i $mainDict $flatDict
    #rm global.ded

    # Create MLF with sil at the beginning and end and sp between words
    monoLed > $ciModelDir/mono-led.txt
    opts=(
        -d $mainDict
        -i $mainMLF
    )
    [[ $fileListColumns == 1 ]] && opts+=( -l '*' )
    $hled $htsOptions $opts $ciModelDir/mono-led.txt $wordMLF

    # Generate a prototype short pause
    mkdir -p $ciModelDir
    proto=$ciModelDir/$spModel
    prototype.sh $targetKind 3 $featDimension > $proto

    # Script to edit the silence models It helps here to use the same
    # tied names as the cd tie will use.
    silHed > $ciModelDir/sil-hed.txt

    # And do the edit
    $hhed $htsOptions -H $ciSourceDir/mmf.txt -d $ciModelDir -M $ciModelDir \
        $ciModelDir/sil-hed.txt $ciModelDir/hmm-list.txt

    # Train scripts for array stage
    mkdir -p deal
    deal.sh $trainList deal/$trainList.{01..$nJobs}
fi


opts=(
    -C $htsConfig $htsOptions
    -t $prune
    -I $mainMLF
    -H $ciModelDir/mmf.txt
    -M $ciModelDir
)

if [[ $gridMode == serial ]]
then
    for iter in {1..$nIter}
    do
        for i in {01..$nJobs}
        do
            $herest -p $i -S deal/$trainList.$i $opts $ciModelDir/hmm-list.txt &
        done
        echo Waiting for iteration $iter processes
        wait
        echo Done
        $herest -p 0 $opts $ciModelDir/hmm-list.txt \
            $ciModelDir/HER{1..$nJobs}.hmm.acc
    done
    rm $ciModelDir/HER{1..$nJobs}.hmm.acc
fi

if [[ $gridMode == array ]]
then
    $herest -p $gridTask -S deal/$trainList.$grid0Task $opts \
        $ciModelDir/hmm-list.txt
fi

if [[ $gridMode == merge ]]
then
    $herest -p 0 $opts $ciModelDir/hmm-list.txt \
        $ciModelDir/HER{1..$nJobs}.hmm.acc
    rm $ciModelDir/HER{1..$nJobs}.hmm.acc
fi

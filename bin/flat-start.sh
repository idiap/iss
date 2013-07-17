#!/bin/zsh
#
# Copyright 2010 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#

#
# Flat start monophone models
# Phil Garner, October 2010
#
this=$0

function usage
cat <<EOF
This is $0
\$PHONESET [$phoneSet]:
 The name of the phoneset to be used.
 (Needs to be defined in \$PHONESET_CSV [$phoneSetCSV])
\$SAMPA_MAP:
 The mapping of some \$PHONESET_CSV entries to computer (htk) readable
 characters. Different mappings should be separated by "," and the values
 with "/" (i.e. 2/_2_,9/_9_)
\$WORD_MLF:
 The raw word-mlf file (no silence, just the words).
\$DICT_DIR/\$DICT_NAME:
 The directory and the name of the raw dictionary in the format
 [word\ttranscription].

needs:
$phoneSetCSV
$phoneSet
$sampaMap (optional)
creates:
$flatPhoneList
$flatModelDir and content
EOF

source $(dirname $0)/config.sh

# Grid
nIter=5
array=( $nJobs $nIter )
source $(dirname $0)/grid.sh

autoload deal.sh
autoload create-phone-list.sh

# HHEd script to merge and floor
function mergeHed
cat <<EOF
FV vFloors
EOF

# HLEd script to create monophone MLF with sentence boundaries
function monoLed
cat <<EOF
IS $sentBegin $sentEnd
EX
EOF


if [[ $gridMode == serial ]] || [[ $gridMode == split ]]
then

    # Build a file list
    if [[ ! -e $trainList ]]
    then
        echo Generating $trainList
        while read ID file 
        do
            feats=$ID"="$featsDir/$featName/$file".htk"
            echo $feats >> $trainList
        done < $fileList
    fi

    # Create the flat-start model
    echo Initialising $flatModelDir
    mkdir -p $flatModelDir

    # Create the phonelist
    echo Writing PhoneList to $flatModelDir
    create-phone-list.sh $flatModelDir/hmm-list.txt

    # One prototype for each phone
    proto=$(echo $protoMMF | sed s/....$//)
    for m in $(cat $flatModelDir/hmm-list.txt)
    do
        cat $proto | sed s/$proto/$m/ > $flatModelDir/$m
    done

    # Merge the separate prototypes into one
    mergeHed > $flatModelDir/merge-hed.txt
    opts=(
        -d $flatModelDir
        -w $flatModelDir/mmf.txt
    )
    $hhed $htsOptions $opts \
        $flatModelDir/merge-hed.txt $flatModelDir/hmm-list.txt

    # Create a flat monophone MLF
    monoLed > $flatModelDir/mono-led.txt
    opts=(
        -d $flatDict
        -i $flatMLF
    )
    [[ $fileListColumns == 1 ]] && opts+=( -l '*' )
    $hled $htsOptions $opts $flatModelDir/mono-led.txt $wordMLF

    # Train scripts for array stage
    mkdir -p deal
    deal.sh $trainList deal/$trainList.{01..$nJobs}
fi



opts=(
    -C $htsConfig $htsOptions
    -t $prune
    -I $flatMLF
    -H $flatModelDir/mmf.txt
    -M $flatModelDir
)

if [[ $gridMode == serial ]]
then
    for iter in {1..$nIter}
    do
        for i in {01..$nJobs}
        do
            $herest -p $i -S deal/$trainList.$i $opts \
                $flatModelDir/hmm-list.txt &
        done
        echo Waiting for iteration $iter processes
        wait
        echo Done
        $herest -p 0 $opts $flatModelDir/hmm-list.txt \
            $flatModelDir/HER{1..$nJobs}.hmm.acc
    done
    rm $flatModelDir/HER{1..$nJobs}.hmm.acc
fi


if [[ $gridMode == array ]]
then
    $herest -p $gridTask -S deal/$trainList.$grid0Task $opts \
        $flatModelDir/hmm-list.txt
fi

if [[ $gridMode == merge ]]
then
    $herest -p 0 $opts $flatModelDir/hmm-list.txt \
        $flatModelDir/HER{1..$nJobs}.hmm.acc
    rm $flatModelDir/HER{1..$nJobs}.hmm.acc
fi

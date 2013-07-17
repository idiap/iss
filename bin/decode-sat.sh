#!/bin/zsh
#
# Copyright 2010 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, October 2010
#

#
# Decode transcriptions using SAT
#
this=$0
source $(dirname $0)/config.sh

function usage
cat << EOF
needs:
$decodeAcousticModelDir/hmm-list.txt
$decodeAcousticModelDir/mmf.txt

creates:
$decodeList
EOF

autoload deal.sh
autoload config-hvite.sh
autoload create-file-list.sh

function configHDecode
cat <<EOF
TARGETKIND = $targetKind
USEHMODEL = T
STARTWORD = <s>
ENDWORD = </s>
EOF

function Split
{
    # Build a file list
    rm -f $decodeList
    create-file-list.sh $decodeList

    case $decoder in
    HVite)
        config-hvite.sh > hvite.cnf
        ;;
    HDecode)
        configHDecode > hdecode.cnf
        ;;
    esac

    # Train scripts for array stage
    mkdir -p deal
    deal.sh $decodeList deal/$decodeList.{01..$nJobs}
}

function Array
{
    echo Decoding with $decoder
    case $decoder in
    HVite)
        opts=(
            -C hvite.cnf $htsOptions
            -w $decodeLanguageModelDir/network.txt
            -H $decodeAcousticModelDir/mmf.txt
            -t $prune
            -s $decodeLMScale
            -p $decodeWordPenalty
            -S deal/$decodeList.$grid0Task
            -i /dev/shm/$decodeMLF.$grid0Task.$$
        )

        if [[ $depTransDir != "" ]]
        then
            # -J can't be the last option
            opts+=(
                -J $depTransDir
            )
        fi

        if [[ $decodeTransDir != "" ]]
        then
            if [[ $satTransDir != "" ]]
            then
                opts+=(
                    -J $decodeTransDir
                    -E $satTransDir txt
                    -h $decodePattern
                    -k
                )
            else
                # -J can't be the last option
                opts+=(
                    -J $decodeTransDir txt
                    -h $decodePattern
                    -k
                )
            fi
        fi
        $hvite $opts \
            $decodeLanguageModelDir/main-dict.txt \
            $decodeAcousticModelDir/hmm-list.txt
        mv /dev/shm/$decodeMLF.$grid0Task.$$ $decodeMLF.$grid0Task
        ;;
    HDecode)
        opts=(
            -C hdecode.cnf $htsOptions
            -H $decodeAcousticModelDir/mmf.txt
            -d $decodeAcousticModelDir
            -w $decodeLanguageModelDir/arpa-ngram.txt
            -s $decodeLMScale
            -p $decodeWordPenalty
            -k $decodeBlockSize
            -t $prune
            -v $prune
            -S deal/$decodeList.$grid0Task
            -i /dev/shm/$decodeMLF.$grid0Task.$$
        )

        if [[ $depTransDir != "" ]]
        then
            # -J can't be the last option
            opts+=(
                -J $depTransDir
            )
        fi

        if [[ $depTransDir2 != "" ]]
        then
            # -J can't be the last option
            opts+=(
                -J $depTransDir2
            )
        fi


        if [[ $satTransDir != "" ]] && [[ ! $decodeTransDir != "" ]] ; then
            opts+=(
                -J $satTransDir $satTransExt
                -E $satTransDir $satTransExt
                -h $decodePattern
                -m
            )
        fi

        if [[ $decodeTransDir != "" ]] && [[ ! $satTransDir != "" ]] ; then
            opts+=(
                -J $decodeTransDir $decodeTransExt
                -h $decodePattern
                -m
            )
        fi

        if [[ $decodeTransDir != "" ]] && [[ $satTransDir != "" ]] ; then
            opts+=(
                -J $decodeTransDir $decodeTransExt
                -J $satTransDir
                -E $satTransDir $satTransExt
                -h $decodePattern
                -m
            )
        fi

        $hdecode $opts \
            $decodeLanguageModelDir/flat-dict.txt \
            $decodeAcousticModelDir/hmm-list.txt
        mv /dev/shm/$decodeMLF.$grid0Task.$$ $decodeMLF.$grid0Task
    esac
}

function Merge
{
    # Without -X rec it will rename to .lab
    $hled -X rec -i $decodeMLF /dev/null $decodeMLF.{01..$nJobs}
    rm $decodeMLF.{01..$nJobs}
}

# Grid
array=( $nJobs 1 )
source $(dirname $0)/grid.sh

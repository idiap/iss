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
# Decode transcriptions
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
autoload config-hvite-cid.sh
autoload config-hvite-notree.sh
autoload create-file-list.sh

function configHDecode
cat <<EOF
TARGETKIND = $targetKind
USEHMODEL = T
STARTWORD = <s>
ENDWORD = </s>
EOF

function juicerWarning
cat <<EOF
Your version of juicer has written a cmd.log file.  This will cause trouble
when multiple juicers run in the same directory.  To fix it, use a version
of juicer with this suppressed.  It's this code right at the beginning of
main() in juicer.cpp:

int main( int argc , char *argv[] )
{
    // Command line parser.  The option prevents writing the cmd.log
    // file, which in turn means that multiple instances can run in
    // the same directory.
    CmdLine cmd ;
    cmd.setBOption("write log", false);
    ...
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
    HVite_*)
        case $decodeCD in 
        '0')
            config-hvite-cid.sh > hvite.cnf
            ;;
        '1')
            config-hvite.sh > hvite.cnf
            ;;
        '2')
            config-hvite-notree.sh > hvite.cnf
            ;;
        esac
        case $fileListColumns in
        '1')
            cp $decodeList $decodeList-temp
            ;;
        '2')
            cut -d "=" -f 2 $decodeList > $decodeList-temp 
            ;;
        esac

        found=1;
        for n in `cat ${decodeList}-temp`
        do
            if [ ! -e $n ]
            then
                found=0;
            fi
        done
        
        if [ $found -eq 0 ]
        then
            cat $decodeList-temp | xargs -n 1 dirname | sort -u | xargs -n 1 mkdir -p
            $feacat -i $activationFile -op htk -ol $decodeList-temp
        else
            touch split2merge
        fi

        rm $decodeList-temp

        if [ ! -e $decodeAcousticModelDir/$model_name ]
        then
            mkdir models
            cmd="$createInitialModels $modelCreationType $decodeAcousticModelDir/$trainLabels models/"
            echo $cmd
            eval $cmd
            cmd="$createHTKHMMS models/ $decodeAcousticModelDir/$trainLabels $decodeAcousticModelDir/$model_name"
            echo $cmd
            eval  $cmd
        fi
        if [ ! -e $decodeAcousticModelDir/$phonelist ]
        then
            cp $decodeAcousticModelDir/hmm-list.txt $decodeAcousticModelDir/$phonelist
            echo "sp" >> $decodeAcousticModelDir/$phonelist
        fi
        ;;
    HDecode)
        configHDecode > hdecode.cnf
        ;;
    esac

    if [[ $decodeLatices != "" ]]
    then
        mkdir -p $decodeLatices
    fi

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
        if [[ $decodeTransDir != "" ]]
        then
            # -J can't be the last option
            opts+=(
                -J $decodeTransDir txt
                -h $decodePattern
                -k
            )
        fi
        $hvite $opts \
            $decodeLanguageModelDir/main-dict.txt \
            $decodeAcousticModelDir/hmm-list.txt
        mv /dev/shm/$decodeMLF.$grid0Task.$$ $decodeMLF.$grid0Task
        ;;
    HVite_*)
        opts=(  
            -C hvite.cnf $htsOptions
            -o N
            -w $decodeLanguageModelDir/network.txt
            -H $decodeAcousticModelDir/$model_name 
            -t $prune
            -s $decodeLMScale
            -p $decodeWordPenalty
            -S deal/$decodeList.$grid0Task
            -i /dev/shm/$decodeMLF.$grid0Task.$$ 
        )

        if [[ ! -e $decodeMLF.$grid0Task ]]
        then
            cp $decodeDict /dev/shm/dict.$$.$grid0Task
            case $decoder in 
            HVite_kl)
                $hvite_kl $opts \
                    /dev/shm/dict.$$.$grid0Task \
                    $decodeAcousticModelDir/$phonelist
                ;;
            HVite_rkl)          
                $hvite_rkl $opts \
                    /dev/shm/dict.$$.$grid0Task \
                    $decodeAcousticModelDir/$phonelist
                ;;
            HVite_skl)          
                $hvite_skl $opts \
                    /dev/shm/dict.$$.$grid0Task \
                    $decodeAcousticModelDir/$phonelist
                ;;
            HVite_scalar)               
                $hvite_scalar $opts \
                    /dev/shm/dict.$$.$grid0Task \
                    $decodeAcousticModelDir/$phonelist
                ;;
            esac
            mv /dev/shm/$decodeMLF.$grid0Task.$$ $decodeMLF.$grid0Task
            rm /dev/shm/dict.$$.$grid0Task
        fi

        for n in `cut -d "=" -f 1 deal/$decodeList.$grid0Task`
        do
            count=`grep -wc "\"${n}.rec\"" $decodeMLF.$grid0Task`;
            if [ $count != "1" ]
            then
                echo "PROBLEM with ${n} on "`hostname`
            fi
        done
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
        if [[ $decodeTransDir != "" ]]
        then
            # -J can't be the last option
            opts+=(
                -J $decodeTransDir txt
                -h $decodePattern
                -m
            )
        fi

        if [[ $decodeOutput != "" ]]
        then
            opts+=(
                -o $decodeOutput
            )
        fi

        if [[ $decodeLatices != "" ]]
        then
            opts+=(
                -l $decodeLatices
                -z $decodeLatices
            )
        fi

        $hdecode $opts \
            $decodeLanguageModelDir/flat-dict.txt \
            $decodeAcousticModelDir/hmm-list.txt
        mv /dev/shm/$decodeMLF.$grid0Task.$$ $decodeMLF.$grid0Task
        ;;

    Juicer)
        opts=(
            -lexFName $wfstDict
            -inputFormat htk
            -inputFName deal/$decodeList.$grid0Task
            -fsmFName $clgDir/CLG.fsm
            -inSymsFName $clgDir/CLG.insyms
            -outSymsFName $clgDir/CLG.outsyms
            -htkModelsFName $decodeAcousticModelDir/mmf.txt
            -sentStartWord $sentBegin
            -sentEndWord $sentEnd
            -outputFormat xmlf
            -outputFName $decodeMLF.$grid0Task
            -mainBeam $decodeBeam[1]
            -phoneEndBeam $decodeBeam[2]
            -phoneStartBeam $decodeBeam[3]
            -maxHyps 0
            -lmScaleFactor $decodeLMScale
            -insPenalty $decodeWordPenalty
            -logFName stdout
        )
        export Tracter_shConfig=1
        $juicer $opts
        [[ -f cmd.log ]] && juicerWarning
    esac
}

function Merge
{
    # Without -X rec it will rename to .lab
    $hled -X rec -i $decodeMLF /dev/null $decodeMLF.{01..$nJobs}
    rm $decodeMLF.{01..$nJobs}
    case $decoder in
    HVite_*)
        if [ -e split2merge ]
        then
            rm split2merge
        else
            rm -rf $featsDir/$featName
        fi
        ;;
    esac
}

# Grid
array=( $nJobs 1 )
source $(dirname $0)/grid.sh

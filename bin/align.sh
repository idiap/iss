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
# Align transcriptions to data
#
this=$0

function usage
cat <<EOF
This is $0

needs:
$wordMLF

creates:
$alignList (if not existing)
EOF


source $(dirname $0)/config.sh
autoload deal.sh
autoload config-hvite.sh
autoload create-file-list.sh

function Split 
{
    # Build a file list
    rm -f $alignList
    create-file-list.sh $alignList

    case $decoder in
    HVite)
        if [[ $alignCD == 1 ]]
        then
            config-hvite.sh > hvite.cnf
        fi
        if [[ ! -e $htsConfig ]]
        then
            echo Please run init-train.sh to generate $htsConfig
        fi

        ;;
    HVite_*)
        if [[ $alignCD == 1 ]]
        then
            config-hvite.sh > hvite.cnf
        fi

        if [[ $crossWord == 0 ]]
        then
            sed 's/ALLOWXWRDEXP = T/ALLOWXWRDEXP = F/' hvite.cnf > hvite.cnf.temp
            mv hvite.cnf.temp hvite.cnf
        fi

        case $fileListColumns in
        '1')
            cp $alignList $alignList-temp
            ;;
        '2')
            cut -d "=" -f 2 $alignList > $alignList-temp 
            ;;
        esac
        found=1;
        echo $found > split2merge.temp
        for n in `cat ${alignList}-temp`
        do
            if [ ! -e $n ]
            then
                found=0;
            fi
        done

        if [ $found -eq 0 ]
        then
            cat $alignList-temp | xargs -n 1 dirname | sort -u | xargs -n 1 mkdir -p
            $feacat -i $activationFile -op htk -ol $alignList-temp
        fi
        rm $alignList-temp

        if [ ! -e $alignModelDir/$model_name ]
        then
            mkdir models
            $createInitialModels delta $alignModelDir/hmm-list.txt models/
            $createHTKHMMS models/ $alignModelDir/hmm-list.txt $alignModelDir/$model_name
        fi
        if [ ! -e $alignModelDir/$phonelist ]
        then
            cp $alignModelDir/hmm-list.txt $alignModelDir/$phonelist
            echo "sp" >> $alignModelDir/$phonelist
        fi
        ;;
    *)
        echo "Decoder $decoder cannot be used to align"
        exit 1
        ;;
    esac

    # Create the lists
    mkdir -p deal
    deal.sh $alignList deal/$alignList.{01..$nJobs}

    # We need a word MLF with start end tokens
    echo "IS <s> </s>" > align-led.txt
    opts=(
        -i $alignWordMLF
    )
    [[ $fileListColumns == 1 ]] && opts+=( -l '*' )
    $hled $htsOptions $opts align-led.txt $wordMLF
}

function Array
{

    case $decoder in
    HVite)
        opts=(
            -C $htsConfig $htsOptions $alignOptions 
            -o SW
            -a
            -H $alignModelDir/$alignModel
            -m
            -t $prune
            -y lab
            -I $alignWordMLF
            -i /dev/shm/$alignMLF.$grid0Task.$$
            -S deal/$alignList.$grid0Task
        )

        if [[ $alignCD == 1 ]]
        then
            opts=( $opts -C hvite.cnf )
        fi

        $hvite $opts $mainDict $alignModelDir/hmm-list.txt
        mv /dev/shm/$alignMLF.$grid0Task.$$ $alignMLF.$grid0Task
        ;;
    HVite_*)
        opts=(
            $htsOptions $alignOptions
            -a
            -o SW
            -H $alignModelDir/$model_name
            -I $alignWordMLF
            -m
            -y lab
            -t $prune
            -i /dev/shm/$alignMLF.$grid0Task.$$
            -S deal/$alignList.$grid0Task
        )
        if [[ $alignCD == 1 ]]
        then
           # opts=( $opts -C hvite.cnf -b "<s>")
            opts=( $opts -C hvite.cnf)
        fi

        case $decoder in
        HVite_kl)
            $hvite_kl $opts $mainDict $alignModelDir/$phonelist
            ;;
        HVite_rkl)
            $hvite_rkl $opts $mainDict $alignModelDir/$phonelist
            ;;
        HVite_skl)
            $hvite_skl $opts $mainDict $alignModelDir/$phonelist
            ;;
        HVite_scalar)
            $hvite_scalar $opts $mainDict $alignModelDir/$phonelist
            ;;
        esac
        
        mv /dev/shm/$alignMLF.$grid0Task.$$ $alignMLF.$grid0Task

        for n in `cut -d "=" -f 1 deal/$alignList.$grid0Task`
        do
            count=`grep -wc "\"${n}.lab\"" $alignMLF.$grid0Task`;
            if [ $count != "1" ]
            then
                echo "PROBLEM with ${n} on "`hostname`
            fi
        done
        ;;

    *)
        echo "Decoder $decoder cannot be used to align" >&2
        exit 1
        ;;
    esac
}

function Merge
{
    $hled -A -i $alignMLF /dev/null $alignMLF.{01..$nJobs}
    rm $alignMLF.{01..$nJobs}
    case $decoder in
    HVite_*)
        for n in $(cat split2merge.temp)
        do
            found=$n;
        done
        rm split2merge.temp
        if [ $found -eq 0 ]
        then
            rm -rf $featsDir/$featName
        fi
        ;;
    esac
}

# Grid
array=( $nJobs 1 )
source $(dirname $0)/grid.sh

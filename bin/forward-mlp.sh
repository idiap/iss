#!/bin/zsh
#
# Copyright 2011 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, August 2011
#   Marc Ferras, November 2011
#                (forward pass parallelization, tandem feature computation,
#                 klt transform training and htk file generation)
#
this=$0
source $(dirname $0)/config.sh

autoload dealc.sh
autoload create-mlp-file-list.sh

function Split
{
    create-mlp-file-list.sh $fileList file-list.txt
    mkdir -p deal
    dealc.sh file-list.txt deal/file-list.txt.{01..$nJobs}
}


function Array
{
    case $mlpWeightFormat in 
    matlab )
        mlpSizeName=`basename $mlpWeightFile | sed -e "s/\.mat//g" `
        ;;
    rap3 )
        mlpSizeName=`basename $mlpWeightFile | sed -e "s/\.txt//g" `
        ;;
    *)
        echo "Unknown weight format ($mlpWeightFormat)"
        exit 1
        ;;
    esac
    activationFile=$activationID-$mlpSizeName.pfile

    # Run the extraction
    echo Running forward pass
    # The first pipeline creates the directories.
    cat deal/file-list.txt.$grid0Task | cut -d' ' -f2  | xargs -n 1 dirname | sort -u | xargs -n 1 mkdir -p

    ftrFile=$featsDir/$featName/$featForward
    echo "Running forward pass on ${ftrFile}.$grid0Task..."
    $feacat -ip htk -l deal/file-list.txt.$grid0Task -o ${ftrFile}.$grid0Task >&3
    minFrames=`$pfile_info -p -q ${ftrFile}.$grid0Task | awk '{printf("%020d\n",$2)}' | sort -u | head -n 1 | awk '{printf("%d\n",$0)}'`

    if [ ${minFrames} -lt ${windowExt} ]
    then
        echo "ERROR: Minimal number of frames (${minFrames}) less than window length (${windowExt})."
        exit
    else
        echo "Minimal number of frames: ${minFrames}"
    fi

    case $mlpWeightFormat in 
    matlab )
        mlpSize=`basename $mlpWeightFile | sed -e "s/\.mat//g" | tr 'x' ','`
        ;;
    rap3 )
        mlpSize=`basename $mlpWeightFile | sed -e "s/\.txt//g" | tr '_' ','`
        ;;
    *)
        echo "Unknown weight format ($mlpWeightFormat)"
        exit 1
        ;;
    esac

    logFile="$logDir/forwardMLP.log"

    opts=(
        ftr1_file=$ftrFile.$grid0Task
        ftr1_ftr_start=0
        ftr1_ftr_count=$featDimension
        ftr1_window_len=$windowExt
        ftr1_window_offset=$featOffset
        ftr1_norm_mode=$normMode
        ftr1_norm_file=$normFile
        window_extent=$windowExt
        mlp_size=$mlpSize
        mlp_output_type=$outputType
        mlp_bunch_size=$bunchSize
        verbose=true
        init_weight_file=$mlpWeightFile
        init_weight_format=$mlpWeightFormat
        activation_file=$activationFile.$grid0Task
        activation_format=$activationFormat
        log_file=$logFile.$grid0Task
        ftr1_delta_order=$deltaOrder
        ftr1_delta_win=$deltaWin
    )
    $qnmultifwd $opts
    rm -f $ftrFile.$grid0Task
}

function Merge
{
    case $mlpWeightFormat in 
    matlab )
        mlpSizeName=`basename $mlpWeightFile | sed -e "s/\.mat//g" `
        ;;
    rap3 )
        mlpSizeName=`basename $mlpWeightFile | sed -e "s/\.txt//g" `
        ;;
    *)
        echo "Unknown weight format ($mlpWeightFormat)"
        exit 1
        ;;
    esac
    activationFile=$activationID-$mlpSizeName.pfile
    echo "Joining job output"
    $pfile_concat -o $activationFile ${activationFile}.{01..$nJobs}
    rm -f ${activationFile}.{01..$nJobs}
}

if [ -z $mlpWeightFile ]
then
    echo "weight file $mlpWeightFile not found"
    exit                
fi

# Just to make sure feacat does not crash when the output is redirected
exec 3>`tty`

# Grid
array=( $nJobs 1 )
source $(dirname $0)/grid.sh

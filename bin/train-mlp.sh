#!/bin/zsh
#
# Copyright 2010 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#

#
# Train MultiLayer Perceptron Training
#
# David Imseng
# Marc Ferras, November 2011
#              (5-layer MLP, allow multiple train-mlp.sh in parallel)
#
this=$0

function usage
cat <<EOF
This is $0
EOF

source $(dirname $0)/config.sh
source $(dirname $0)/grid.sh

# offset due to the window span
hardTargetWindowOffset=`echo "($windowExt-1)/2" | bc`

# Estimate the number of parameters as the 10% of the number of training frames
if  [ $nParams -lt 0 ]
then
    nFrames=`$pfile_info $targetTRN | grep frames | cut -d , -f 2 | cut -d " " -f 2`
    nParams=`echo "$nFrames/$nParamsPart" | bc`
    echo "$nParams parameters used in the neural net"
fi

# compute MLP input size
if [[ ! -z $featTRN2 ]] && [[ ! -z $featDEV2 ]]
then
    mlpInputSize=`echo "$windowExt*$featDimension+$windowExt2*$featDimension2" | bc`   
else
    mlpInputSize=`echo "$windowExt*$featDimension" | bc`
fi

# compute output dimension
if [ $outputDim -lt 0 ]
then
    mlpOutputSize=`$pfile_print -q -ns -i $targetTRN | sort -u | wc -l`
else
    mlpOutputSize=$outputDim
fi


case $mlpNLayers in
'2')
    mlpSize=$mlpInputSize,$mlpOutputSize
    outWeightFile=${mlpInputSize}x${mlpOutputSize}.mat
    suffix=${mlpInputSize}x${mlpOutputSize}
    ;;
'3')
    if [[ -z $mlpHiddenSize ]]
    then
        # compute size of hidden layer
        # for 3 layers: P = (1+I)*H + (H+1)*O  => H=(P-O)/(1+I+O)
        mlpHiddenSize=`echo "($nParams-$mlpOutputSize)/(1+$mlpInputSize+$mlpOutputSize)" | bc`
        mlpSize=$mlpInputSize,$mlpHiddenSize,$mlpOutputSize
        outWeightFile=${mlpInputSize}x${mlpHiddenSize}x${mlpOutputSize}.mat
        suffix=${mlpInputSize}x${mlpHiddenSize}x${mlpOutputSize}
    fi
    ;;
'5')
    if [[ $mlpNLayers == 5 ]]
    then
        if [[ -z $mlpHiddenSize ]]
        then
        # compute size for layers H1 and H3, assuming H1=H3 and known H2=$mlpBnSize
        # (i+1)*h + (h+1)*h2 + (h2+1)*h + (h+1)* o = p  => h = (p-o-h2)/(i+o+2*h2+2)
            mlpHiddenSize=`echo "($nParams-$mlpOutputSize-$mlpBnSize)/($mlpInputSize+$mlpOutputSize+2*$mlpBnSize+2)" | bc`
        fi
        mlpSize=$mlpInputSize,$mlpHiddenSize,$mlpBnSize,$mlpHiddenSize,$mlpOutputSize
        outWeightFile=${mlpInputSize}x${mlpHiddenSize}x${mlpBnSize}x${mlpHiddenSize}x${mlpOutputSize}.mat
        suffix=${mlpInputSize}x${mlpHiddenSize}x${mlpBnSize}x${mlpHiddenSize}x${mlpOutputSize}
    fi
    ;;
esac

# Add suffix to features to allow different train runs at the same
# time (using different files) this suffix is also used by
# init-mlp.sh when creating the training and dev data files
featTRN=`echo "$featTRN-$suffix"`
featDEV=`echo "$featDEV-$suffix"`

# Create hard targets
hardTargetFile=target.pfile
$pfile_concat -q -o $hardTargetFile $targetTRN $targetDEV
ftrFile=$featsDir/$featName/$featTRN,$featsDir/$featName/$featDEV
if [[ ! -z $featTRN2 ]] && [[ ! -z $featDEV2 ]]
then
    ftrFile2=$featsDir/$featName/$featTRN2,$featsDir/$featName/$featDEV2
else
    ftrFile2=""
fi

# Get number of sentences for train and dev sets
nTrnSent=`$pfile_info -i $featsDir/$featName/$featTRN | grep sentences | cut -d , -f 1 | cut -d " " -f 1`
nDevSent=`$pfile_info -i $featsDir/$featName/$featDEV | grep sentences | cut -d , -f 1 | cut -d " " -f 1`

# start and end train/dev sentences, train/dev ranges
trnBegin=0
let trnEnd=$nTrnSent-1
devBegin=$nTrnSent
let devEnd=$trnEnd+$nDevSent
trainRange="$trnBegin:$trnEnd"
cvRange="$devBegin:$devEnd"

logWeightFile="%e.wts"
logFile="$logDir/trainMLP.log"

opts=(
    ftr1_file=$ftrFile
    ftr2_file=$ftrFile2
    hardtarget_file=$hardTargetFile
    hardtarget_format=pfile
    ftr1_ftr_count=$featDimension
    ftr2_ftr_count=$featDimension2
    hardtarget_lastlab_reject=true
    hardtarget_window_offset=$hardTargetWindowOffset
    ftr2_window_offset=$featOffset2
    ftr1_norm_file=$normFile
    ftr2_norm_file=$normFile2
    window_extent=$windowExt
    ftr1_window_offset=$featOffset
    ftr1_window_len=$windowExt
    ftr2_window_len=$windowExt2
    train_sent_range=$trainRange
    cv_sent_range=$cvRange
    train_cache_frames=$trnCacheFrame
    log_weight_file=$logWeightFile
    out_weight_file=$outWeightFile
    learnrate_schedule=$learnRateSchedule
    learnrate_vals=$learnRateVals
    learnrate_scale=$learnRateScale
    mlp_size=$mlpSize
    mlp_lrmultiplier=$mlpLRMultiplier
    mlp_output_type=softmax
    mlp_bunch_size=$bunchSize
    mlp_threads=$threads
    verbose=true
    ftr1_norm_mode=$normMode
    ftr2_norm_mode=$normMode2
    ftr1_delta_order=$deltaOrder
    ftr2_delta_order=$deltaOrder2
    ftr1_delta_win=$deltaWin
    ftr2_delta_win=$deltaWin2
    log_file=$logFile
)

# use pre-initialized weights if present
if [ ! -z $initWeightFile ]
then
    opts+="init_weight_file=$initWeightFile"
fi

if [ ! -z $initRandomBiasMin ]
then
    opts+="init_random_bias_min=$initRandomBiasMin"
fi
if [ ! -z $initRandomBiasMax ]
then
    opts+="init_random_bias_max=$initRandomBiasMax"
fi
if [ ! -z $initRandomWeightMin ]
then
    opts+="init_random_weight_min=$initRandomWeightMin"
fi
if [ ! -z $initRandomWeightMax ]
then
    opts+="init_random_weight_max=$initRandomWeightMax"
fi

$qnmultitrn $opts

rm $hardTargetFile
rm *.wts

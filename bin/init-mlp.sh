#!/bin/zsh
#
# Copyright 2010 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#

#
# Initialise MultiLayer Perceptron Training
#
# David Imseng, November 2010
# Marc Ferras, November 2011 (added mlpSize as suffix to train and dev pfiles)
#
this=$0

function usage
cat <<EOF
This is $0
\$PHONESET [$phoneSet]: The name of the phoneset to be used.
(Needs to be defined in \$PHONESET_CSV [$phoneSetCSV])
\$SAMPA_MAP: The mapping of some \$PHONESET_CSV entries to
computer (htk) readable characters. Different mappings should be
separated by "," and the values with "/" (i.e. 2/_2_,9/_9_)
EOF

source $(dirname $0)/config.sh
source $(dirname $0)/grid.sh

autoload create-phone-list.sh
autoload create-mlp-file-list.sh

# Create phonelist (no sp, just sil)
echo Writing PhoneList
if [ ! -e $trainLabels ]
then
    create-phone-list.sh $trainLabels
fi

# generate random file of any size (100k here) as seed
if [[ ! -f $seed ]]
then
    dd if=/dev/urandom of=$seed bs=100k count=1
fi

echo Creating training and development list
create-mlp-file-list.sh $trnList trn-list-htk.txt
shuf --random-source=$seed trn-list-htk.txt > trn-list-htk-shuf.txt
mv trn-list-htk-shuf.txt trn-list-htk.txt
create-mlp-file-list.sh $devList dev-list-htk.txt
shuf --random-source=$seed dev-list-htk.txt > dev-list-htk-shuf.txt
mv dev-list-htk-shuf.txt dev-list-htk.txt

# shuffle train and dev file lists
inListColumns=$(tail -n 1 $trnList | wc -w)
case $inListColumns in
'1')
    # Use the full HTK filename
    echo Single column format: s/.htk//
    sed 's/\.htk$//' < trn-list-htk.txt > trn-list-shuf.txt
    sed 's/\.htk$//' < dev-list-htk.txt > dev-list-shuf.txt
    ;;
'2')
    # Use the ID; that's what's in the MLF
    echo Double column format: picking IDs
    cut -d " " -f 1 $trnList | shuf --random-source=$seed > trn-list-shuf.txt
    cut -d " " -f 1 $devList | shuf --random-source=$seed > dev-list-shuf.txt
    ;;
*)
    echo "Don't know how to handle $inListColumns column file lists"
    exit 1
    ;;
esac

# creating hard target for train and development set
echo Creating target pfiles...
mlf-to-pfile-tri.pl $trnMLF $trainLabels trn-list-shuf.txt $targetTRN
echo TRN done...
mlf-to-pfile-tri.pl $devMLF $trainLabels dev-list-shuf.txt $targetDEV
echo DEV done.


# compute the mlpSize to use as suffix for the training and dev files
# offset due to the window span
hardTargetWindowOffset=`echo "($windowExt-1)/2" | bc`

# Estimate the number of parameters as the 10% of the number of
# training frames
if  [ $nParams -lt 0 ]
then
    nFrames=`$pfile_info $targetTRN | grep frames | cut -d , -f 2 | cut -d " " -f 2`
    nParams=`echo "$nFrames/$nParamsPart" | bc`
    echo "$nParams ($nFrames/$nParamsPart) parameters used in the neural net"
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
'3')
    if [[ -z $mlpHiddenSize ]]
    then
        # compute size of hidden layer
        # for 3 layers: P = (1+I)*H + (H+1)*O  => H=(P-O)/(1+I+O)
        mlpHiddenSize=`echo "($nParams-$mlpOutputSize)/(1+$mlpInputSize+$mlpOutputSize)" | bc`
        mlpSize=$mlpInputSize,$mlpHiddenSize,$mlpOutputSize
        suffix=${mlpInputSize}x${mlpHiddenSize}x${mlpOutputSize}
    fi
    ;;
'5')
    if [[ $mlpNLayers == 5 ]]
    then
        if [[ -z $mlpHiddenSize ]]
        then
            # compute size for layers H1 and H3, assuming H1=H3 and
            # known H2=$mlpBnSize (i+1)*h + (h+1)*h2 + (h2+1)*h +
            # (h+1)* o = p => h = (p-o-h2)/(i+o+2*h2+2)
            mlpHiddenSize=`echo "($nParams-$mlpOutputSize-$mlpBnSize)/($mlpInputSize+$mlpOutputSize+2*$mlpBnSize+2)" | bc`
        fi
        mlpSize=$mlpInputSize,$mlpHiddenSize,$mlpBnSize,$mlpHiddenSize,$mlpOutputSize
        suffix=${mlpInputSize}x${mlpHiddenSize}x${mlpBnSize}x${mlpHiddenSize}x${mlpOutputSize}
    fi
    ;;
esac

echo Creating feature pfiles...
$feacat -ip htk -l trn-list-htk.txt -o $featsDir/$featName/$featTRN-$suffix -dt pfile -dl $targetTRN 
echo -n TRN done...
$feacat -ip htk -l dev-list-htk.txt -o $featsDir/$featName/$featDEV-$suffix -dt pfile -dl $targetDEV
echo DEV done.

#!/bin/zsh
#
# Copyright 2013 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Marc Ferras, November 2011
#   Phil Garner, July 2013
#
this=$0
source $(dirname $0)/config.sh
source $(dirname $0)/grid.sh

# Just to make sure feacat does not crash when the output is redirected
exec 3>`tty`

# apply klt on training data
# apply feature dimension reduction
#  need mlpOutputSize first
mlpOutputSize=`wc -l $mlpTandemStats | cut -d' ' -f1`

# eigenvalues: last column in $mlpTandemStats
((eigenpos=$mlpOutputSize*2+2))
eigenvalues=()
eigenvalues=("${(@f)$(cat $mlpTandemStats | cut -d' ' -f $eigenpos)}");

# Compute cumulative "energy"
g=0
for i in {1..$mlpOutputSize}
do
    ((g=$g+$eigenvalues[$i]))
done
h=0
i=1
while (( $h/$g < $pcaThreshold ))
do
    ((h=$h+$eigenvalues[$i]))
    ((i=$i+1))
done
((i=$i-2))
echo "Feature dimensionality after reduction: 0:$i"
echo "PCA threshold: $pcaThreshold"


echo "Generating tandem features"
mlpSizeName=$mlpWeightFile:t:r
activationFile=$activationID-$mlpSizeName.pfile
activationFileLog=$activationID-$mlpSizeName-log.pfile
activationFileTandem=$activationID-$mlpSizeName-tandem.pfile

# These files may already exist from the KLT training stage
if [ ! -f $activationFileTandem ]
then
    if [ ! -f $activationFileLog ]
    then
        $feacat -i $activationFile -o $activationFileLog -tr safelog >&3
    fi

    echo "Generating tandem features"
    $pfile_klt -i $activationFileLog -o $activationFileTandem -a -is $mlpTandemStats -fr 0:$i
    rm -f $activationFileLog
fi
activationFile=$activationFileTandem

# generate htk files and list
if [ ! -z $mlpOutHtkDir ]
then
    if [[ -e $activationFile ]]
    then
        echo "Generating htk features from $activationFile"
        mkdir -p $featsDir/$featName/$mlpOutHtkDir

        create-mlp-file-list.sh $fileList file-list.txt

        htkFileList=file-list-htk.txt
        echo -n "" > $htkFileList
        utt=0
        for f in $(cat file-list.txt)
        do
            baseOut=`basename $f`
            baseOutNoExt=`echo $baseOut | sed -e 's/\..*//g'`
            spk=`echo $baseOut | cut -c1-3`
            mkdir -p $featsDir/$featName/$mlpOutHtkDir/$spk
            fileOut=$featsDir/$featName/$mlpOutHtkDir/$spk/$baseOut
            echo "$mlpOutHtkDir/$spk/$baseOutNoExt" >> $htkFileList
            echo "doing file $f (utt=$utt) from $activationFile $fileOut"
            $feacat -ip pfile -i $activationFile -op htk -o $fileOut -sr $utt-$utt >&3
            (( utt = utt + 1 ))
        done
    fi
fi

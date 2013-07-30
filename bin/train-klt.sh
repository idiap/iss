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

# train tandem (log + klt train)
# apply log
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
activationFileTandem=`echo $activationFile | sed "s/\.pfile/-tandem\.pfile/g"`
if [ ! -f $activationFileTandem ]
then
    activationFileLog=`echo $activationFile | sed "s/\.pfile/-log\.pfile/g"`
    if [ ! -f $activationFileLog ]
    then
        $feacat -i $activationFile -o $activationFileLog -tr safelog >&3
    fi

    # train klt
    if [ ! -f $mlpTandemStats ]
    then
        if [[ $mlpTandemTrainSent > 0 ]]
        then
            (( mlpTandemTrainLast = mlpTandemTrainSent -1 ))
            $pfile_klt -i $activationFileLog -a -os $mlpTandemStats -sr 0:$mlpTandemTrainLast
        else
            $pfile_klt -i $activationFileLog -a -os $mlpTandemStats
        fi
    fi
fi

#!/bin/zsh (not executable, just for editor mode)
#
# Copyright 2010 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Creates the phonelist based on a cvs phonesheet
#
# David Imseng, October 2010
#

# Check the usage
if [[ $# < 1 ]]
then
    echo "Usage: create-phone-list.sh phonelist"
    exit 1
fi


echo sil > $1
if [ ! -z $sampaMap ]
then
    $binDir/phone-list.py \
        -d $phoneSetCSV \
        -i $phoneSet \
        -l error \
        -m $sampaMap \
        >> $1
else
    $binDir/phone-list.py -d $phoneSetCSV -i $phoneSet -l error  >> $1
fi


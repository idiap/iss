#!/bin/zsh 
#
# Copyright 2010 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Creates the dictionary and checks if it uses the complete phonelist
# also given as argument
#
# David Imseng, October 2010
# Milos Cernak, September 2013
#

# Check the usage
if [[ $# < 3 ]]
then
    echo "Usage: create-dict.sh input flat main [phonelist]"
    exit 1
fi

this=$0
source $(dirname $0)/config.sh

autoload create-phone-list.sh

# Creating the Dict
if [ ! -z $sampaMap ]
then
    $binDir/convert-dict.py \
    -i ${1} \
    -m $sampaMap \
    -l 'error' \
    > ${2}.unsorted
else
    $binDir/convert-dict.py \
        -i ${1} \
        -l 'error' \
    	> ${2}.unsorted
fi

# Ensure the sorting
LC_ALL=C sort ${2}.unsorted > ${2}.raw
rm ${2}.unsorted


if [[ $# -eq "4" ]]
then 
    create-phone-list.sh ${4}
    $hdman -m -i -n ${4}.temp ${2} ${2}.raw
    for phon in $(cat ${4}.temp)
    do
        cnt=`grep -xc ${phon} ${4}`
        if [ $cnt -ne "1" ]
        then
    	    echo $phon" from dictionary is present "$cnt" times in "$2
            exit
        fi
    done

    for phon in $(cat ${4})
    do
        cnt=`grep -xc ${phon} ${4}.temp`
        if [ $cnt -ne "1" ]
        then
     	    echo $phon" from "${4}" is present "$cnt" times in the dictionay"
            exit
        fi
    done

    rm ${4}.temp
else
    $hdman -m -i ${2} ${2}.raw
fi

# Create dictionary to fix silence 
echo AS sp sil > global.ded
echo MP sil sil sp >> global.ded
echo MP sil sil sil >> global.ded
$hdman -m -i ${3} ${2}.raw

rm global.ded
rm ${2}.raw

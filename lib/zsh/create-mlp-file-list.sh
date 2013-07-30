#!/bin/zsh (for editor)
#
# Copyright 2012 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   David Imseng, February 2012
#   Marc Ferras, February 2012 
#
# Convert ISS style file list to Quicknet style 'script'
#
# The ISS ones are just whitespace separated lists where the number of
# columns vary depending on the function. Output always has one column.
#

if [[ $# < 2 ]]
then
    echo "Usage: $0 <input list> <output Quicknet list>"
    exit 1
fi
htkList=$2
inlist=$1

#
# This dispatch table should work for all quicknet related scripts.
#
echo Generating $htkList from $inlist
inListColumns=$(tail -n 1 $inlist | wc -w)
case $inListColumns in
'1')
    while read file 
    do
       	feats=$featsDir/$featName/$file.htk
	echo $feats
    done < $inlist > $htkList
    ;;
'2')
    while read ID file 
    do
       	feats=$featsDir/$featName/$file.htk
	echo $feats
    done < $inlist > $htkList
    ;;
*)
    echo "Don't know how to handle $inListColumns column file lists"
    exit 1
    ;;
esac

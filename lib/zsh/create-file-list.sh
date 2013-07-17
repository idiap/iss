#!/bin/zsh (for editor)
#
# Copyright 2011 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, March 2011
#

#
# Convert ISS style file list to HTK style 'script'
#
# The ISS ones are just whitespace separated lists where the number of
# columns vary depending on the function.
#
# Single column ISS corresponds to traditional HTK script.  Multiple
# column ISS gets convereted to HTK extended filename format, which is
# largely undocumented.
#
if [[ $# < 1 ]]
then
    echo "Usage: $0 <output HTK list>"
    exit 1
fi
htkList=$1

#
# This dispatch table should work for align, decode and train.
# Truncate and extract are different because they need two files in
# the list.
#
echo Generating $htkList from $fileList
case $fileListColumns in
'1')
	while read file 
	do
       	feats=$featsDir/$featName/$file.htk
		echo $feats >> $htkList
	done < $fileList
    ;;
'2')
	while read ID file 
	do
       	feats=$ID"="$featsDir/$featName/$file.htk
		echo $feats >> $htkList
	done < $fileList
    ;;
'4')
	while read ID file begin end
	do
       	feats=$ID"="$featsDir/$featName/$file.htk[$begin,$end]
		echo $feats >> $htkList
	done < $fileList
	;;
*)
    echo "Don't know how to handle $fileListColumns column file lists"
    exit 1
    ;;
esac

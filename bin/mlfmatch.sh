#!/bin/zsh
#
# Copyright 2010 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#

#
# Output transcripts for a list of files
#
# Marc Ferras, November 2011
#

function usage
cat <<EOF
mlfmatch wordmlf filelist  -  outputs transcriptions for the file sin filelist
EOF

# generate comma-separated list of segment ids to match
blockSize=100
nBlock=0
idlist=""
echo "#!MLF!#"
for file in $(cat $2)
do
    bfile=`basename $file`
    if [[ $nBlock == 0 ]]
    then
        idlist=$bfile
    else
        idlist="$idlist,$bfile"
    fi
    (( nBlock=nBlock+1 ))
    if [[ $nBlock == $blockSize ]]
    then
        nBlock=0
        # process block of ids
        awk -v id=$idlist '{gsub(/,/,"|",id) ; if ($0 ~ id) b=1 ; if (b==1 && $0==".") {b=0; print} ; if (b) print}' $1
        idlist=""
    fi
# awk -v id=$bfile '{if ($0 ~ id) b=1 ; if (b==1 && $0==".") {b=0; print ; exit} ; if (b) print}' $1
done

# process last block of ids
if [[ $idlist != "" ]]
then
    awk -v id=$idlist '{gsub(/,/,"|",id) ; if ($0 ~ id) b=1 ; if (b==1 && $0==".") {b=0; print} ; if (b) print}' $1
fi

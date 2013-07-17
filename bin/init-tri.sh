#!/bin/zsh
#
# Copyright 2011 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, February 2011
#

#
# Initialise triphone models from monophone ones
# (Was part of cd-init.sh)
#
this=$0

function usage
cat << EOF
needs:
$ciModelDir and content
creats:
$cdModelDir and all content
EOF

source $(dirname $0)/config.sh
source $(dirname $0)/grid.sh

function triLed
cat <<EOF
NB $spModel
WB $spModel
TC
IT
RE $silModel $silModel
EOF

# Convert the aligned ci labels into cd labels and generate a triphone list
echo Convert ci labels to cd labels and generate triphone list
mkdir -p $cdModelDir
triLed > $cdModelDir/tri.led
opts=(
    -n $cdModelDir/hmm-list.txt
    -i $cdMLF
)
[[ $fileListColumns == 1 ]] && opts+=( -l '*' )
$hled $htsOptions $opts $cdModelDir/tri.led $ciMLF

# Duplicate ci models to make cd models
echo Duplicate ci models to cd models
duphed=$cdModelDir/dup.hed
echo CL $cdModelDir/hmm-list.txt > $duphed
for m in $(cat $ciModelDir/hmm-list.txt | grep -v $silModel | grep -v $spModel)
do
    echo TI T_$m {\*-$m+\*.TRANSP} >> $duphed
done
opts=(
    -H $ciModelDir/mmf.txt
    -M $cdModelDir
)
$hhed $htsOptions $opts $duphed $ciModelDir/hmm-list.txt

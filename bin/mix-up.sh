#!/bin/zsh
#
# Copyright 2011 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, September 2011
#

#
# Increase the order of the Gaussian mixtures
#
this=$0

function usage
cat << EOF
needs:
$mixModelDir monogaussian content at least

creates:
$mixModelDir new models

EOF

autoload reestimate.sh
source $(dirname $0)/config.sh

function mixHed
cat <<EOF
MU $mixOrder {*.state[2].mix}
MU $mixOrder {*.state[3].mix}
MU $mixOrder {*.state[4].mix}
EOF

function Split
{
    echo Mixing up to order $mixOrder in $mixModelDir

    # Find the previous highest order MMF
    oldMMF=$mixModelDir/mmf.txt
    for i in {$mixOrder..1}
    do
        mmf=$mixModelDir/mmf-$i.bin
        if [[ -f $mmf ]] && [[ $mmf -nt $oldMMF ]] 
        then
            oldMMF=$mmf
            break
        fi
    done

    # Where to write
    mmf=$mixModelDir/mmf-$mixOrder.bin
    echo Creating $mmf from $oldMMF
    # BP: hack to solve issue on lustre storage
    cat $oldMMF > $mmf
    oldMMF=$mmf

    # Generate hed and do mixup
    mixhed=$mixModelDir/mix-up.hed
    mixHed > $mixhed
    $hhed $htsOptions -B -H $mmf -M $mixModelDir \
        $mixhed $mixModelDir/hmm-list.txt
}

# Grid
# grid.sh will run Split, then drop through; then reestimate will be run
nIter=5
array=( $nJobs $nIter )
source $(dirname $0)/grid.sh

reestimate.sh $mixModelDir $mixMLF $trainList

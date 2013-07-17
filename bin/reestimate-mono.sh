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
# Re-estimate monophone models
#
this=$0

function usage
cat <<EOF
This is $0
Given a monophone model directory \$ciModelDir, reestimates the model
against MMF file \$ciMMF and file list $trainList.
EOF

autoload reestimate.sh
source $(dirname $0)/config.sh

# Grid
nIter=5
array=( $nJobs $nIter )
source $(dirname $0)/grid.sh

reestimate.sh $ciModelDir $ciMLF $trainList

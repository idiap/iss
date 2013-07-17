#!/bin/zsh
#
# Copyright 2010 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, October 2010
#

#
# Re-estimate triphone models.
#
this=$0

function usage
cat <<EOF
This is $0
Given a triphone model directory \$cdModelDir, reestimates the model
against MMF file \$cdMMF and file list $trainList.
EOF

autoload reestimate.sh
source $(dirname $0)/config.sh

# Grid
nIter=5
array=( $nJobs $nIter )
source $(dirname $0)/grid.sh

reestimate.sh $cdModelDir $cdMLF $trainList

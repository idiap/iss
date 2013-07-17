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
# Floor variances
#
this=$0

function usage
cat <<EOF
This is $0
needs:
$fileList [ID file]
$featsDir
$featName
$targetKind
$featDimension
creates:
$htsConfig
$trainList (if not existing)
$protoMMF
vFloor
EOF


source $(dirname $0)/config.sh
source $(dirname $0)/grid.sh

autoload prototype.sh
autoload create-file-list.sh

# Build a file list
[[ ! -e $trainList ]] && create-file-list.sh $trainList

# Create a config
# Other possibilities are:
#
#  VFLOORSCALESTR    = "Vector 1 0.01"
#  ...which is a more versatile form of HCompV -f 0.01 
#
cat <<EOF > $htsConfig
APPLYVFLOOR   = T
MINLEAFOCC    = 0
MAXSTDDEVCOEF = 10
TARGETKIND    = $targetKind
EOF

# Create a prototype
prototype.sh $targetKind 5 $featDimension > $protoMMF

# Run HCompV in variance flooring mode
opts=(
    -C $htsConfig
    -f $varFloor
    -m
    -S $trainList
)
$hcompv $htsOptions $opts $protoMMF

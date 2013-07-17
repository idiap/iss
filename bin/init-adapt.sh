#!/bin/zsh
#
# Copyright 2011 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, August 2011
#
this=$0
source $(dirname $0)/config.sh
source $(dirname $0)/grid.sh

autoload create-file-list.sh

#
# Initialise model adaptation
#

# This contains commands to both expand the words into phones using
# the dictionary, then expand phones into triphones.
function triLed
cat <<EOF
IS $sentBegin $sentEnd
EX
NB $spModel
WB $spModel
TC
IT
RE $silModel $silModel
EOF

# Build a file list
[[ ! -e $adaptList ]] && create-file-list.sh $adaptList

# Create a tri-phone MLF for supervised adaptation
led=adapt-tri.led
triLed > $led
opts=(
    -d $flatDict
    -i $adaptMLF
)
[[ $fileListColumns == 1 ]] && opts+=( -l '*' )
$hled $htsOptions $opts $led $wordMLF

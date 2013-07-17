#!/bin/zsh (for editor)
#
# Copyright 2011 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, February 2011
#   David Imseng, February 2011
#

#
# Create HVite config file
#
cat <<EOF
TARGETKIND   = $targetKind
ALLOWCXTEXP  = T
ALLOWXWRDEXP = T
FORCECXTEXP  = T
FORCEOUT     = T
EOF

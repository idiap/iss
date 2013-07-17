#!/bin/zsh
#
# Copyright 2010 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, February 2011
#

#
# Score transcriptions
#
this=$0

function usage
cat <<EOF
This is $0
\$DECODE_DICT: dictionary that contains all the words that are used
               (no transcription needed)
\$SCORE_REFERENCE: reference to perform the scoring
\$DECODE_MLF: system output 
EOF

source $(dirname $0)/config.sh
source $(dirname $0)/grid.sh

#
# This just calls HResults.  There is also NIST stuff...
#
# HDecode and HVite can be made to suppress the start and end tokens.
# juicer can't (I think).  In any case, the -e lines sort it out.
#
# Leave the options simple here; you can always say:
#  HTS_OPTIONS='-f' Score.sh dir
# on the command line, or set HTS_OPTIONS in Score.sh
#
opts=(
    $htsOptions
    -z $silModel
    -e $silModel $sentBegin
    -e $silModel $sentEnd
    -I $scoreReference
)
$hresults $opts $flatDict $decodeMLF

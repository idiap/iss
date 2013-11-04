#!/bin/zsh
#
# Copyright 2013 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, October 2013
#

#
# Calculates the number of bark bands corresponding to a given
# sampling rate.  It uses the same calculation that Junichi does in
# the legacy STRAIGHT code.
#
if [[ $# < 1 ]]
then
    echo "Usage: bark-bands.sh <rate>"
    exit 1
fi

zmodload zsh/mathfunc

sampRate=$1
nyq=$((sampRate / 2.0))
fbark=$((26.81 * nyq / (1960.0 + nyq ) - 0.53))

if ((fbark < 2.0))
then
    fbark=$(( fbark + 0.15*(2.0-fbark) ))
fi

if ((fbark > 20.1))
then
    fbark=$(( fbark + 0.22*(fbark-20.1) ))
fi

echo $(( int(fbark + 0.5) ))

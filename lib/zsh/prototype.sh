#!/bin/zsh (for editor)
#
# Copyright 2010 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#

#
# Create a prototype MMF
# Phil Garner, October 2010
#
if [[ $# < 3 ]]
then
    echo "Usage: prototype.sh <targetKind> <nStates> <nDimensions>"
    exit 1
fi

local targetKind=$1
local nStates=$2
local featDimension=$3

#
# One header
#
cat <<EOF
~o
<VecSize> $featDimension <$targetKind>
<MSDINFO> 1 0
<StreamInfo> 1 $featDimension
<BeginHMM>
<NumStates> $nStates
EOF

#
# One mean and variance per state, excluding the first and last.  Uses
# a very small variance so that state tying will favour the already
# trained state when this is actually used as a variance.
#
for s in {2..$((nStates-1))}
do
cat <<EOF
<State> $s
<SWeights> 1 1.0
<Stream> 1
EOF
echo "<Mean>" $featDimension
for i in {1..$featDimension}
do
    echo -n " 0.0"
done
echo
echo "<Variance>" $featDimension
for i in {1..$featDimension}
do
    echo -n " 0.001"
done
echo
done

#
# The transition matrix is a little tricky.  We aim for something
# like this:
#
# <TransP> 5
#  0.000e+0 1.000e+0 0.000e+0 0.000e+0 0.000e+0
#  0.000e+0 6.000e-1 4.000e-1 0.000e+0 0.000e+0
#  0.000e+0 0.000e+0 6.000e-1 4.000e-1 0.000e+0
#  0.000e+0 0.000e+0 0.000e+0 6.000e-1 4.000e-1
#  0.000e+0 0.000e+0 0.000e+0 0.000e+0 0.000e+0
# <EndHMM>
#
echo "<TransP> $nStates"
for r in {1..$nStates}
do
    for c in {1..$nStates}
    do
        case $r-$c in
        *-1)
            echo -n " 0.0e+0"
            ;;
        $nStates-*)
            echo -n " 0.0e+0"
            ;;
        1-2)
            echo -n " 1.0e+0"
            ;;
        $r-$r)
            echo -n " 6.0e-1"
            ;;
        $r-$((r+1)))
            echo -n " 4.0e-1"
            ;;
        *)
            echo -n " 0.0e+0"
            ;;
        esac
    done
    echo
done
echo "<EndHMM>"

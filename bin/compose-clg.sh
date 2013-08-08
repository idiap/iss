#!/bin/zsh
#
# Copyright 2011 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, February 2011
#
this=$0
source $(dirname $0)/config.sh
source $(dirname $0)/grid.sh

#
# Compose CLG WFST from LG WFST and acoustic model
# ...based on earlier scripts by Darren, John and me.
#
echo Working in $clgDir using toolkit $wfst
mkdir -p $clgDir

echo cdgen
opts=(
    -monoListFName $wfstModelDir/mono-list.txt
    -silMonophone $silModel
    -pauseMonophone $spModel
    -tiedListFName $wfstModelDir/hmm-list.txt
    -htkModelsFName $wfstModelDir/mmf.txt
    -cdSepChars -+
    -cdType xwrdtri
    -fsmFName $clgDir/C.fsm
    -inSymsFName $clgDir/C.insyms
    -outSymsFName $clgDir/C.outsyms
    -lexInSymsFName $wfstLexInSyms
)
$cdgen $opts

# Prepare the context dependency transducer
case $wfst in
att)
    fsmcompile -t -s log -f const_input_indexed $clgDir/C.fsm | \
        fsmconnect | \
        fsminvert | \
        fsmdeterminize | \
        fsmencode -l - $clgDir/key.bfsm | \
        fsmminimize | \
        fsmencode -dl - $clgDir/key.bfsm | \
        fsminvert > $clgDir/C.bfsm
    echo -n "$clgDir/C.bfsm: "
    echo $(fsminfo -n $clgDir/C.bfsm | grep "of arcs")
    ;;
openfst)
    fstcompile --arc_type=log --fst_type=const $clgDir/C.fsm | \
        fstarcsort | \
        fstconnect | \
        fstinvert | \
        fstdeterminize | \
        fstencode --encode_labels - $clgDir/key.bfsm | \
        fstminimize - | \
        fstencode --decode - $clgDir/key.bfsm | \
        fstinvert > $clgDir/C.bfsm
    echo -n "$clgDir/C.bfsm: "
    echo $(fstinfo $clgDir/C.bfsm | grep "of arcs")
    ;;
esac
rm -f $clgDir/key.bfsm

# Compose CLG
if [[ "$wfstOptFinal" == 0 ]]
then
    # No final optimistaion; just compose
    case $wfst in
    att)
        fsmcompose -s $clgDir/C.bfsm $wfstLG | \
            fsmpush $pushOpts -i > $clgDir/CLG.bfsm
        ;;
    openfst)
        fstcompose $clgDir/C.bfsm $wfstLG | \
            fstpush --push_weights > $clgDir/CLG.bfsm
        ;;
    esac
else
    # Compose and optimise
    case $wfst in
    att)
        fsmcompose -s $clgDir/C.bfsm $wfstLG | \
            fsmepsnormalize | \
            fsmdeterminize | \
            fsmencode -l - $clgDir/key.bfsm | \
            fsmminimize | \
            fsmencode -dl - $clgDir/key.bfsm | \
            fsmpush $pushOpts -i > $clgDir/CLG.bfsm
        ;;
    openfst)
        fstcompose $clgDir/C.bfsm $wfstLG | \
            fstepsnormalize | \
            fstdeterminize | \
            fstencode --encode_labels - $clgDir/key.bfsm | \
            fstminimize - | \
            fstencode --decode - $clgDir/key.bfsm | \
            fstpush --push_weights > $clgDir/CLG.bfsm
        ;;
    esac
    rm -f $clgDir/key.bfsm
fi

# Report the final size of CLG and print
case $wfst in
att)
    echo -n "$clgDir/CLG.bfsm: "
    echo $(fsminfo -n $clgDir/CLG.bfsm | grep "of arcs")
    fsmprint $clgDir/CLG.bfsm > $clgDir/CLG.fsm
    ;;
openfst)
    echo -n "$clgDir/CLG.bfsm: "
    echo $(fstinfo $clgDir/CLG.bfsm | grep "of arcs")
    fstprint $clgDir/CLG.bfsm > $clgDir/CLG.fsm
    ;;
esac

# Copy the symbols files
cp $clgDir/C.insyms $clgDir/CLG.insyms
cp $wfstGramOutSyms $clgDir/CLG.outsyms
echo done

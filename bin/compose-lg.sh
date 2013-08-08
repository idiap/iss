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
# Compose LG WFST
# ...based on earlier scripts by Darren, John and me.
#
echo Working in $lgDir using toolkit $wfst
mkdir -p $lgDir

function createWordList
{
    words=$1
    echo $sentBegin > $words
    echo $sentEnd >> $words
    cat $wfstWords >> $words
}

if [[ ! -e $wfstDict ]]
then
    echo Building $wfstDict
    createWordList $lgDir/wfst-words.txt
    $binDir/dict-man.rb $mainDict -w $lgDir/wfst-words.txt -o $wfstDict -b
fi

if [[ $wfstNormLM == 1 ]]
then
    echo Building $lgDir/wfst-lm.txt
    createWordList $lgDir/wfst-words.txt
    opts=(
        -f TEXT
        -w $lgDir/wfst-words.txt
    )
    $lnorm $htsOptions $opts $wfstLM $lgDir/wfst-lm.txt
    wfstLM=$lgDir/wfst-lm.txt
fi

echo gramgen
opts=(
    -lexFName $wfstDict
    -sentStartWord $sentBegin
    -sentEndWord $sentEnd
    -lmFName $wfstLM
    -gramType ngram
    -fsmFName $lgDir/G.fsm
    -inSymsFName $lgDir/G.insyms
    -outSymsFName $lgDir/G.outsyms
    -phiBackoff
    -lmScaleFactor $wfstLMScale
    -wordInsPen $wfstWordPenalty
    -unkWord $unknownWord
)
$gramgen $opts

echo lexgen
opts=(
    -lexFName $wfstDict
    -sentStartWord $sentBegin
    -sentEndWord $sentEnd
    -monoListFName $wfstModelDir/mono-list.txt
    -silMonophone $silModel
    -pauseMonophone $spModel
    -fsmFName $lgDir/L.fsm
    -inSymsFName $lgDir/L.insyms
    -outSymsFName $lgDir/L.outsyms
    -outputAuxPhones
    -addPhiLoop
)
#    -addPronunsWithEndSil
#    -addPronunsWithEndPause
$lexgen $opts

# Prepare the grammar transducer
case $wfst in
att)
    fsmcompile -t -s log -f const_input_indexed $lgDir/G.fsm | \
        fsmdeterminize > $lgDir/G.bfsm
    echo -n "$lgDir/G.bfsm: "
    echo $(fsminfo -n $lgDir/G.bfsm | grep "of arcs")
    ;;
openfst)
    fstcompile --arc_type=log --fst_type=const $lgDir/G.fsm | \
        fstarcsort | \
        fstdeterminize > $lgDir/G.bfsm
    echo -n "$lgDir/G.bfsm: "
    echo $(fstinfo $lgDir/G.bfsm | grep "of arcs")
    ;;
esac

# Prepare the lexicon transducer
case $wfst in
att)
    fsmcompile -t -s log -f const_input_indexed $lgDir/L.fsm | \
        fsmclosure > $lgDir/L.bfsm
    echo -n "$lgDir/L.bfsm: "
    echo $(fsminfo -n $lgDir/L.bfsm | grep "of arcs")
    ;;
openfst)
    fstcompile --arc_type=log --fst_type=const $lgDir/L.fsm | \
        fstarcsort | \
        fstclosure > $lgDir/L.bfsm
    echo -n "$lgDir/L.bfsm: "
    echo $(fstinfo $lgDir/L.bfsm | grep "of arcs")
    ;;
esac

# Compose LG
echo Composing LG transducer LG.bfsm
rm -f $lgDir/key.bfsm
case $wfst in
att)
    fsmcompose $lgDir/L.bfsm $lgDir/G.bfsm | \
        fsmepsnormalize | \
        fsmdeterminize | \
        fsmencode -l - $lgDir/key.bfsm | \
        fsmminimize | \
        fsmencode -dl - $lgDir/key.bfsm > $lgDir/LG.bfsm.tmp
    ;;
openfst)
    fstcompose $lgDir/L.bfsm $lgDir/G.bfsm | \
        fstepsnormalize | \
        fstdeterminize | \
        fstencode --encode_labels - $lgDir/key.bfsm | \
        fstminimize - | \
        fstencode --decode - $lgDir/key.bfsm | \
        fstarcsort > $lgDir/LG.bfsm.tmp
    ;;
esac

if [[ "$wfstOptFinal" == 0 ]]
then
    # Remove aux symbols from LG
    echo Removing aux symbols
    case $wfst in
    att)
        fsmprint $lgDir/LG.bfsm.tmp > $lgDir/LG.fsm.tmp1
        $aux2eps $lgDir/LG.fsm.tmp1 $lgDir/L.insyms \
            > $lgDir/LG.fsm.tmp2
        fsmcompile -t -s log -f const_input_indexed $lgDir/LG.fsm.tmp2 \
            > $lgDir/LG.bfsm
        ;;
    openfst)
        fstprint $lgDir/LG.bfsm.tmp > $lgDir/LG.fsm.tmp1
        $aux2eps $lgDir/LG.fsm.tmp1 $lgDir/L.insyms \
            > $lgDir/LG.fsm.tmp2
        fstcompile --arc_type=log --fst_type=const $lgDir/LG.fsm.tmp2 \
            | fstarcsort \
            > $lgDir/LG.bfsm
        ;;
    esac
    rm $lgDir/LG.bfsm.tmp $lgDir/LG.fsm.tmp1 $lgDir/LG.fsm.tmp2
else
    # Leave 'em in
    mv $lgDir/LG.bfsm.tmp $lgDir/LG.bfsm
fi
rm -f $lgDir/key.bfsm

# Report final size of LG
echo -n "$lgDir/LG.bfsm: "
case $wfst in
att)
    echo $(fsminfo -n $lgDir/LG.bfsm | grep "of arcs")
    ;;
openfst)
    echo $(fstinfo $lgDir/LG.bfsm | grep "of arcs")
    ;;
esac
echo done.

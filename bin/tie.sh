#!/bin/zsh
#
# Copyright 2010 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#

#
# Tie context dependent models
# Phil Garner, October 2010
# Marc Ferras, November 2011 (optimization of TB parameter to obtain
#                             the desired number of states)
#
this=$0

zmodload zsh/mathfunc

function usage
cat << EOF
needs:
$phoneSetCSV
$phoneSet
$sampaMap

creates:
$tiedTrees
$trifle
EOF

source $(dirname $0)/config.sh
source $(dirname $0)/grid.sh

# Generate the questions
# The python script is sensitive to LANG
# I use en_GB.UTF-8, but it's probably the UTF8 part that's important
mkdir -p $tiedModelDir
questions=$tiedModelDir/questions.txt

function getNewGuess ()
{
    # newGuess based on the relation log(TB) = rate * log(nStates)
    # halves the number of search iterations vs. binary search
    x0=$1
    x1=$2
    y0=$3
    y1=$4
    t=$5
    (( lx0=log(x0) ))
    (( lx1=log(x1) ))
    (( ly0=log(y0) ))
    (( ly1=log(y1) ))
    (( lt=log(t) ))
    (( rate = (ly1-ly0)/(lx1-lx0) ))
    (( lNewGuess = ly1+rate*(lx0-lt) ))
    (( newGuess = exp(lNewGuess) ))

    # binary search based new guess
    # ((newGuess=(x0+x1)/2))

    return $newGuess
}

# $1 is the TB value to use
# $2 stdout flag
function tie()
{
    if [ ! -z $sampaMap ]
    then
        if [[ $2 != 0 ]]
        then
            echo "Generating questions with sampa-map = $sampaMap" 
            $parsePhoneSet \
                -i $phoneSetCSV \
                -p $phoneSet \
                -f $questions \
                -s $silModel \
                -m $sampaMap \
                -t $1
        else
            $parsePhoneSet \
                -i $phoneSetCSV \
                -p $phoneSet \
                -f $questions \
                -s $silModel \
                -m $sampaMap \
                -t $1 >& /dev/null
	fi
    else
        if [[ $2 != 0 ]]
        then
            echo "Generating questions without mapping"
            $parsePhoneSet \
                -i $phoneSetCSV \
                -p $phoneSet \
                -f $questions \
                -s $silModel \
                -t $1
        else
            $parsePhoneSet \
                -i $phoneSetCSV \
                -p $phoneSet \
                -f $questions \
                -s $silModel \
                -t $1 >& /dev/null
        fi
    fi

# ...and the HHEd script
    cluster=$tiedModelDir/cluster.hed
    echo RO $tiedMinCluster $cdModelDir/stats.txt > $cluster
    cat $questions >> $cluster
    cat <<EOF >> $cluster
CO "$tiedModelDir/hmm-list.txt"
ST "$tiedTrees"
EOF

    opts=(
        -H $cdModelDir/mmf.txt
        -M $tiedModelDir
    )

    if [[ $2 != 0 ]]
    then
	if [[ $1 -eq 0 ]]
        then
	    opts+=( -m )
	fi
        $hhed $htsOptions $opts $cluster $cdModelDir/hmm-list.txt
        nStates=$(fgrep \~s $tiedModelDir/mmf.txt | sort -u | wc -l)
        echo $tiedModelDir/mmf.txt has $nStates states
    else
        $hhed $htsOptions $opts $cluster $cdModelDir/hmm-list.txt >& /dev/null
        nStates=$(fgrep \~s $tiedModelDir/mmf.txt | sort -u | wc -l)
    fi

    return $nStates
}



# main
if [[ $tieForceNStates -le 0 ]]
then
    # no TB optimization
    tie $tieMaxLlkInc 1
else
    # optimize TB so that we get tieForceNStates tied states
    # default low and high search limits
    # they extend automatically if necessary
    tbLow=10
    tbHigh=5000

    # only positive values
    if [[ $tbLow < 0 ]]
    then
        tbLow=0
    fi
    if [[ $tbHigh < 0 ]]
    then
        tbHigh=0
    fi

    echo "Initializing"
    # Initialize tb and number of states at the limits of the
    # specified search range
    tie $tbLow 0
    nStatesLow=$nStates
    tie $tbHigh 0
    nStatesHigh=$nStates
    echo "Initial search range is TB=$tbLow..$tbHigh ($nStatesLow..$nStatesHigh states)"

    # Expand low and high ends to include the searched number of
    # states first (in case it did not)
    while [[ $nStatesLow -lt $tieForceNStates ]]
    do
        echo -n "Halving low end from TB=$tbLow($nStatesLow states) to "
        (( tbLow = tbLow / 2 ))
        tie $tbLow 0
        nStatesLow=$nStates
        echo "TB=$tbLow($nStatesLow states)"
    done

    while [[ $nStatesHigh -gt $tieForceNStates ]]
    do
        echo -n "Doubling high end from TB=$tbHigh($nStatesHigh states) to "
        (( tbHigh = tbHigh * 2 ))
        tie $tbHigh 0
        nStatesHigh=$nStates
        echo "TB=$tbHigh($nStatesHigh states)"
    done

    echo "Final search range is $tbLow..$tbHigh ($nStatesLow..$nStatesHigh states)"
    n=1
    newGuessOld=0
    newGuess=-1
    nStates=-1
    while [[ $nStates != $tieForceNStates && $newGuessOld != $newGuess ]]
    do
        newGuessOld=$newGuess
        #   getNewGuess $tbLow $tbHigh
        getNewGuess $nStatesLow $nStatesHigh $tbHigh $tbLow $tieForceNStates
        echo "It $n: searching TB=$tbLow($nStatesLow states) to TB=$tbHigh($nStatesHigh states)"
        echo -n "      guessing TB=$newGuess "
        tie $newGuess 0
        echo "($nStates states)"
        if [[ $nStates -gt $tieForceNStates ]]
        then
            tbLow=$newGuess
            nStatesLow=$nStates
        else
            if [[ $nStates -lt $tieForceNStates ]]
            then
                tbHigh=$newGuess
                nStatesHigh=$nStates
            fi
        fi

        (( n = n + 1 ))
    done
    # fill the log with the optimal guess (could be bypassed as it's
    # been computed in the last iteration)
    tie $newGuess 1
fi

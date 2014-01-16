#!/bin/zsh
#
# Copyright 2013 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, April 2013
#
this=$0
source $(dirname $0)/config.sh
source $(dirname $0)/grid.sh

# Phonetisaurus
phsaurusg2p=${PSAURUS_G2P:-$(which phonetisaurus-g2p)}

nBest=${N_BEST:-1}
phsaurusFST=${PHSAURUS_FST:-local/dictionary.fst}
phsaurusWordList=${PHSAURUS_WORD_LIST:-words.txt}
phsaurusDict=${PHSAURUS_DICT:-dictionary.txt}

# That pipe at the end removes the score after the word
$phsaurusg2p \
    --model=$phsaurusFST \
    --input=$phsaurusWordList \
    --nbest=$nBest \
    --words=true \
    --isfile=true \
    | sed 's/\s/ /g' | cut -d' ' -f 1,3- \
    > $phsaurusDict

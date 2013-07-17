#!/bin/zsh
#
# Copyright 2013 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, April 2013 (based on original by Alexandre Nanchen)
#
this=$0
source $(dirname $0)/config.sh
source $(dirname $0)/grid.sh

# Phonetisaurus
psaurusalign=${PSAURUS_ALIGN:-$(which phonetisaurus-align)}
psaurusfst=${PSAURUS_FST:-$(which phonetisaurus-arpa2fst)}
estimatengram=${MIT_ESTIMATE_NGRAM:-$(which estimate-ngram)}

inDict=${IN_DICT:-dictionary.txt}

alignFile=align.txt
arpaFile=arpa.txt

#
# The align phase can use quite a lot of memory; 6GB or so
#
echo "Align phase ..."
$psaurusalign \
    --input=$inDict \
    --ofile=$alignFile

if [[ ! -e $alignFile ]]
then
    echo "Error during alignment"
    exit 1
fi

echo "Creating ARPA language model $arpaFile ..."
$estimatengram \
    -s FixKN \
    -o 7 \
    -t $alignFile \
    -wl $arpaFile

echo "Creating FST"
$psaurusfst \
    --input=$arpaFile \
    --prefix=$inDict:r

#!/bin/zsh
#
# Copyright 2012 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, May 2012
#

this=$0
source $(dirname $0)/config.sh
source $(dirname $0)/grid.sh

#
# Creates the language model files necessary for at least the HTK
# derived decoders.
#
# HVite is easy enough.  $main-dict will work, inserting sil and sp at
# the end of each word as happened during training.  In practice it's
# easier to create a specific dictionary which will be shorter.
#
# HDecode is pickier.  In principle, $flat-dict should work because
# sil and sp are implied after each word.  However, you aren't allowed
# monophone sil anywhere else in the dictionary at all (otherwise it
# gets expanded into a triphone).  Further, You need < 2^15
# pronunciations (else it complains about building with int).  So you
# can't have noises like:
#
#  COUGH sil
#
# The solution here is to build a custom dictionary for HDecode.
# dict-man.rb will do this.
#

# Both decoders need a word list at some point
mkdir -p $lmDir
wordList=$lmDir/word-list.txt
echo $wordList
echo $sentBegin >  $wordList
echo $sentEnd   >> $wordList
cat $lmWordList >> $wordList

# Then we generate decoder specific files
case $decoder in
HVite)
    # HBuild
    echo Building LM for HVite in directory $lmDir
    opts=(
        $htsOptions
        -s '<s>' '</s>'
        -u '<UNK>'
        -z
        -n $lmARPAFile
    )
    $hbuild $opts $wordList $lmDir/network.txt
    $binDir/dict-man.rb $mainDict -w $wordList -o $lmDir/main-dict.txt
    ;;
HDecode)
    # LNorm and HLMCopy require an ARPA LM without escapes.  HDecode,
    # however, requires the escapes.  It's HDecode that's wrong.
    echo Building LM for HDecode in directory $lmDir
    opts=(
        $htsOptions
        -f TEXT
        -w $wordList
    )
    if $useLNorm
    then
        $lnorm $opts $lmARPAFile $lmDir/arpa-ngram.txt
    else
        $hlmcopy $opts $lmARPAFile $lmDir/arpa-ngram.txt
    fi
    sed -i "s/'/\\\'/g" $lmDir/arpa-ngram.txt # Escape the apostrophes
    $binDir/dict-man.rb $flatDict -w $wordList -o $lmDir/flat-dict.txt
    ;;
*)
    echo "Don't know how to create LM for decoder $decoder" >&2
    exit 1
    ;;
esac

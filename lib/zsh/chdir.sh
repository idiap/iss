#!/bin/zsh For the editor
#
# Copyright 2011 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, July 2011
#

# Create an output directory and change to it
dir=test-dir
if [[ $1 != '' ]]
then
    dir=$1
    shift
fi
echo Changing to $dir
mkdir -p $dir
cd $dir

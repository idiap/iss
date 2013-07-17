#!/bin/bash
#
# Copyright 2011 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner
#

#
# Flatten a database by building a tree of links
#
# Uses a naive method that links every file individually.  Basically
# you should use flatten.sh instead, but this may be useful when
# mapping uppercase to lowercase or vice-versa.
#
function usage()
{
cat <<EOF
flatten.sh [-h -r -t <target-dir>] <source-dir>
-h  Print this help
-t  [.] Where to write the files.
-r  Really do it, rather than just check it looks right.
EOF
exit 0
}

# Config
sourceDir=.
targetDir=.

# Walk the command line
while (( $# > 0 ))
do
    case $1 in
    '-h')
        usage
        ;;
    '-r')
        really=1
        ;;
    '-t')
        shift
        targetDir=$1
        ;;
    *)
        sourceDir=$1
        ;;
    esac
    shift
done

# Confirm this is really what you want to do
echo Source: $sourceDir/\*
echo Target: $targetDir
if [[ ${really:=0} != 1 ]]
then
    echo Use -r to actually run
    exit 0
fi

# Find the files; follow links
files=$(cd $sourceDir; find -L . -type f)
nFiles=0
for file in $files
do
    # Bits of files...
    d=$(dirname $file | sed 's/^\.\///')
    b=$(basename $file)
    c1=$(echo $d | cut -d/ -f1)
    c2=$(echo $d | cut -s -d/ -f2-)

    # ...joined together into source and target
    sourceFile=$sourceDir/$d/$b
    targetPath=$targetDir
    if [[ "$c2" != "" ]]
    then
        targetPath+=/$c2
    fi
    targetFile=$targetPath/$b

    # Append the disk name to clashes
    if [[ -h $targetFile ]]
    then
        targetFile+=.$c1
    fi

    # Do the write
    mkdir -p $targetPath
    ln -s $sourceFile $targetFile

    # Keep a tally
    echo -ne $((nFiles++))\\r
done
echo $nFiles files
rm -f $tmpFile

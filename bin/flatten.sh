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
# Where possible, this script will link directories instead of eac
# file in the directory.  If you want to change case, try
# flatten-naive.sh instead.
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
    '-lc')
        # Won't do quite what you think with mixed file and directory
        # links
        lowerCase=1
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

# First find all the directories
tmpDir=/dev/shm/flatten$$
mkdir $tmpDir
dirs=$(cd $sourceDir; ls)
for dir in $dirs
do
    echo Searching $dir
    (cd $sourceDir/$dir; find -L . -type d > $tmpDir/$dir)
done

# Create directories that appear more than once
sort $tmpDir/* | uniq -c | sed 's/^ *//' \
    | while read freq
do
    count=$(echo $freq | cut -d' ' -f1)
    if [[ $count != 1 ]]
    then
        p=$(echo $freq | cut -d' ' -f2 | sed 's/^\.\///')
        if [[ ${lowerCase:=0} == 1 ]]
        then
            p=$(echo $p | tr '[:upper:]' '[:lower:]')
        fi
        mkdir -p $targetDir/$p
    fi
done

# Now find all directories and files
echo Searching $sourceDir
files=$(cd $sourceDir; find -L .)
nLinks=0
for file in $files
do
    # Bits of files...
    f=$(echo $file | sed 's/^\.\///')
    d=$(echo $f | cut -d/ -f1)
    p=$(echo $f | cut -s -d/ -f2-)
    if [[ ${lowerCase:=0} == 1 ]]
    then
        p=$(echo $p | tr '[:upper:]' '[:lower:]')
    fi

    # ...joined together into source and target
    sourceFile=$sourceDir/$f
    targetLink=$targetDir/$p

    # Append the disk name to clashes
    if [[ -h $targetLink && -f $sourceFile ]]
    then
        targetLink+=.$d
    fi
        
    if [[ "$p" != "" && ! -e $targetLink ]]
    then
        # Do the link
        ln -s $sourceFile $targetLink

        # Keep a tally
        echo -ne $((nLinks++))\\r
    fi
done
echo $nLinks links
rm -r $tmpDir

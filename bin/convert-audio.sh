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
# Find audio files and convert
#
function usage()
{
cat <<EOF
convert-audio.sh [-r -t <target-directory>] <source-directory>
-h  Print this help.
-t  [.] Where to write the files.
-e  [sph] Source file extension.
-c  [sph] Source encoding.
-p  [.]   Pattern to match in source file / path.
-o  [see output] Options to pass to sox to read raw files.
-r  Really do it, rather than just check it looks right.
EOF
exit 0
}

# Programs
sox=$(which sox)
shorten=/idiap/resource/software/shorten/shorten
wdecode=/idiap/resource/software/nist-debian/bin/w_decode

# Config
sourceDir=.
targetDir=.
sourceExt=sph
targetExt=wav
sourceEnc=sph
pattern=.

# For raw files
rawOpts="-r 16000 -s -2 -x"

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
    '-e')
        shift
        sourceExt=$1
        ;;
    '-c')
        shift
        sourceEnc=$1
        ;;
    '-p')
        shift
        pattern=$1
        ;;
    '-o')
        shift
        rawOpts=$1
        ;;
    *)
        sourceDir=$1
        ;;
    esac
    shift
done

# Confirm this is really what you want to do
echo Source: $sourceDir/\*/\*.$sourceExt
echo Target: $targetDir/\*/\*.$targetExt
echo Encoding: $sourceEnc
echo Raw opts: $rawOpts
echo Pattern: $pattern
if [[ ${really:=0} != 1 ]]
then
    echo Use -r to actually run
    exit 0
fi

# Find the files
files=$(cd $sourceDir; find -L . -name "*.$sourceExt" | grep $pattern)
tmpFile=/dev/shm/findAudio$$.tmp
nFiles=0
for file in $files
do
    # Figure out where to read from and write to
    d=$(dirname $file | sed 's/^\.\///')
    b=$(basename $file)
    t=$(echo $b | sed s/$sourceExt\$/$targetExt/)
    targetPath=$targetDir/$d
    targetFile=$targetPath/$t
    sourceFile=$sourceDir/$d/$b

    # Do the write
    mkdir -p $targetPath
    case $sourceEnc in
    'sph')
        # Sphere (WSJ etc.)
        $wdecode -f -o pcm $sourceFile $tmpFile
        $sox $tmpFile $targetFile
        ;;
    'raw')
        # Raw (Aurora and the like)
        $sox -t raw $rawOpts $sourceFile $targetFile
        ;;
    'flac')
        $sox $sourceFile $targetFile
        ;;
    'shn')
        $shorten -x $sourceFile $tmpFile
        $sox -t raw $rawOpts $tmpFile $targetFile
        ;;
    *)
        echo Unknown encoding $sourceEnc
        exit 1
        ;;
    esac

    # Keep a tally
    echo -ne $((nFiles++))\\r
done
echo $nFiles files
rm -f $tmpFile

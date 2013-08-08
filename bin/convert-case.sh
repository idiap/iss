#!/bin/zsh
#
# Copyright 2011 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, December 2011
#
autoload zmv

# See http://unix.stackexchange.com/questions/20222/change-entire-directory-tree-to-lower-case-names

function usage()
{
cat <<EOF
convert-case.sh [-u -l] <source-directory>
-u  Convert to upper case
-l  Convert to lower case
EOF
exit 0
}

# Config
to=neither
sourceDir=\*

# Walk the command line
while (( $# > 0 ))
do
    case $1 in
    '-h')
        usage
        ;;
    '-u')
        to=upper
        ;;
    '-l')
        to=lower
        ;;
    *)
        sourceDir=$1
        ;;
    esac
    shift
done

# Do it
case $to in
'upper')
    zmv -o-i "(**/)($sourceDir)" '$1${2:u}'
    ;;
'lower')
    zmv -o-i "(**/)($sourceDir)" '$1${2:l}'
    ;;
*)
    usage
    ;;
esac

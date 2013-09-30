#!/bin/zsh
#
# Copyright 2010 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#

#
# Extract Features
#
# Phil Garner, October 2010
#
this=$0
source $(dirname $0)/config.sh

function usage
cat <<EOF
This is $0
needs:
$fileList [file] or [ID file]
$audioDir
$audioName
$featsDir
$featName
$featExt
$hcopyConfig
creates:
$extractList
Features in extractlist
EOF

autoload deal.sh

function createDirTree
{
    # This would be better using while read
    cat $1 \
        | cut -d' ' -f2  | xargs -n 1 dirname \
        | sort -u | xargs -n 1 mkdir -p
}

function Split
{
    # Build a file list.  The routine depends on the number of columns
    # in the list.
    if [[ ! -e $extractList ]]
    then
        echo Generating $extractList
        case $fileListColumns in
        '1')
            while read file 
            do
                audio=$audioDir/$audioName/$file.wav
                feats=$featsDir/$featName/$file.$featExt
                echo $audio $feats
            done < $fileList | sort -u > $extractList
            ;;
        '2')
            while read id file 
            do
                audio=$audioDir/$audioName/$file.wav
                feats=$featsDir/$featName/$file.$featExt
                echo $audio $feats
            done < $fileList | sort -u > $extractList
            ;;
        '4')
            while read id file begin end
            do
                audio=$audioDir/$audioName/$file.wav
                feats=$featsDir/$featName/$file.$featExt
                echo $audio $feats
            done < $fileList | sort -u > $extractList
            ;;
        *)
            echo "Don't know how to handle $fileListColumns column file lists"
            exit 1
            ;;
        esac
    fi

    mkdir -p deal
    deal.sh $extractList deal/$extractList.{01..$nJobs}
}

function Array
{
    # Run the extraction
    case $extract in
    'hcopy')
        # HTK or HTS based HCopy
        echo Running $hcopy
	createDirTree deal/$extractList.$grid0Task
        opts=(
            -C $hcopyConfig
            -S deal/$extractList.$grid0Task
        )
        if [[ $hcopyConfigTarget == 1 ]] 
        then
            [[ ! -e hcopy-target.cnf ]] && \
                echo "TARGETKIND = $targetKind" > hcopy-target.cnf
            opts+=( -C hcopy-target.cnf )
        fi
        $hcopy $htsOptions $opts
        ;;
    'tracter')
        # The extracter executable supplied with tracter
        if [[ ! -f $extracterConfig ]]
        then
            echo No tracter config file $extracterConfig
            exit 1
        fi
        source $extracterConfig
        export ASRFactory_Source=SndFile
        echo Running $extracter
        $extracter -f deal/$extractList.$grid0Task
        ;;
    'ssp')
        # The extracter.py script in SSP
	createDirTree deal/$extractList.$grid0Task
        echo Running $sspExtracter
        $sspExtracter -f deal/$extractList.$grid0Task
        ;;
    'tts')
        echo Running TTS extracter
        extractor-HTS.sh deal/$extractList.$grid0Task
        ;;
    *)
        echo Unknown extraction tool: $extract
        exit 1
    esac
}

# Grid
array=( $nJobs 1 )
source $(dirname $0)/grid.sh

#!/bin/zsh
#
# Copyright 2011 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, August 2011
#   Marc Ferras, October 2011
#   György Szaszák, January 2013
#
this=$0
source $(dirname $0)/config.sh

autoload deal.sh

#
# Adapt
#

# General config for transformation based adaptation
function configTrans
cat <<EOF
TARGETKIND       = $targetKind
HADAPT:TRANSKIND = $adaptTransKind
HADAPT:ADAPTKIND = $adaptKind:u
HADAPT:KEEPXFORMDISTINCT = TRUE
EOF

# The global class of all mixture components and all states
function globalMacro
cat <<EOF
~b "global.base"
<MMFIDMASK> *
<PARAMETERS> MIXBASE
<NUMCLASSES> 1
  <CLASS> 1 {*.state[2-4].mix[1-$mixOrder]}
EOF

# Convert occupancy into regression tree
function treeHed
cat <<EOF
LS $adaptModelDir/stats.txt
RC $nTrees "rtree"
EOF


function Split
{
    mkdir -p $adaptTransDir
    case $adaptKind in
    'base')
        # Build a global base class
        globalMacro > $adaptTransDir/global.base
        configTrans > $adaptTransDir/adapt.cnf
        echo "HADAPT:BASECLASS = global.base" >> $adaptTransDir/adapt.cnf
        ;;
    'tree')
        # Create a regression class tree
        hed=adapt-tree.hed
        treeHed > $hed
        opts=(
            $htsOptions
            -H $adaptModelDir/mmf.txt
            -M $adaptTransDir
        )
        $hhed $opts $hed $adaptModelDir/hmm-list.txt
        configTrans > $adaptTransDir/adapt.cnf
        echo "HADAPT:REGTREE = rtree.tree" >> $adaptTransDir/adapt.cnf
        ;;
    *)
        echo $0: Unknown HADAPT:TRANSKIND - $adaptKind
        exit 1
    esac

    case $adaptTransKind in
    'MLLRCOV')
        echo "HADAPT:USEBIAS = FALSE" >> $adaptTransDir/adapt.cnf
        ;;
    'MLLRVAR')
        echo "HADAPT:USEBIAS = FALSE" >> $adaptTransDir/adapt.cnf
        ;;
    *)
        echo "HADAPT:USEBIAS = TRUE" >> $adaptTransDir/adapt.cnf
    esac

    if [[ $useSmap = "true" ]]
    then
        echo "HADAPT:USESMAP = TRUE" >> $adaptTransDir/adapt.cnf
        echo "HADAPT:SMAPSIGMA = $smapSigma" >> $adaptTransDir/adapt.cnf
        # Necessary due to a bug in HTS 2.2, can be removed if fixed:
        echo "HADAPT:DURADAPTKIND = TREE" >> $adaptTransDir/adapt.cnf
    fi

    # Saves speaker specific models - works only for mean adaptation
    if [[ $saveSpkrModels = "true" ]]
    then
        echo "HADAPT:SAVESPKRMODELS = TRUE" >> $adaptTransDir/adapt.cnf
    fi

    # Deal adaptList while all utterances from the same speaker are
    # together on the same list
    mkdir -p deal
    adaptListSpk=`echo $adaptList | sed -e "s/\.txt/\-spk.txt/g"`

    case $adaptPattern in
    '%%%/*')
        cat $adaptList | cut -c1-3 | sort -u > $adaptListSpk
        ;;
    *)
        cat $adaptList | awk '{ fname=system("basename " $1) }' | cut -c1-3 | sort -u > $adaptListSpk
        ;;
    esac

    deal.sh $adaptListSpk deal/$adaptListSpk.{01..$nJobs}
    for i in {01..$nJobs}
    do
        cat /dev/null > deal/$adaptList.$i
        foreach spk in $(cat deal/$adaptListSpk.$i)
        do
            case $adaptPattern in
            '%%%/*')
                grep "$spk/" $adaptList >> deal/$adaptList.$i
                ;;
            *)
                grep "^$spk" $adaptList >> deal/$adaptList.$i
                ;;
            esac
        done
    done
}


function Array
{
    echo Running adaptation
    # The first pipeline creates the directories.
    cat deal/$adaptList.$grid0Task | cut -d' ' -f2 | cut -d'=' -f2 | xargs -n 1 dirname | sort -u | xargs -n 1 mkdir -p

    # Don't try to mix transform types in the same directory; rather, the
    # adaptKind will influence the name.  Just add a .txt extension
    # consistent with mmf.txt
    #
    # A -J <dir> is enough to find base classes and input transforms as
    # long as the names match the files.
    opts=(
        -C $adaptTransDir/adapt.cnf
        -S deal/$adaptList.$grid0Task
        -I $adaptMLF
        -H $adaptModelDir/mmf.txt
        -K $adaptTransDir $adaptTransExt
        -J $adaptTransDir
        -u a
    )

    # Add additional dependency directory (for parent xforms)
    if [[ $depTransDir != "" ]]
    then
        opts+=(
            -J $depTransDir
        )
    fi

    if [[ $satTransDir != "" ]] && [[ ! $inputTransDir != "" ]]
    then
        opts+=(
            -J $satTransDir $satTransExt
            -E $satTransDir $satTransExt
            -a
        )
    fi

    if [[ $inputTransDir != "" ]] && [[ ! $satTransDir != "" ]]
    then
        opts+=(
            -J $inputTransDir $inputTransExt
            -a
        )
    fi

    if [[ $inputTransDir != "" ]] && [[ $satTransDir != "" ]]
    then
        opts+=(
            -J $inputTransDir $inputTransExt
            -J $satTransDir
            -E $satTransDir $satTransExt
            -a
        )
    fi
    
    # -J cannot be last option, hence, add the -h options now to be last
    case $adaptPattern in
    '%%%/*')
        opts+=(
            -h $adaptPattern
        )
        ;;
    *)
        opts+=(
            -h "%%%*"
        )
        ;;
    esac
    $herest $htsOptions $opts $adaptModelDir/hmm-list.txt
}
     
# Grid
array=( $nJobs 1 )
source $(dirname $0)/grid.sh

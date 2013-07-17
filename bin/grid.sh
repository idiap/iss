#!/bin/zsh (just for the editor)
#
# Copyright 2010 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, October 2010
#   David Imseng, November 2010
#

#
# Allow script to run on the grid
#

# Print help
if [[ "$HELP" == 1 ]] && [[ "$(whence usage)" == "usage" ]]
then
    usage
    exit 0
fi

setopt HUP
useGE=${USE_GE:-0}
jobID=${JOB_ID:-0}
jobName=${this:-none}
jobFile=${JOB_FILE:-job-file}
gridMode=serial
gridTask=0
arraySize=${array[1]:=0}
arrayRepeat=${array[2]:=1}

# Logging (same as the one in bin/config is OK)
geLogDir=${LOG_DIR:-log}
mkdir -p $geLogDir

#
# These are important; they define the way this framework works.
# qsub's default behaviour is to copy its argument, assumed to be a
# script, to a spool area.  If it does that, grid.sh and config.sh
# can't be found.  Rather, use -b to treat the scripts as binaries and
# run in place.
#
# ...except as of February 2011, Idiap's grid assumes everything is a
# script, so we do actually need -S /bin/zsh too, which normally
# wouldn't be needed with -b y
#
geOpts=(
    -r y # Restart the job if the execution host crashes
    -b y # Pass a path, not a script, to the execution host
    -cwd # Retain working directory
    -V   # Retain environment variables
    -S /bin/zsh
    -e $geLogDir
    -o $geLogDir
    ${=GE_OPTIONS}
)

#
# Submit a job, print just the job number.
# Output of qsub to parse is:
#  Your job 3260017 ("test.sh") has been submitted
#  Your job-array 3260017.1-2:1 ("test.sh") has been submitted
#
function submit
qsub $geOpts $* | cut -d" " -f3 | cut -d. -f1


#
# This GE system uses a file to track job dependencies.  The GE ID
# returned by qsub is placed in the file $jobFile.  This file is
# checked before submitting and the contents added to the -hold_jid
# list.
#
# There are two job types: serial and array.  Serial is just a single
# job that runs and finishes.  Array jobs are actually submitted as
# (at least) three jobs.  The array jobs have GRID_MODE mode set to
# split, array and merge respectively; the final two can be iterated.
# The ones with mode "array" are themselves parallel jobs.
#
if [[ $useGE = 1 ]]
then
    if [[ $jobID = 0 ]]
    then
        # GE is selected, but we're not under GE so try to submit
        if [[ $jobName = none ]]
        then
            # Fail; we don't have a script name
            echo Must set \$this to run under GE
            exit 1
        else
            # Get the job deps
            [[ -e $jobFile ]] && jobDep=$(cat $jobFile)
            [[ $jobDep != "" ]] && jobStr=( -hold_jid $jobDep )

            # Submit
            echo -n Submitting $this:
            if [[ $arraySize = 0 ]]
            then
                # It's a serial job
                export GRID_MODE=serial
                jobNum=$(submit $jobStr $jobName)
                echo " $jobNum"
                echo $jobNum > $jobFile
                exit 0
            else
                # It's an array job; submit three jobs
                export GRID_MODE=split
                jobNum=$(submit $jobStr $jobName)
                echo -n " $jobNum"

                # Repeat the array and merge parts as required
                for iter in {1..$arrayRepeat}
                do
                    # An array job
                    export GRID_ITERATION=$iter
                    export GRID_MODE=array
                    jobStr=( -hold_jid $jobNum -t 1-$arraySize )
                    jobNum=$(submit $jobStr $jobName)
                    echo -n " $jobNum"

                    # A merge (or collector) job
                    export GRID_MODE=merge
                    jobStr=( -hold_jid $jobNum )
                    jobNum=$(submit $jobStr $jobName)
                    echo -n " $jobNum"
                done
                echo

                # Save the final job number
                echo $jobNum > $jobFile
                exit 0
            fi
        fi
    else
        # We are running under GE
        gridMode=$GRID_MODE
        gridIteration=$GRID_ITERATION
        TASK_ID=$GE_TSK_ID$SGE_TASK_ID
        gridTask=${TASK_ID:-0}
        grid0Task=$(printf "%02d" $gridTask)
        echo Mode: $gridMode
        echo Grid: $JOB_NAME id $JOB_ID task $grid0Task on host $HOSTNAME
    fi
else
    # GE is not selected so run interactively
    echo Interactive job - renice to $nice
    renice $nice -p $$

    if [[ ! $arraySize = 0 ]]
    then
        # Emulate an array job on GE
        if [[ "$(whence Split)" == "Split" ]]
        then
            Split
        fi
        if [[ "$(whence Array)" == "Array" ]]
        then
            for gridIteration in {1..$arrayRepeat}
            do
                for gridTask in {1..$arraySize}
                do
                    grid0Task=$(printf "%02d" $gridTask)
                    echo Emulate: task $grid0Task
                    Array &
                done
                echo -n Waiting for $arraySize processes
                echo \(iteration $gridIteration of $arrayRepeat\)
                wait
                echo Done
                if [[ "$(whence Merge)" == "Merge" ]]
                then
                    Merge
                fi
            done
        fi
    fi
fi

# Iff the functions are defined then we can dispatch the processing to
# them.  It's possible to define only some of them.
case $gridMode
in
'split')
    [[ "$(whence Split)" == "Split" ]] && Split
    ;;
'array')
    [[ "$(whence Array)" == "Array" ]] && Array
    ;;
'merge')
    [[ "$(whence Merge)" == "Merge" ]] && Merge
    ;;
esac

# Unless the action was to submit a job, we'll always drop through to
# the calling script here.
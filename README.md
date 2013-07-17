# Model training and evaluation scripts

## Overview

This is a collection of scripts for training and running speech
recognition and (one day) synthesis.  It is largely based on HTS
rather than HTK.

The top level contains a `Config.sh` and a few other scripts that source
`Config.sh` and run things (you can find example top level scripts in
`etc/examples`).  These "top level scripts" are the things you can edit
to customise to whatever you want to do.  `Config.sh` imposes a
consistent feel, e.g., it immediately changes directory into the
working directory specified as the first argument; so
```
Extract.sh my-dir
```
creates and changes to `./my-dir` before doing anything.

The bin directory contains bin/config.sh and other scripts that source
bin/config.sh and do actual work.  These "working scripts" should
remain task independent.  The working scripts also use zsh functions
in lib/zsh.  Similar to Config.sh, bin/config.sh imposes a consistent
feel.

The top level scripts communicate with the working script using
environment variables.  In this sense they can be written in any
scripting language.  See bin/config.sh for a (long) list of which
environment variables can be used.

Basic sequence based on the HTK book:
```
extract.sh
init-train.sh
flat-start.sh
fix-silence.sh
align.sh
reestimate-mono.sh
init-tri.sh
reestimate-tri.sh
tie.sh
mix-up.sh
synth-full.sh
```
Then for decoding:
```
extract.sh
decode.sh
score.sh
```
although there is a decoder dependent grammar construction stage too.

The scripts themselves are written mainly in `zsh`, which is like `sh`
or `bash`, but it handles arrays like `csh`.  Basically, if you know
`bash` then just pretend it's `bash`.  The place where this will come
undone is arrays: In `bash` the first element is `${array[0]}`, in
`zsh` it is `$array[1]`.  `bash`'s `${array[*]}` is just `$array` in
`zsh`.  `zsh` is nicer :-)

These scripts will run under SGE simply by setting
```
export USE_GE=1
```
In this case, the sequence of working scripts called at top level form
a graph of SGE jobs.  Each working script is held until the previous
one completes.

## Some naming conventions

In writing ISS I tried to stick to these conventions.  Of course, much
of it is subjective.

File names in `bin/` should be lower case with words separated by
hyphens, as in `/usr/bin` etc.
```
flat-start.sh 	(not flatStart.sh)
dict-man.rb	(not dictMan.rb)
```
Favour standard file extensions rather than htk-specific ones
```
mmf.txt	(not model.mmf)
train-mlf.txt	(not train.mlf)
```
Shell variable names should not contain hyphens or underscores
```
dbaseRoot     	  (not dbase_root)
mainMLF	  (not main_MLF)
```
Environment variables should be upper case and underscore separated
```
DBASE_ROOT
MAIN_MLF
```
Keep lines to a maximum of 80 characters.
Use a basic indent of 4 spaces.
Avoid really short abbreviations where possible
```
train		(not TRN)
devel		(not DEV)
```
Avoid brackets around shell variables where possible
```
$mainDir      (not ${mainDir})
```
Use `$(cmd)` instead of `` `cmd` ``
Use `ksh` style `[[ ]]` instead of `sh` style `[ ]`

Favour `create` over `build`, `make`, `gen` etc.

[Phil Garner](http://www.idiap.ch/~pgarner),
Idiap,
October 2010

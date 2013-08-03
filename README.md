# Model training and evaluation scripts

## Overview

This is a collection of scripts for training and running speech
recognition and (one day) synthesis.  It is largely based on HTS
rather than HTK.

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

## Documentation

For more documentation, please see the [iss
wiki](https://github.com/idiap/iss/wiki) on GitHub.

There is no mailing list (yet), but feel free to use the
[juicer](https://github.com/idiap/juicer) list: To subscribe, send a
message to mailto:juicer-list-request@idiap.ch with `subscribe` in the
body.

[Phil Garner](http://www.idiap.ch/~pgarner),
Idiap,
October 2010

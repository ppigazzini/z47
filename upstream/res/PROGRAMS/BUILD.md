# Building the demonstration programs

Build the whole set from this directory:

    make

`make` compiles every `*.p47u` source to `*.p47` with `rejig`, exports each to
`*.rtf` through `t47`, and rebuilds the index `Example-programs.txt`. There is
no per-program target.

## Targets

    make          build every .p47 and .rtf, then rebuild the index
    make index    rebuild Example-programs.txt only, from the .p47u headers
    make clean    delete the generated .p47 and .rtf

## Prerequisites

    rejig      a build at the repository root, or on the PATH
    t47        a build at the repository root, or on the PATH
    python3    for the index

## Index header fields

`make index` takes one row per program from three `@` comment fields in the
`.p47u` header, matched wherever they appear:

    @ Index:   <3 to 8 word description>
    @ Author:  <name or names>
    @ Version: <version>

`@ Index:` is the description column and the one field every program
needs. `@ Author:` and `@ Version:` are optional; a program without them leaves
that column empty. `Example-programs.txt` is generated, so a new description or
author is edited into the `.p47u` header, never into the index file.

## Other header fields

A header may also include fields the index does not use:

    @ Source:  the origin, an application note AN00xx or a forum link
    @ Tested:  what a sim run of the program produced
    @ input:   the registers, stack or flags the test set
    @ output:  the expected result

A program from an application note names it in `@ Source:`: STRUCT from AN0007,
INTDEMO from AN0022, SETT from AN0015, sums from AN0005 and AN23ALL from AN0023.

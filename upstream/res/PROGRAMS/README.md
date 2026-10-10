# C47/R47 Demonstration Programs

The `Makefile` produces `*.p47` from the `*.p47u` using a copy of
[`rejig`][1], then uses `t47` to `READP` that P47 byte-coded program
into the simulator and `XPORTP` it out as the `*.rtf` form.
This process prefers in-tree binaries for both, at the root
of the repo, but it will fall back to a `PATH` search if it
cannot find what it needs there.

This accomplished, it then calls `mkindex.py` to rebuild the
`Example-programs.txt` index from the tagged metadata at the
top of each `*.p47u` file.  Do not make manual edits to it;
change the metadata and run `make` instead.

New examples should follow the style example set by `FactIt.p47u`.
Simply add the file to this directory, run `make`, and commit all
three versions to Git.  We violate the common rule not to
commit generated files since we do not want to make having
`rejig`, `t47` and `python` as prerequisites for end-users to
try out these examples.

The same rules apply to the `tvm/` subdirectory, holding
Duncan Murray's TVM problem demo set.

[1]: https://tangentsoft.com/rpn/rejig

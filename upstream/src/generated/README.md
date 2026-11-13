`make sim` and `make simr47` copy the generated sources here, for tools outside the meson build. The meson build itself does not look in this directory: it
compiles the files it generates in its own build directory.

`src/generateTests/constantsCheck.py` writes its report, `constantsVerification.txt`, here during a testSuite build.

Git ignores every untracked file here. The report is the only tracked file and is is committed only by a project owner at a release tag.

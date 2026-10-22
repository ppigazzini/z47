# z47 — the C47 calculator, ported to Zig

C47 and R47 are RPN calculator firmware for SwissMicros hardware — two keyboard
models of the same application, each built for the original DM42 (DMCP) and
for the newer DMCP5 hardware (the DM42n for C47, the R47 for R47), plus a GTK
desktop simulator of each. They are maintained upstream in C
at [gitlab.com/rpncalculators/c43](https://gitlab.com/rpncalculators/c43) — the
GitLab path keeps the historical `c43` name — with user-facing information at
[47calc.com](https://47calc.com).

**z47 re-implements that calculator in Zig, with upstream's C retained as the
reference the port is measured against.** Every upstream calculator `.c` file
that is part of the program has a named Zig owner — the sole exception is an
offline `gperf` input generator that no build compiles — and the product builds
link none of upstream's first-party calculator C. Both facts are gated, not
asserted here:

```sh
python3 .github/project/check-upstream-correspondence.py   # owner for every C file
bash .github/project/check-c-dependency-phase-i-policy.sh .            # zero first-party C in the product lanes
```

Third-party C *is* still compiled in: decNumber and the SwissMicros SDKs are
vendored under `upstream/dep/` and compiled as they are, and the firmware
cross-builds GMP from source with upstream's `upstream/subprojects/` overlay.
What the imported calculator tree still supplies is the headers the generators
and the generated C compile against, the firmware linker scripts, the
calculator's resources, and the parity reference.

This is an independent port. It is not affiliated with SwissMicros or with the
upstream C47 project, and bugs found here should be reproduced against upstream
before being reported there.

## What is actually verified — and what is not

z47 is a *port*, so the claim worth making is **function parity with upstream**.
It is worth being exact about how much of that is demonstrated, because the
honest answer is "a well-defined part of it, not all of it".

**What is enforced on every change:**

- **Upstream's own test suite, run unmodified.** z47 never adds cases to it: the
  suite is the measuring instrument, so its pass count is only meaningful while
  it stays upstream's. Read the total off the run, never off a number in a doc.
- **Per-owner parity lanes**, most of which compile upstream's C beside the Zig
  owner and diff the two, so their reference moves whenever upstream does; a few
  are golden or Zig-only checks (`eigen_parity`, `format_parity`, the `*_test`
  roots). How many lanes exist is a fact the build knows:
  `python3 .github/project/check-parity-lanes-gated.py --repo-root .`
- **A negative control over the differential lanes.**
  `check-oracle-negative-control.py` breaks a behaviour in the Zig owner a lane
  watches and requires the lane to notice, so for a lane with a mutant a green
  run means "this lane can fail and did not", not "this lane ran". Its closing
  lines say how many lanes it mutates and which it only documents.

**What that does not establish.** The suite measures what *upstream* chose to
test, not where a re-implementation is most likely to drift, and the oracles
cover the owners that have oracles — far fewer lanes than there are owner files.
Behaviour outside both is unverified, and the project tracks its own holes rather
than papering over them: `oracle-negative-control.json` records surviving mutants
with a written reason, and at least one is recorded as a real gap, not an
equivalence. Treat "the lanes are green" as exactly that. It is not a proof of
bit-for-bit equivalence and nothing in this repository could establish one.

Everything else — the governance guards under `.github/project/`, the pinned
import, the ratchets — exists to keep that bounded claim honest as upstream
advances.

## Layout

| path | contents |
| --- | --- |
| `src/` | the ported calculator — Zig owners |
| `build/` | the Zig build control plane, harnesses, generators, packaging |
| `bridge/` | near-retired C header shims |
| `docs/` | developer documentation |
| `upstream/` | the imported C47 tree, pinned to one upstream commit |
| `build.zig` | the only supported build entrypoint |

`upstream/` is a vendored snapshot pinned in `.github/project/upstream-pin.env`
and mounted under `UPSTREAM_ROOT`, which is what leaves the canonical `src/` and
`docs/` names to z47. Every file it carries is byte-identical to that commit and
it holds no z47 content; some upstream paths are deliberately not carried at all,
each declared in `.github/project/imported-tree-divergences.txt`.
`check-imported-tree-pin.py` enforces both halves and prints how many paths are
declared.

## Building

Prerequisites, none of which the build vendors:

- **Zig** at the `ZIG_VERSION` in `.github/zig-toolchain.env`
  (`grep ZIG_VERSION= .github/zig-toolchain.env`), which also pins the CI
  toolchain.
- **Host simulator:** GTK 3, GMP, FreeType 2, and optionally PulseAudio, as
  system libraries found through `pkg-config`.
- **Firmware:** the `arm-none-eabi` GCC toolchain (`gcc`, `ar`, `ranlib`), `make`,
  `tar`, `python3` and a native `cc` for the GMP cross-build, `curl` or
  `wget` to fetch the GMP source on first use, plus the two SwissMicros SDK
  submodules — `git submodule update --init` before any `dmcp*` target, or the
  link fails.

No step drives upstream's Make or Meson build; the only `make` the build runs is
GMP's own, inside the firmware cross-build. The imported `Makefile` and Meson
files are upstream's and are kept only as parity references.

```sh
git submodule update --init   # required for firmware targets

zig build --help              # every target, with descriptions
zig build sim                 # the C47 desktop simulator (simr47 for R47)
zig build test                # upstream's test suite, unmodified
zig build dmcp                # C47 DM42 firmware (dmcpr47, dmcp5, dmcp5r47)
```

Before pushing, run the gate — not `sim` and not `test:unit`, which have both
been green over changes that CI rejected:

```sh
(. .github/project/upstream-pin.env && git fetch --no-tags "$UPSTREAM_REPOSITORY_URL" "$UPSTREAM_BRANCH")   # the pin check diffs upstream/ against UPSTREAM_COMMIT
uv sync                                                    # repo Python tooling into .venv
PATH="$PWD/.venv/bin:$PATH" bash .github/project/run-local-gate.sh
```

The fetch is needed once per clone, and it must be a full fetch: a shallow graft
breaks the merge-base gates. The gate also links DMCP packages 1-3, so it needs
the firmware prerequisites above. It runs the Linux governance, host-parity and
firmware-link lanes;
[70-tests-and-verification.md](docs/70-tests-and-verification.md) lists the
steps, and its closing banner lists what only CI runs.

## Documentation

**Start at [docs/README.md](docs/README.md)** — it is the maintained index and
gives a reading order. Direct entry points if you already know what you want:

| you want to | read |
| --- | --- |
| understand the project and its upstream relationship | [00-project-and-upstream.md](docs/00-project-and-upstream.md) |
| find your way around the tree and the build | [10-build-and-source-layout.md](docs/10-build-and-source-layout.md) |
| know what a build target does | [20-zig-build-graph.md](docs/20-zig-build-graph.md) |
| work on the host, GTK, or generated surfaces | [30-host-and-generated-surfaces.md](docs/30-host-and-generated-surfaces.md) |
| build firmware or a distribution package | [40-firmware-and-distribution.md](docs/40-firmware-and-distribution.md) |
| know where the Zig/C boundary is allowed to sit | [50-zig-c-boundaries-and-rewrite-policy.md](docs/50-zig-c-boundaries-and-rewrite-policy.md) |
| understand the CI jobs and the release flow | [60-ci-and-release-workflow.md](docs/60-ci-and-release-workflow.md) |
| know the smallest lane to re-run for a change | [70-tests-and-verification.md](docs/70-tests-and-verification.md) |
| chase a divergence the lanes did not catch | [75-debugging.md](docs/75-debugging.md) |
| work on a resync or a milestone | [80-maintainer-workflow.md](docs/80-maintainer-workflow.md) |
| find upstream and toolchain references | [90-official-references.md](docs/90-official-references.md) |
| decode the calculator's vocabulary | [95-glossary.md](docs/95-glossary.md) |

Contributor workflow, branch policy and the verification rules for each kind of
change are in [CONTRIBUTING.md](CONTRIBUTING.md).

## License

z47 is **GPL-3.0-only**, the same terms as the C47 work it derives from. The full
text is in [COPYING](COPYING) and covers every z47 source; `git grep -L
SPDX-License-Identifier -- src build` lists the files that do not yet carry the
`GPL-3.0-only` tag. The vendored tree under `upstream/`
remains under its own upstream copyright and ships the same license text.

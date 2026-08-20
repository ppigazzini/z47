# z47 — the C47 calculator, ported to Zig

C47 and R47 are RPN calculator firmware for SwissMicros hardware — two keyboard
models of the same application, each built for the DM42 (DMCP) and the DM32
(DMCP5), plus a GTK desktop simulator of each. They are maintained upstream in C
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
python3 .github/project/report-c-dependency-status.py --repo-root .
```

Third-party C *is* still compiled in: decNumber and the SwissMicros SDK are
vendored under `upstream/dep/` and linked as they are. What the imported
calculator tree still supplies is the headers those owners consume, the
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
- **Per-owner parity oracles** that compile upstream's C beside the Zig owner and
  diff the two, so the reference moves whenever upstream does. How many lanes
  exist is a fact the build knows:
  `python3 .github/project/check-parity-lanes-gated.py --repo-root .`
- **A negative control over those lanes.** `check-oracle-negative-control.py`
  breaks one behaviour in a Zig owner per lane and requires the lane to notice, so
  a green lane means "this lane can fail and did not", not "this lane ran".

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
| `bridge/` | two near-retired C header shims |
| `docs/` | developer documentation |
| `upstream/` | the imported C47 tree, pinned to one upstream commit |
| `build.zig` | the only supported build entrypoint |

`upstream/` is a vendored snapshot pinned in `.github/project/upstream-pin.env`
and mounted under `UPSTREAM_ROOT`, which is what leaves the canonical `src/` and
`docs/` names to z47. Every file it carries is byte-identical to that commit and
it holds no z47 content; a handful of upstream paths are deliberately not carried
at all, each declared in `.github/project/imported-tree-divergences.txt`.
`check-imported-tree-pin.py` enforces both halves.

## Building

Prerequisites, none of which the build vendors:

- **Zig `0.16.0`** — pinned, with the CI toolchain, in `.github/zig-toolchain.env`.
- **Host simulator:** GTK 3, GMP, FreeType 2, and optionally PulseAudio, as
  system libraries found through `pkg-config`.
- **Firmware:** `arm-none-eabi-gcc`, plus the two SwissMicros SDK submodules —
  `git submodule update --init` before any `dmcp*` target, or the link fails.

There is no Make and no Meson step. The imported `Makefile` and Meson files are
upstream's and are kept only as parity references.

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
bash .github/project/run-local-gate.sh
```

It reproduces the Linux CI verdict: the governance guards, the host-parity
build/test/oracle battery, the firmware link for every package variant, and the
tracked-generated-artifact diff. The Windows (LLP64) and macOS host lanes cannot
run locally and are adjudicated by CI.

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
text is in [COPYING](COPYING); z47's own sources carry
`SPDX-License-Identifier: GPL-3.0-only`. The vendored tree under `upstream/`
remains under its own upstream copyright and ships the same license text.

# z47 — the C47 calculator, ported to Zig

C47 and R47 are RPN calculator firmware for SwissMicros hardware — two keyboard
models of the same application, each built for the DM42 (DMCP) and the DM32 (DMCP5),
plus a GTK desktop simulator of each. It is maintained upstream in C at
[gitlab.com/rpncalculators/c43](https://gitlab.com/rpncalculators/c43) — the GitLab
path keeps the historical `c43` name — with user-facing information at
[47calc.com](https://47calc.com).

**z47 ports that calculator to Zig while keeping its behaviour bit-for-bit.** The
core is fully ported: all 230 `.c` files of the upstream calculator have Zig owners,
and the build asserts that none of the original C is compiled into the product. What
the imported tree still supplies is the C headers the Zig owners consume, the
calculator's resources, and — most importantly — the reference the port is measured
against.

## The correctness claim

z47 is a *port*, so its claim is **function parity with upstream**, not "the tests
pass". Two things enforce that, and both take upstream's source as the reference:

- **Upstream's own test suite, run unmodified.** z47 never adds cases to it: the
  suite is the measuring instrument, so the pass count is only meaningful while it
  is upstream's count, and it moves with every pin advance — read the total off the
  run, not off a number written here.
- **Per-owner parity oracles** that compile upstream's C beside the Zig owner and
  diff the two, so the reference moves whenever upstream does.

Everything else — the governance guards under `.github/project/`, the pinned import,
the ratchets — exists to keep that claim honest as upstream advances.

## Layout

| path | contents |
| --- | --- |
| `src/` | the ported calculator — Zig owners |
| `build/` | the Zig build control plane, harnesses, generators, packaging |
| `bridge/` | near-retired C header shims |
| `docs/` | developer documentation |
| `upstream/` | the imported C47 tree, pinned and byte-identical to its commit |
| `build.zig` | the only supported build entrypoint |

`upstream/` is a vendored snapshot pinned in `.github/project/upstream-pin.env` and
mounted under `UPSTREAM_ROOT`, which is what leaves the canonical `src/` and `docs/`
names to z47. It carries no z47 content and a gate enforces that.

## Documentation

**Start at [docs/README.md](docs/README.md)** — it is the maintained index and gives
a reading order. Direct entry points if you already know what you want:

| you want to | read |
| --- | --- |
| understand the project and its upstream relationship | [00-project-and-upstream.md](docs/00-project-and-upstream.md) |
| find your way around the tree and the build | [10-build-and-source-layout.md](docs/10-build-and-source-layout.md) |
| know what a build target does | [20-zig-build-graph.md](docs/20-zig-build-graph.md) |
| build firmware or a distribution package | [40-firmware-and-distribution.md](docs/40-firmware-and-distribution.md) |
| know where the Zig/C boundary is allowed to sit | [50-zig-c-boundaries-and-rewrite-policy.md](docs/50-zig-c-boundaries-and-rewrite-policy.md) |
| know the smallest lane to re-run for a change | [70-tests-and-verification.md](docs/70-tests-and-verification.md) |
| chase a divergence the lanes did not catch | [75-debugging.md](docs/75-debugging.md) |
| work on a resync or a milestone | [80-maintainer-workflow.md](docs/80-maintainer-workflow.md) |
| decode the calculator's vocabulary | [95-glossary.md](docs/95-glossary.md) |

Contributor workflow, branch policy and the verification rules for each kind of
change are in [CONTRIBUTING.md](CONTRIBUTING.md).

## Building

Zig `0.16.0`, pinned in `.github/zig-toolchain.env`. No Make, no Meson — the
imported `Makefile` and Meson files are upstream's and are kept only as parity
references.

```sh
zig build --help    # every target, with descriptions
zig build sim       # the C47 desktop simulator
zig build test      # upstream's test suite
```

[20-zig-build-graph.md](docs/20-zig-build-graph.md) explains the target map;
[70-tests-and-verification.md](docs/70-tests-and-verification.md) says which lane to
run for which change.

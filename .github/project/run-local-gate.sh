#!/usr/bin/env bash
#
# One-command local reproduction of the Linux CI lanes that can run on Linux, for
# use BEFORE pushing a change (especially an upstream resync). Runs the same
# governance-check scripts CI runs as separate jobs, then the host-parity
# build/test/oracle battery (run-host-parity-battery.sh, identical to the CI
# step), then the firmware link for every DMCP package variant, then the tracked
# generated-artifact diff. Fails fast on the first red.
#
# It is NOT the whole CI verdict, and the closing banner says so: the Windows and
# macOS host lanes cannot run here, and CI additionally packages and publishes the
# firmware artifacts. Do not read a green run as more than it claims.
#
# This is the gate the first all-Zig resync (0caee2adc) needed: three of its four
# host-parity failures — an oracle that stopped compiling, a stale generated
# artifact, and a source-ownership violation — were invisible to `zig build sim`
# and `zig build test:unit`, and only surfaced in CI. Running this catches all
# three locally. (The fourth, a Windows LLP64 int-width panic, is inherently a
# Windows-lane finding; see upstream-resync-runbook.md.)
#
# Usage:
#   bash .github/project/run-local-gate.sh
# Environment:
#   XVFB   GUI wrapper for `zig build test` (default "xvfb-run --auto-servernum"
#          if xvfb-run is on PATH, else empty). Override to "" on a real display.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

if [[ -z "${XVFB+x}" ]]; then
  if command -v xvfb-run >/dev/null 2>&1; then
    export XVFB="xvfb-run --auto-servernum"
  else
    export XVFB=""
  fi
fi

step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }

step "[1/11] zig fmt"
./.github/project/check-fmt.sh
step "[1b/11] filename hygiene (NM10-0)"
bash .github/project/check-filename-hygiene.sh
step "[1c/11] file cohesion (NM11-0)"
bash .github/project/check-file-cohesion.sh
step "[2/11] native unit tests (zig build test:unit)"
zig build test:unit
step "[3/11] tracked source ownership"
bash .github/project/check-source-ownership.sh
step "[4/11] upstream pin + port ledger"
python3 .github/project/check-upstream-port-ledger.py --repo-root .
step "[4b/11] upstream correspondence (symbol join owner coverage)"
python3 .github/project/check-upstream-correspondence.py
step "[4c/11] clamp correspondence (upstream guards inside owned functions)"
# The symbol join above answers "which owner absorbs this .c" and is blind to
# upstream adding a GUARD inside a function the Zig already has -- how the matrix
# capacity clamp survived four resyncs (M-SAFE-1) and how the config-descriptor
# version gate was missing until M-SAFE-8. Ratchets the load-path queue.
python3 .github/project/report-clamp-correspondence.py --check
step "[4d/11] macro-family correspondence (one #define, one behaviour)"
# Upstream generates function families from a single #define, so their ports must
# agree with each other. Four of the six stringTo* parsers had drifted to a
# different base and a different overflow answer (finding 10, M-SAFE-11), which
# neither the twin scan (all six live in one file) nor the parity oracles (decimal
# only) could see. Gated at zero, not ratcheted: the queue really is empty.
python3 .github/project/report-twin-divergence.py --self-test >/dev/null
python3 .github/project/report-twin-divergence.py --check
step "[4e/11] strtoul width contract (every parse site has a decided verdict)"
# `unsigned long` is 64-bit on the Linux/macOS hosts and 32-bit on the firmware and
# on Windows, so upstream's own answer differs by target and the oracles only check
# the host (finding 9, M-SAFE-10). This does not judge a verdict, it insists one
# exists: a resync that adds a parse site fails until somebody decides its answer.
python3 .github/project/check-strtoul-width-contract.py --self-test >/dev/null
python3 .github/project/check-strtoul-width-contract.py
step "[5/11] curated Zig/C boundaries"
bash .github/project/check-zig-c-boundaries.sh
step "[6/11] idiomatic-Zig ratchet"
bash .github/project/check-idiom-ratchet.sh
step "[6b/11] headless-engine severance (engine->shell)"
python3 .github/project/check-core-shell-severance.py --repo-root .
bash .github/project/test-check-core-shell-severance.sh
step "[6c/11] core platform leak vs upstream (REPORT-28 §38 L8)"
bash .github/project/check-core-platform-purity.sh
step "[6d/11] compilation carriers are module roots (REPORT-28 §39 L9)"
bash .github/project/check-module-carriers.sh
python3 .github/project/check-dead-force-imports.py --repo-root .
step "[6h/11] authored ABI surface (REPORT-28 M8 / G6)"
python3 .github/project/check-authored-abi.py --repo-root .
step "[6g2/11] harness include paths resolve"
# A quoted #include in a parity oracle reaches the imported tree by relative
# path, so a layout change breaks it at COMPILE time in a lane that neither
# `zig build sim` nor `zig build test` runs. Costs milliseconds; catches all of
# them at once.
python3 .github/project/check-harness-includes.py --repo-root .
step "[6g/11] module graph cycles (REPORT-28 M1.3)"
python3 .github/project/check-module-graph.py --repo-root .
step "[6i/11] object graph cycles per target (REPORT-28 M1.2)"
# The build declares the object set it links; the gate consumes the declaration.
# Scraping it instead would observe the truth in CI and NOTHING on a cached local
# build, since --verbose-link only emits when a link actually runs.
zig build object-manifest
python3 .github/project/check-object-graph.py --repo-root .
bash .github/project/test-check-object-graph.sh
step "[6f/11] item seam vs owner drift (REPORT-28 M1.1)"
python3 .github/project/check-item-seam-drift.py --repo-root .
step "[6j/11] softmenu tables vs upstream softmenus.c"
python3 .github/project/audit-softmenu-table-parity.py --repo-root .
step "[6e/11] transliteration contract (hot 1:1 ports intact)"
python3 .github/project/check-transliteration-contract.py --repo-root .
step "[7/11] Phase I C dependency policy"
bash .github/project/check-c-dependency-phase-i-policy.sh .
step "[8/11] workflow script locality"
bash .github/project/check-ci-no-local-dev-scripts.sh
step "[9/11] portable integer widths (Windows LLP64 trap)"
bash .github/project/check-portable-int-widths.sh
step "[10/11] host-parity build/test/oracle battery"
bash .github/project/run-host-parity-battery.sh
step "[10a/11] malformed-input corpora through the real load paths"
# ~1 s each once built, and they are the ONLY adversarial coverage the load paths
# have: every other lane feeds them files the calculator itself just wrote.
zig build pgm_load_fuzz --summary none
zig build state_load_fuzz --summary none

step "[10b/11] firmware link for every DMCP package variant"
# NOT redundant with `zig build dmcp` / `dmcp5`, and not optional. The OLD_HW
# package-3 layout asserts `_ebss <= 0x10002000` and sits EXACTLY on it, so a few
# bytes of static data anywhere in a firmware-linked owner fails the link -- and
# only in a package variant. When that happened (one @setRuntimeSafety(true) in
# shell/config.zig), every other lane here was green, as were dmcp and dmcp5.
# ~16 s cached, against a gate that already runs a 12835-case testSuite.
zig build dmcp_pkgs_all --summary none

step "[11/11] tracked generated artifacts unchanged"
mapfile -t generated_artifacts < <(bash .github/project/workflow-imported-root-paths.sh generated-artifacts)
git diff --exit-code -- "${generated_artifacts[@]}"

printf '\n\033[1;32mLOCAL GATE PASSED\033[0m — the Linux governance, host-parity and firmware-link lanes.\n'
printf 'Still CI-only: the Windows (LLP64) and macOS host lanes, and firmware PACKAGING/artifact publication.\n'

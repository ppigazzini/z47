#!/usr/bin/env bash
# check-build-paths.sh — every src/*.zig path literal named by the build
# system (build.zig pure_modules + build module roots) must resolve to a
# tracked file. Guards against a rename/edit that desyncs a build root from the
# owner it points at. Cheap; runnable as a local-gate / CI step.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
missing=0
# Scope to Zig build files and QUOTED path literals only, so stale mentions in
# C-oracle comments (e.g. a renamed owner named in a .c doc comment) are not
# mistaken for a live build root.
build_zig_files=(build.zig)
while IFS= read -r z; do build_zig_files+=("$z"); done < <(git ls-files 'build/**/*.zig')
while read -r p; do
  [ -n "$p" ] || continue
  git ls-files --error-unmatch "$p" >/dev/null 2>&1 || { echo "DANGLING build path: $p"; missing=1; }
done < <(grep -rhoE '"src/[a-z_]+/[a-z_0-9]+\.zig"' "${build_zig_files[@]}" | tr -d '"' | sort -u)
if [ "$missing" -ne 0 ]; then echo "FAIL: build references a missing owner path"; exit 1; fi
echo "build-path integrity OK"

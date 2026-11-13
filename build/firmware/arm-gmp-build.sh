#!/usr/bin/env bash
# Cross-build GMP 6.2.1 for a DMCP board, as build/firmware.zig's
# addArmGmpBuild runs it:
#
#   arm-gmp-build.sh <board> <gmp.h out> <libgmp.a out> <gmp-impl.h overlay>
#                    <gmp-mparam.h overlay> <imported GMP source dir>
#
# The source is the imported subprojects/gmp-6.2.1 when it is checked out, else
# a tarball whose SHA-256 is verified, fetched from the first mirror that
# answers. Upstream's two overlay headers are copied over a staged copy of the
# source, never in place, and the static library is built for the board's CPU.
set -euo pipefail

board="$1"
header_out="$2"
lib_out="$3"
impl_overlay="$4"
mparam_overlay="$5"
work_dir="$(cd "$(dirname "$lib_out")" && pwd)/gmp-work"
repo_source="$PWD/$6"
source_dir="$repo_source"
tarball="$work_dir/gmp-6.2.1.tar.bz2"
download_urls=(
  "https://gmplib.org/download/gmp/gmp-6.2.1.tar.bz2"
  "https://mirrors.kernel.org/gnu/gmp/gmp-6.2.1.tar.bz2"
  "https://ftp.acc.umu.se/mirror/gnu.org/gnu/gmp/gmp-6.2.1.tar.bz2"
  "https://ftpmirror.gnu.org/gmp/gmp-6.2.1.tar.bz2"
  "https://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.bz2"
)
extract_root="$work_dir/src"
build_dir="$work_dir/build-$board"
install_dir="$work_dir/install-$board"
jobs=$(getconf _NPROCESSORS_ONLN 2>/dev/null || nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
build_cc="$(command -v cc || command -v gcc || true)"
target_cc="arm-none-eabi-gcc --specs=nosys.specs"
for tool in arm-none-eabi-gcc arm-none-eabi-ar arm-none-eabi-ranlib make python3 tar; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "missing required firmware tool: $tool" >&2
    exit 1
  }
done
if [[ -z "$build_cc" ]]; then
  echo "missing required native build compiler: cc or gcc" >&2
  exit 1
fi
mkdir -p "$work_dir"
verify_gmp_hash() {
  python3 - "$tarball" <<'PY'
import hashlib
import pathlib
import sys
path = pathlib.Path(sys.argv[1])
expected = "eae9326beb4158c386e39a356818031bd28f3124cf915f8c5b1dc4c7a36b4d7c"
digest = hashlib.sha256(path.read_bytes()).hexdigest()
if digest != expected:
    raise SystemExit(f"gmp-6.2.1 sha256 mismatch: {digest}")
PY
}
download_gmp() {
  local partial="$tarball.part"
  local url
  rm -f "$partial"
  if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    echo "missing curl or wget to fetch gmp-6.2.1" >&2
    exit 1
  fi
  for url in "${download_urls[@]}"; do
    if command -v curl >/dev/null 2>&1; then
      if curl -L --fail --retry 3 --retry-delay 2 --retry-all-errors --connect-timeout 15 --max-time 120 --output "$partial" "$url" && [[ -s "$partial" ]]; then
        mv "$partial" "$tarball"
        return 0
      fi
    else
      if wget --tries=3 --timeout=15 -O "$partial" "$url" && [[ -s "$partial" ]]; then
        mv "$partial" "$tarball"
        return 0
      fi
    fi
    rm -f "$partial"
  done
  return 1
}
case "$board" in
  dmcp) cpu_flags=( -mthumb -march=armv7e-m -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16 ) ;;
  dmcp5) cpu_flags=( -mthumb -march=armv8-m.main+dsp -mcpu=cortex-m33 -mfloat-abi=hard -mfpu=fpv5-sp-d16 ) ;;
  *) echo "unsupported firmware board: $board" >&2; exit 1 ;;
esac
if [[ -d "$source_dir" ]]; then
  rm -rf "$extract_root"
  mkdir -p "$extract_root"
  cp -R "$source_dir" "$extract_root/gmp-6.2.1"
  source_dir="$extract_root/gmp-6.2.1"
else
  if [[ -f "$tarball" ]] && ! verify_gmp_hash; then
    rm -f "$tarball"
  fi
  if [[ ! -f "$tarball" ]]; then
    for attempt in 1 2 3 4 5; do
      if download_gmp && verify_gmp_hash; then
        break
      fi
      rm -f "$tarball"
      if [[ "$attempt" -eq 5 ]]; then
        echo "failed to fetch a verified gmp-6.2.1 tarball" >&2
        exit 1
      fi
    done
  fi
  rm -rf "$extract_root"
  mkdir -p "$extract_root"
  tar -xf "$tarball" -C "$extract_root"
  source_dir="$extract_root/gmp-6.2.1"
fi
cp "$impl_overlay" "$source_dir/gmp-impl.h"
cp "$mparam_overlay" "$source_dir/mpn/generic/gmp-mparam.h"
build_triplet="$("$source_dir/config.guess")"
rm -rf "$build_dir" "$install_dir"
mkdir -p "$build_dir" "$install_dir"
(
  cd "$build_dir" || exit 1
  CFLAGS="-Os -std=gnu17 -Wno-overflow ${cpu_flags[*]}" CC="$target_cc" AR=arm-none-eabi-ar RANLIB=arm-none-eabi-ranlib CC_FOR_BUILD="$build_cc" "$source_dir/configure" --build="$build_triplet" --host=arm-none-eabi --disable-assembly --disable-shared --disable-fft --disable-cxx --prefix="$install_dir"
  make -j"$jobs"
  make install
)
cp "$install_dir/include/gmp.h" "$header_out"
cp "$install_dir/lib/libgmp.a" "$lib_out"

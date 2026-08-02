#!/usr/bin/env bash
# Every `const <name>_t = <scalar>;` alias of a C type must have the same width in
# every owner that declares it.
#
# A single owner aliasing bool_t to u32 (C's bool_t is one byte) made every store
# through it a four-byte store into a one-byte global, writing three bytes past the
# end. Under ELF those bytes landed in alignment padding and nothing was observable;
# under COFF the linker had placed another global there and the write corrupted it,
# which cost eight days of a Windows-only failure that no test could see.
#
# Cross-owner agreement is checkable and this class is otherwise invisible: the
# defining owner is correct, the declaring owner is self-consistent, and only the
# combination is wrong.
set -euo pipefail

root="${1:-.}"
fail=0

mapfile -t rows < <(
  grep -rhoP '^const \K[A-Za-z_][A-Za-z0-9_]*_t = [A-Za-z_][A-Za-z0-9_]*(?=;)' \
    "$root/src" --include='*.zig' 2>/dev/null | sort -u
)

declare -A width_of=(
  [bool]=1 [u8]=1 [i8]=1 [u16]=2 [i16]=2 [u32]=4 [i32]=4
  [u64]=8 [i64]=8 [usize]=8 [isize]=8 [f32]=4 [f64]=8
  [c_int]=4 [c_uint]=4 [c_short]=2 [c_ushort]=2
)

declare -A seen_width seen_where
for row in "${rows[@]}"; do
  name="${row%% = *}"
  type="${row##* = }"
  w="${width_of[$type]:-}"
  [[ -n "$w" ]] || continue
  if [[ -n "${seen_width[$name]:-}" && "${seen_width[$name]}" != "$w" ]]; then
    echo "C TYPE ALIAS WIDTH CONFLICT: ${name} is ${seen_width[$name]} byte(s) as ${seen_where[$name]} and ${w} byte(s) as ${type}"
    echo "  A store through the wider alias writes past the end of the real object."
    grep -rn "^const ${name} = " "$root/src" --include='*.zig' | sed 's/^/    /'
    fail=1
  fi
  seen_width[$name]="$w"
  seen_where[$name]="$type"
done

if [[ "$fail" -ne 0 ]]; then
  echo
  echo "Align every owner's alias with the C definition's width."
  exit 1
fi

echo "check-c-type-alias-widths: OK (${#seen_width[@]} C type aliases, all widths agree across owners)"

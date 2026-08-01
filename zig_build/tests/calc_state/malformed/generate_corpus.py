#!/usr/bin/env python3
# M-SAFE-1 (REPORT-30): generate a malformed state-file corpus that stresses the
# restore parser's dimension/length math -- the OOB class upstream guards against
# in saveRestoreCalcState.c and z47 had never ported.
#
# NOTE ON STATUS: no build step consumes this directory yet. The driver is
# M-SAFE-7 (`zig build state_load_fuzz`), which will run every file here through
# the real doLoad under AddressSanitizer AND under a safe build, exactly as
# `zig build pgm_load_fuzz` does for the .p47 corpus. Until then these files are
# reproducers, kept because the M-SAFE-1 fix was verified against them by hand.
#
# Deterministic (no RNG) so CI is reproducible. Run from the repo root:
#   python3 zig_build/tests/calc_state/malformed/generate_corpus.py
import pathlib

outdir = pathlib.Path(__file__).resolve().parent
root = outdir.parents[3]
base = (root / "c47Test.sav").read_text().split("\n")


def patch_first_matrix(rows: int, cols: int, elements: int) -> list[str]:
    """Rewrite the first `Rema / 1 1` entry to `rows x cols` with `elements` values.

    c47Test.sav's NAMED_VARIABLES section holds `Mat_A / Rema / "1 1" / <value>`.
    Restoring a matrix register reads the dimension line, sizes the register from
    it, then reads rows*cols element lines.
    """
    out, i, patched = [], 0, False
    while i < len(base):
        line = base[i]
        if not patched and line == "Rema" and i + 1 < len(base) and base[i + 1] == "1 1":
            out.append("Rema")
            out.append(f"{rows} {cols}")
            out.extend(["0"] * elements)
            i += 3  # skip the original "1 1" and its single element
            patched = True
            continue
        out.append(line)
        i += 1
    assert patched, "no 'Rema / 1 1' entry in c47Test.sav to patch"
    return out


def write(name: str, lines: list[str]) -> None:
    p = outdir / name
    p.write_text("\n".join(lines))
    print(f"{p.relative_to(root)}: {p.stat().st_size} bytes")


# A register's data size is a u16 block count and a real34 element is 4 blocks,
# so 16383 elements is the largest that fits (16383*4 + 1 header == 65533) and
# 16384 is the first that does not (65537). 128x128 is that first refused shape,
# and it is a plausible matrix rather than a hostile one -- which is the point.
#
# Before the M-SAFE-1 fix this file reached
#   reallocateRegister(regist, dtReal34Matrix, @intCast(4 * rows * cols), tag)
# with a value of 65536 and panicked with "integer does not fit in destination
# type" on a safe host build; on the ReleaseSmall firmware the same cast truncates
# silently, under-allocates, and the element restore writes into the next block.
write(
    "matrix_dims_overflow_u16_blocks.sav",
    patch_first_matrix(128, 128, 128 * 128),
)

# The accepting side of the same boundary, and the only file here that is NOT
# malformed: 4x4095 is 16380 elements (16380*4 + 1 == 65521 blocks, inside the
# u16) with both dimensions inside the header's 12-bit fields. It must load
# unchanged before and after the fix -- a clamp that rejected it would be a
# behaviour change on a file upstream accepts. Note the two limits are separate:
# 3x5461 is also 16383 elements and inside the block count, yet 5461 exceeds the
# 12-bit matrixColumns field, so it is NOT a valid accepting case.
write(
    "matrix_dims_at_u16_block_limit.sav",
    patch_first_matrix(4, 4095, 4 * 4095),
)

# Dimensions whose PRODUCT overflows a u32 (65535*65535 == 0xFFFE0001, and the
# *4 wraps): the capacity test must be done in u64 or the comparison is against a
# number the file never claimed, and a wrapped-small product would be accepted.
write(
    "matrix_dims_product_overflows_u32.sav",
    patch_first_matrix(65535, 65535, 0),
)

# A row count that survives the product clamp yet exceeds the header's 12-bit
# matrixRows field (16383x1 == 16383 elements, and 16383 > 4095). Upstream's
# bitfield assignment truncates here, so the port must use @truncate rather than
# @intCast -- with @intCast this is illegal behaviour where upstream is defined.
write(
    "matrix_rows_exceed_header_12_bits.sav",
    patch_first_matrix(16383, 1, 16383),
)


# M-SAFE-4: the header version line, forged. Under the wrapping u32 arithmetic the
# state-side parser used before M-SAFE-4, these digits evaluate to exactly
# 10000025 -- inside the [10000000, 20000000] window parseSaveFileRevision accepts
# -- so a file could claim any version and thereby select the parse layout used
# for everything after it. With the saturating parse the value pins to
# 0xFFFFFFFF, the range check rejects it, and loadedVersion stays 0. Verified both
# ways through the real doLoad in a ReleaseSmall build.
def patch_version(line: str) -> list[str]:
    out = list(base)
    assert out[0] == "SAVE_FILE_REVISION", out[0]
    out[3] = line          # SAVE_FILE_REVISION / revision / calculator id / version
    return out


write("version_wrap_forges_valid.sav", patch_version("4304967321"))

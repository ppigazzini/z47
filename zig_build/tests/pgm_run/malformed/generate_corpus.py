#!/usr/bin/env python3
# M1 (REPORT-27 ANNEX B): generate a malformed .p47 corpus that stresses the
# program-load parser's header/length/offset math -- the OOB class upstream fixes
# on the state/program-load path (577 statefile overflow, decode-literal-base-oob).
# The corpus is run through the REAL load path (fnLoadProgram) under AddressSanitizer
# by `zig build pgm_load_fuzz`; a clean/graceful reject passes, an ASAN abort fails.
# Deterministic (no RNG) so CI is reproducible. Run from repo root:
#   python3 zig_build/tests/pgm_run/malformed/generate_corpus.py
import pathlib
import sys

root = pathlib.Path(__file__).resolve().parents[4]
outdir = pathlib.Path(__file__).resolve().parent

# res/ is an imported-upstream path, so it hangs off UPSTREAM_ROOT rather than the
# repo root. Reuse the gates' resolver instead of re-deriving the layout here.
sys.path.insert(0, str(root / ".github/project"))
from upstream_paths import upstream_path  # noqa: E402

real = upstream_path(root, "res/PROGRAMS/BinetV3.p47").read_bytes()


def w(name, data):
    (outdir / name).write_bytes(data)


MAGIC = b"PROGRAM_FILE_FORMAT\n0\nC47_program_file_version\n1\n"

# 1. empty file
w("empty.p47", b"")
# 2. one byte
w("one_byte.p47", b"\x00")
# 3. magic only, nothing after
w("magic_only.p47", MAGIC)
# 4. header truncated mid-magic
w("trunc_magic.p47", real[:12])
# 5. truncated right after the size field, no body
w("header_no_body.p47", MAGIC + b"PROGRAM\n169\n")
# 6. program size claims far more than the body provides (over-read)
w("size_overflow.p47", MAGIC + b"PROGRAM\n999999\n1\n2\n")
# 7. absurd / non-numeric size field
w("size_garbage.p47", MAGIC + b"PROGRAM\n999999999999999999999999\n")
w("size_negative.p47", MAGIC + b"PROGRAM\n-1\n")
w("size_nan.p47", MAGIC + b"PROGRAM\nNOTANUMBER\n")
# 8. valid header, body truncated to half
half = len(real) // 2
w("body_truncated.p47", real[:half])
# 9. every prefix truncation at 8-byte steps (classic "read past end" fuzz)
for cut in range(8, len(real), max(8, len(real) // 12)):
    w(f"trunc_{cut:04d}.p47", real[:cut])
# 10. valid header + high bytes / control bytes in the body (bad opcode/length bytes)
w("body_ff.p47", MAGIC + b"PROGRAM\n32\n" + b"\xff" * 32)
w("body_zeros.p47", MAGIC + b"PROGRAM\n32\n" + b"\x00" * 32)
# 11. all-0xFF and all-0x00 whole files
w("all_ff.p47", b"\xff" * 256)
w("all_00.p47", b"\x00" * 256)
# 12. real file with a single byte flipped in the size field region
mut = bytearray(real)
if len(mut) > 40:
    mut[38] = 0x39  # nudge a digit
w("size_digit_flip.p47", bytes(mut))

count = len(list(outdir.glob("*.p47")))
print(f"generated {count} malformed .p47 files in {outdir.relative_to(root)}")

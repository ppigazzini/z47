#!/usr/bin/env python3
# M-SAFE-1 (REPORT-30): generate a malformed state-file corpus that stresses the
# restore parser's dimension/length math -- the OOB class upstream guards against
# in saveRestoreCalcState.c and z47 had never ported.
#
# CONSUMED BY: `zig build state_load_fuzz` (M-SAFE-7), which drives every file
# here through the real doLoad and checks two things -- that the restore path did
# not crash, hang or trip a Zig safety check, and that it produced the outcome
# `expectations.txt` states. The second matters because the defect class this
# corpus exists for includes SILENT wrong-accepts, which no crash detector sees.
#
# Both the .sav files and expectations.txt are generated; the driver regenerates
# them if the directory is empty.
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


# Expected `loadedVersion` after the restore, per file. This is what turns the
# lane from "did not crash" into "behaved correctly": a defect that makes the
# parser SILENTLY ACCEPT something it should refuse -- the version forgery is
# exactly that shape -- never crashes, so crash-detection alone would miss its
# regression entirely. `None` means "no expectation, any value passes".
expectations: dict[str, int | None] = {}


def write(name: str, lines: list[str], expect_version: int | None = None) -> None:
    p = outdir / name
    p.write_text("\n".join(lines))
    expectations[name] = expect_version
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
    expect_version=10000025,  # header is untouched; only the matrix is malformed
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
    expect_version=10000025,  # the VALID file: it must keep loading normally
)

# Dimensions whose PRODUCT overflows a u32 (65535*65535 == 0xFFFE0001, and the
# *4 wraps): the capacity test must be done in u64 or the comparison is against a
# number the file never claimed, and a wrapped-small product would be accepted.
write(
    "matrix_dims_product_overflows_u32.sav",
    patch_first_matrix(65535, 65535, 0),
    expect_version=10000025,
)

# A row count that survives the product clamp yet exceeds the header's 12-bit
# matrixRows field (16383x1 == 16383 elements, and 16383 > 4095). Upstream's
# bitfield assignment truncates here, so the port must use @truncate rather than
# @intCast -- with @intCast this is illegal behaviour where upstream is defined.
write(
    "matrix_rows_exceed_header_12_bits.sav",
    patch_first_matrix(16383, 1, 16383),
    expect_version=10000025,
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
    out[3] = line  # SAVE_FILE_REVISION / revision / calculator id / version
    return out


# 0 is the assertion that matters here: the saturating parse must pin the value
# at u32-max so parseSaveFileRevision's range check REFUSES it. With the wrapping
# arithmetic this file yields 10000025 and is accepted -- silently, with no crash
# for a crash-detector to find.
write("version_wrap_forges_valid.sav", patch_version("4304967321"), expect_version=0)

# Emit the expectations the driver reads. Written last so it always matches the
# files just generated.
(outdir / "expectations.txt").write_text(
    "".join(f"{name} {'any' if v is None else v}\n" for name, v in sorted(expectations.items()))
)
print(f"{(outdir / 'expectations.txt').relative_to(root)}: {len(expectations)} expectations")


# =====================================================================
# M-SAFE-14: the corpus M-SAFE-7 specified and did not build.
#
# Everything above is a REPRODUCER of a bug already found and fixed -- useful as
# a regression guard, incapable of finding anything new. Everything below is the
# opposite: mutations chosen to reach parser states nobody has looked at. The
# sibling .p47 corpus was built this way and found three real bugs the afternoon
# it existed.
#
# No expectation is recorded for these (they pass `None` -> "any"). Stating one
# would mean asserting an answer nobody has established; the assertion for an
# exploratory case is "the parser did not crash, hang or trip a safety check",
# which the driver applies to every file regardless. Pin an expectation only once
# a case's correct outcome has actually been decided.
# =====================================================================

SECTION_COUNTS = {
    # section header -> the guard its count feeds (31fb6f755), for the record
    "GLOBAL_REGISTERS": "register loop",
    "NAMED_VARIABLES": "named-variable loop",
    "STATISTICAL_SUMS": "the 28 statistical sums",
    "KEYBOARD_ASSIGNMENTS": "kbd_usr[37]",
    "MYMENU": "userMenuItems[18]",
    "MYALPHA": "userAlphaItems[18]",
    "USER_MENUS": "userMenus[].menuItem[18]",
    "EQUATIONS": "the formula allocation",
    "PROGRAMS": "resizeProgramMemory",
}

# 0 and 1 probe the "section is not really there" and "one entry" edges; 0x7FFF
# is the i16 boundary the EQUATIONS loop cared about; 0xFFFF and 0xFFFFFFFF are
# the u16 and u32 ceilings a count field can express.
# 0x100000000 and above are the M-SAFE-10 width probes, and the corpus stopped one
# short of them for two milestones: 0xFFFFFFFF is the LARGEST value at which a
# 64-bit and a 32-bit `unsigned long` still agree. The divergence window opens at
# 2**32 -- there a host reads the true low bits and the firmware reads 0xFFFFFFFF --
# and closes again at 2**64, where both saturate to all-ones. A corpus that stops at
# 0xFFFFFFFF tests the boundary and never crosses it.
COUNT_MUTATIONS = (
    0,
    1,
    0x7FFF,
    0xFFFF,
    0xFFFFFFFF,
    0x100000000,
    0x10000000000000000,
)


def set_section_count(section: str, value: int) -> list[str]:
    """Replace the count line that follows `section`'s header."""
    out = list(base)
    for i, line in enumerate(out):
        if line == section and i + 1 < len(out):
            out[i + 1] = str(value)
            return out
    raise AssertionError(f"section {section} not found")


def _duplicate_header(section: str) -> list[str]:
    """Emit `section`'s header twice, so the second lands where data is expected."""
    out = list(base)
    i = out.index(section)
    return [*out[: i + 1], section, *out[i + 1 :]]


def _inject_blank_lines() -> list[str]:
    """Blank lines inside a section body. readLine() skips them, so this probes
    whether a section that runs out of data stops or walks into the next one."""
    out, i = list(base), base.index("NAMED_VARIABLES")
    return [*out[: i + 2], "", "", "", *out[i + 2 :]]


def _oversize_first_variable_name() -> list[str]:
    """A named-variable name far longer than the field that receives it."""
    out, i = list(base), base.index("NAMED_VARIABLES")
    out[i + 2] = "N" * 4000  # the name line of the first entry
    return out


for section in SECTION_COUNTS:
    for value in COUNT_MUTATIONS:
        write(f"count_{section.lower()}_{value}.sav", set_section_count(section, value))

# Truncation sweep. The cheapest generator of unexamined parser states, and the
# one class most likely to reach the end-of-section handling 31fb6f755 rewrote --
# every section must treat an empty read as end of file rather than parsing the
# next section's header as its own data.
TRUNCATION_POINTS = 12
for k in range(1, TRUNCATION_POINTS + 1):
    cut = len(base) * k // (TRUNCATION_POINTS + 1)
    write(f"truncated_at_{cut:05d}.sav", base[:cut])

# Structural mutations: the file's shape rather than its numbers.
write("no_terminator.sav", [ln for ln in base if ln != "END_OTHER_PARAM"])
write("duplicate_section_header.sav", _duplicate_header("NAMED_VARIABLES"))
write("blank_lines_injected.sav", _inject_blank_lines())
write("oversized_variable_name.sav", _oversize_first_variable_name())
write("empty_file.sav", [""])
write("header_only.sav", base[:4])

# Over-capacity sweep. Raising a count ALONE does not reach the guards that bound
# a section against its fixed-size array: the loop hits end of file first and
# takes the "the count was a lie" break instead. Reaching a capacity guard needs a
# count above the array's size WITH the entries to match, so the loop keeps
# feeding it real data all the way past the end. Measuring branch coverage of the
# 31fb6f755 guard commit is what showed this up: no count mutation above ever
# evaluated a capacity bound, because every one of them ran out of data first.
CAPACITY_SECTIONS = {
    "MYMENU": "userMenuItems[18]",
    "MYALPHA": "userAlphaItems[18]",
    "KEYBOARD_ASSIGNMENTS": "kbd_usr[37]",
}


def _overfill(section: str, extra: int) -> list[str]:
    """Raise `section`'s count by `extra` and append that many more entry lines.

    Every section here stores one line per entry, so the last entry serves as the
    filler: the content does not matter, only that the loop never runs dry."""
    out = list(base)
    i = out.index(section)
    count = int(out[i + 1])
    end = i + 2 + count
    out[i + 1] = str(count + extra)
    return out[:end] + [out[end - 1]] * extra + out[end:]


def _overfill_user_menu_items(extra: int) -> list[str]:
    """The same, for the per-menu item count nested inside USER_MENUS: each menu
    is a name line, then its own item count, then that many item lines."""
    out = list(base)
    name = out.index("USER_MENUS") + 2  # first menu's name line
    count = int(out[name + 1])
    end = name + 2 + count
    out[name + 1] = str(count + extra)
    return out[:end] + [out[end - 1]] * extra + out[end:]


for section in CAPACITY_SECTIONS:
    # +1 steps exactly one past the array; +64 walks well beyond it, so a guard
    # that is merely off by one and a guard that is missing look different.
    for extra in (1, 64):
        write(f"overfill_{section.lower()}_plus{extra}.sav", _overfill(section, extra))
for extra in (1, 64):
    write(f"overfill_user_menu_items_plus{extra}.sav", _overfill_user_menu_items(extra))


def _keyboard_arguments(n: int, key_of) -> list[str]:
    """Populate KEYBOARD_ARGUMENTS, which the base file leaves EMPTY (count 0).

    Its two bounds -- `i < userMenuItems.len` and `key < 37 * 6` -- guard indices
    the section itself supplies, and an empty section evaluates neither: they were
    the last of 31fb6f755's arms no corpus file reached. The entry format the
    parser wants is `<key> <argument name>`, the key read with toUint16 and the
    name taken after the space."""
    out = list(base)
    i = out.index("KEYBOARD_ARGUMENTS")
    out[i + 1] = str(n)
    return out[: i + 2] + [f"{key_of(k)} ARG{k}" for k in range(n)] + out[i + 2 :]


# 40 entries walks past userMenuItems[18] with keys still inside the userKeyLabel
# ceiling; the out-of-range variant holds every key ABOVE 37*6 so the refusing
# side of that bound is exercised too; 400 runs both far past their limits.
write("keyboard_arguments_40.sav", _keyboard_arguments(40, lambda k: k))
write("keyboard_arguments_40_key_over_ceiling.sav", _keyboard_arguments(40, lambda k: 37 * 6 + k))
write("keyboard_arguments_400.sav", _keyboard_arguments(400, lambda k: k))


def _set_value_after(key: str, value: str) -> list[str]:
    """Replace the value line that follows a `key`/value config pair."""
    out = list(base)
    out[out.index(key) + 1] = value
    return out


# Norm_Key_00.funcParam is `char funcParam[16]`, and the value a real calculator
# saves for an unassigned key is the 17-character sentinel "NoNormKeyParamDef" --
# one too long for the field, so the length guard that copies it is never TAKEN by
# any file derived from a genuine save. A value that fits exercises the copy; a
# far longer one exercises the refusal at a width the sentinel does not reach.
write("norm_key_funcparam_fits.sav", _set_value_after("Norm_Key_00.funcParam", "AB"))
write("norm_key_funcparam_overlong.sav", _set_value_after("Norm_Key_00.funcParam", "P" * 400))


def _unparseable_equation(text: str) -> list[str]:
    """Replace the single stored formula's text. The restore re-parses each
    formula, and only a formula that FAILS to parse takes the arm that clears
    lastErrorCode; every valid file takes the other one."""
    out = list(base)
    out[out.index("EQUATIONS") + 2] = text  # header, count, then the formula
    return out


write("equation_unparseable.sav", _unparseable_equation("((((+*/"))
write("equation_empty.sav", _unparseable_equation(""))


def _programs_field(offset: int, value: int) -> list[str]:
    """Rewrite one of the PROGRAMS section's pointer/offset lines.

    After the block count come, in order: currentStep's block pointer and its
    offset within that block, then firstFreeProgramByte's pointer and offset. The
    POINTERS go through toPcmemptr, which narrows under `@setRuntimeSafety(true)`
    and so traps on a value the pool cannot hold. The OFFSETS do not: upstream adds
    them to the pointer with no bound at all (`currentStep += toUint32(...)`), and
    the port reproduces that. These files are what tests whether that is reachable
    rather than merely alarming.
    """
    out = list(base)
    out[out.index("PROGRAMS") + offset] = str(value)
    return out


PROGRAMS_FIELDS = {
    2: "currentStep_block",
    3: "currentStep_offset",
    4: "firstFreeProgramByte_block",
    5: "firstFreeProgramByte_offset",
}
for _off, _name in PROGRAMS_FIELDS.items():
    for _v in (0xFFFF, 0xFFFFFFFF, 0x100000000):
        write(f"programs_{_name}_{_v:x}.sav", _programs_field(_off, _v))


def _version(v: int) -> list[str]:
    """Rewrite the header's version line (line 3, after `C47_save_file_00`)."""
    out = list(base)
    out[3] = str(v)
    return out


# Version boundaries. The restore path BRANCHES on loadedVersion all over --
# `restoreRegister` alone gates the config-descriptor decode on it -- and every
# file derived from a real save carries the current version, so those older arms
# were reached by nothing. M-SAFE-8's scan found a live out-of-bounds write behind
# one of them, which is what put this class in the corpus.
#
# Inside [10000000, 20000000] the header accepts the value, so the expectation is
# the version itself; outside it the header forces 0 (M-SAFE-4's range check).
for v in (10000000, 10000007, 10000008, 10000019, 10000020, 20000000):
    write(f"version_{v}.sav", _version(v), expect_version=v)
for v in (9999999, 20000001):
    write(f"version_{v}_out_of_range.sav", _version(v), expect_version=0)

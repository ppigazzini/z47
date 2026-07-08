#!/usr/bin/env python3
"""Item-table parity audit: the Zig indexOfItems mirror must match upstream items.c.

frontier_items.zig hand-mirrors the byte-exact data of the C-compiled
`indexOfItems[]` command table (param, catalog/softmenu name bytes, tamMinMax,
status) for every one of the ~2861 items. That table is C-DERIVED DATA maintained
by hand, so an upstream items.c change (new items, changed status/param/name)
silently desyncs it -- and because nothing gated it, an upstream pin advance that
grew LAST_ITEM crashed the testSuite with an indexOfItems[op] out-of-bounds before
this audit existed (see REPORT-27 "Pin-Advance Trial").

This audit closes that gap the same way the constant-parity audit does: it parses
the real upstream `indexOfItems[]` initializer, evaluates every row's data fields
by compiling a probe against the pinned headers with `zig cc` (func pointers are
replaced with 0 -- only the data fields are compared, so nothing needs to link),
and diffs the result against the Zig mirror. A mismatch or a row-count divergence
(vs LAST_ITEM+1) exits 1.

The ~31 build-target-varying rows (the OPTION_XFN_1000 XFN family, whose status/
func differ per target) are written in the Zig mirror as comptime expressions
rather than literals; they are reported and skipped (they carry no literal to
diff). Everything else is compared byte-exact.

Run standalone or via `zig build item-table-parity`. Requires zig + the upstream
headers under src/c47, dep/decNumberICU, the generated softmenu/constant headers
(produced by any prior `zig build`), and GTK3 cflags (pkg-config).
"""
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
ITEMS_C = ROOT / "src/c47/items.c"
ITEMS_H = ROOT / "src/c47/items.h"
ZIG_ITEMS = ROOT / "zig_src/frontier/frontier_items.zig"


def _split_top_level(text, sep=","):
    """Split on top-level `sep`, honoring (), {}, [] and string literals."""
    out, depth, cur, instr, esc = [], 0, "", False, False
    for ch in text:
        if instr:
            cur += ch
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == '"':
                instr = False
            continue
        if ch == '"':
            instr = True
            cur += ch
            continue
        if ch in "({[":
            depth += 1
        elif ch in ")}]":
            depth -= 1
        if ch == sep and depth == 0:
            out.append(cur)
            cur = ""
        else:
            cur += ch
    if cur.strip():
        out.append(cur)
    return out


def parse_c_rows(src):
    """Return (initializers-with-func-0, func-name-per-row) from items.c."""
    m = re.search(r"const item_t indexOfItems\[\] = \{(.*?)\n\};", src, re.S)
    body = "\n".join(re.sub(r"//.*$", "", ln) for ln in m.group(1).splitlines())
    rows = [re.sub(r"/\*.*?\*/", "", r, flags=re.S).strip() for r in _split_top_level(body)]
    rows = [r for r in rows if r]
    out, funcs = [], []
    for r in rows:
        if r.startswith("UNIT_CONV"):
            args = [a.strip() for a in _split_top_level(r[r.index("(") + 1 : r.rindex(")")])]
            unit, invert, cat, menu = args
            out.append(
                f"{{ 0, {unit} | {invert}, {cat}, {menu}, (0 << TAM_MAX_BITS) | 0, "
                "CAT_NONE | SLS_ENABLED | US_ENABLED | EIM_DISABLED | PTP_NONE | RESULT_IN_X }"
            )
            funcs.append("fnUnitConvert")
        else:
            inner = r[1 : r.rindex("}")]
            parts = _split_top_level(inner)
            funcs.append(parts[0].strip())
            out.append("{ 0, " + ",".join(parts[1:]).strip() + " }")
    return out, funcs


# items.c func names that legitimately do NOT map to plain ext_<name> in the Zig
# mirror. Keep tiny and always cite why (mirrors audit-constant-parity's
# KNOWN_DIVERGENCES discipline).
KNOWN_FUNC_MAP = {
    # An items.c macro that resolves to itemToBeCoded whenever USECURVES is #undef
    # (true on every z47 target), which the mirror binds directly.
    "conditionalPCURVE": "&itemToBeCoded",
    # z47 binds the underlying fnDumpMenus; the C row uses the fnDumpMenusWrapper
    # indirection. Same dump entry -- see the deferred fnmenudump-stale-port note.
    "fnDumpMenusWrapper": "ext_fnDumpMenus",
}


def expected_zig_func(c_func):
    """The Zig .func reference a given items.c function name maps to."""
    if c_func in KNOWN_FUNC_MAP:
        return KNOWN_FUNC_MAP[c_func]
    return "&itemToBeCoded" if c_func == "itemToBeCoded" else "ext_" + c_func


def extract_block(src_lines, start_pat, end_pat):
    lines = src_lines
    start = next(i for i, l in enumerate(lines) if re.search(start_pat, l))
    end = next(i for i in range(start, len(lines)) if re.search(end_pat, lines[i]))
    return "\n".join(lines[start : end + 1])


def build_probe_and_dump(zig, tmp):
    src = ITEMS_C.read_text(errors="ignore")
    src_lines = src.splitlines()
    rows, cfuncs = parse_c_rows(src)
    # items.c-local string macros (SEP/S3EM/...) and the OPTION_XFN_1000 S18_* block.
    localm = extract_block(src_lines, r"#define PER_\b", r"#define S3EM\b")
    s18 = extract_block(src_lines, r"#if defined\(OPTION_XFN_1000\)", r"#endif //OPTION_XFN_1000")
    probe = [
        "#include <stdio.h>",
        "#define PC_BUILD 1",
        "#define LINUX 1",
        "#define OS64BIT 1",
        '#include "c47.h"',
        localm,
        s18,
        "static const item_t rows[] = {",
    ]
    probe += ["  " + r + "," for r in rows]
    probe += [
        "};",
        "int main(void){",
        '  printf("COUNT %zu\\n", sizeof(rows)/sizeof(rows[0]));',
        "  for(size_t i=0;i<sizeof(rows)/sizeof(rows[0]);i++){",
        '    printf("%zu|%u|%u|%u|", i, rows[i].param, rows[i].tamMinMax, rows[i].status);',
        '    for(int b=0;b<16;b++) printf("%02x",(unsigned char)rows[i].itemCatalogName[b]); printf("|");',
        '    for(int b=0;b<16;b++) printf("%02x",(unsigned char)rows[i].itemSoftmenuName[b]); printf("\\n");',
        "  } return 0; }",
    ]
    (tmp / "probe.c").write_text("\n".join(probe))

    # Locate the generated softmenu/constant headers produced by a prior zig build.
    gen_dirs = set()
    for name in ("softmenuCatalogs.h", "constantPointers.h"):
        hit = next(ROOT.glob(f".zig-cache/**/{name}"), None) or next(ROOT.glob(f"src/generated/{name}"), None)
        if hit:
            gen_dirs.add(str(hit.parent))
    gtk = subprocess.run(["pkg-config", "--cflags", "gtk+-3.0"], capture_output=True, text=True)
    gtk_flags = gtk.stdout.split() if gtk.returncode == 0 else []

    inc = ["-I", str(ROOT / "dep/decNumberICU"), "-I", str(ROOT / "src/c47")]
    for d in gen_dirs:
        inc += ["-I", d]
    cc = [zig, "cc", "-DPC_BUILD=1", "-DLINUX=1", "-DOS64BIT=1", *gtk_flags, *inc]

    # Preflight: c47.h drags in gmp.h / gtk / glib, which are not on every runner's
    # default include path (e.g. Windows MSYS2, the Zig-master monitor). If a bare
    # `#include "c47.h"` will not compile, this host lacks the item-table probe's
    # build deps -- SKIP rather than mis-report an environment gap as table drift.
    # The audit still gates on the Linux host-parity lane where the deps exist, and
    # the table is platform-independent data so one lane is sufficient.
    (tmp / "preflight.c").write_text('#include "c47.h"\nint main(void){return 0;}\n')
    pf = subprocess.run(cc + [str(tmp / "preflight.c"), "-o", str(tmp / "pf")], capture_output=True, text=True)
    if pf.returncode != 0:
        miss = re.search(r"'([^']+\.h)' file not found", pf.stderr)
        print(f"SKIP: c47.h build deps unavailable on this host ({miss.group(1) if miss else 'header not found'})", file=sys.stderr)
        return "SKIP", len(rows), cfuncs

    comp = subprocess.run(cc + [str(tmp / "probe.c"), "-o", str(tmp / "probe")], capture_output=True, text=True)
    if comp.returncode != 0:
        print("item-table probe: compile failed\n" + comp.stderr[:2500], file=sys.stderr)
        return None, len(rows), cfuncs
    run = subprocess.run([str(tmp / "probe")], capture_output=True, text=True)
    cdump = {}
    for line in run.stdout.splitlines():
        if line.startswith("COUNT"):
            continue
        idx, param, tam, status, cat, sm = line.split("|")
        cdump[int(idx)] = (int(param), int(tam), int(status), cat, sm)
    return cdump, len(rows), cfuncs


def parse_zig_rows():
    lines = ZIG_ITEMS.read_text().splitlines()
    hdr = next(i for i, l in enumerate(lines) if "pub export const indexOfItems" in l)
    size = int(re.search(r"\[(\d+)\]item_t", lines[hdr]).group(1))
    rows, zfuncs, comptime = {}, {}, 0
    idx = 0
    for i in range(hdr + 1, len(lines)):
        s = lines[i].strip()
        if s == "};":
            break
        if not s.startswith(".{"):
            continue
        mp = re.search(r"\.param\s*=\s*(\d+)", s)
        mt = re.search(r"\.tamMinMax\s*=\s*(\d+)", s)
        ms = re.search(r"\.status\s*=\s*(\d+)", s)
        mc = re.search(r"\.itemCatalogName\s*=\s*\[16\]u8\{([^}]*)\}", s)
        msm = re.search(r"\.itemSoftmenuName\s*=\s*\[16\]u8\{([^}]*)\}", s)
        mf = re.search(r"\.func\s*=\s*(ext_[A-Za-z0-9_]+|&itemToBeCoded)", s)
        if mp and mt and ms and mc and msm and mf:
            hx = lambda g: "".join(x.lower() for x in re.findall(r"0x([0-9a-fA-F]{2})", g))
            rows[idx] = (int(mp.group(1)), int(mt.group(1)), int(ms.group(1)), hx(mc.group(1)), hx(msm.group(1)))
            zfuncs[idx] = mf.group(1)
        else:
            comptime += 1
        idx += 1
    return size, idx, rows, comptime, zfuncs


def main():
    zig = shutil.which("zig")
    if not zig:
        print("SKIP: zig not on PATH", file=sys.stderr)
        return 0

    last_item = int(re.search(r"#define\s+LAST_ITEM\s+(\d+)", ITEMS_H.read_text()).group(1))
    zsize, zcount, zrows, comptime, zfuncs = parse_zig_rows()

    print(f"item-table parity: LAST_ITEM={last_item}, Zig table size={zsize}, rows={zcount}")
    if zsize != last_item + 1:
        print(f"FAIL: Zig indexOfItems is [{zsize}] but items.h LAST_ITEM+1 == {last_item + 1}")
        return 1

    tmp = pathlib.Path(tempfile.mkdtemp())
    cdump, ccount, cfuncs = build_probe_and_dump(zig, tmp)
    if cdump == "SKIP":
        print("SKIP: item-table probe deps unavailable on this host; gated on the Linux lane")
        return 0
    if cdump is None:
        return 1
    if ccount != zcount:
        print(f"FAIL: C items.c has {ccount} rows but Zig mirror has {zcount}")
        return 1

    data_bad, func_bad = [], []
    for idx, z in zrows.items():
        c = cdump.get(idx)
        if c != z:
            data_bad.append((idx, c, z))
        want = expected_zig_func(cfuncs[idx])
        if zfuncs[idx] != want:
            func_bad.append((idx, cfuncs[idx], want, zfuncs[idx]))
    print(f"  compared {len(zrows)} literal rows (data + func), skipped {comptime} build-varying rows")
    fields = ["param", "tamMinMax", "status", "catName", "smName"]
    for idx, c, z in data_bad[:12]:
        diff = [(fields[k], c[k], z[k]) for k in range(5) if c[k] != z[k]]
        print(f"  DATA MISMATCH row {idx}: {diff}")
    for idx, cf, want, got in func_bad[:12]:
        print(f"  FUNC MISMATCH row {idx}: items.c={cf} -> expected {want}, mirror has {got}")
    if data_bad or func_bad:
        print(f"\nFAIL: {len(data_bad)} data + {len(func_bad)} func indexOfItems divergence(s) from items.c")
        return 1
    print("\nPASS: every literal indexOfItems row matches upstream items.c byte-for-byte (data + func)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

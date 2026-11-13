#!/usr/bin/env python3
"""Compare every Zig `extern fn` declaration with the Zig `export fn` it binds.

Owners reach each other through the C ABI: one owner exports a function and
others declare it `extern`. The compiler checks neither side against the other,
so a declaration can claim `void` where the definition returns `bool`, or `u16`
where it takes `u32`, and the program links and runs on whatever the registers
happen to hold. This check pairs every declaration in src/ and build/ with the
exported definition of the same name and compares arity, each parameter and the
return type after resolving type aliases, module qualifiers and C integer
spellings to one canonical form.

Usage:
    check-extern-signatures.py [--repo-root .]
    check-extern-signatures.py --self-test    # prove a planted mismatch fails
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

ROOTS = ("src", "build")
EXCLUDE_PREFIXES = ("build/tests/",)

C_INTEGERS = {
    "c_int": "i32",
    "c_uint": "u32",
    "c_short": "i16",
    "c_ushort": "u16",
    "c_longlong": "i64",
    "c_ulonglong": "u64",
}
PRIMITIVE = re.compile(
    r"^(?:[iu]\d+|f16|f32|f64|f80|f128|bool|void|noreturn|usize|isize|anyopaque|c_long|c_ulong|c_char)$"
)


@dataclass
class Sig:
    name: str
    params: list[str]
    ret: str
    path: str
    line: int
    text: str


def strip_comments(text: str) -> str:
    out = []
    for line in text.split("\n"):
        idx = line.find("//")
        while idx != -1:
            # keep `//` inside a string literal
            if line[:idx].count('"') % 2 == 0:
                line = line[:idx]
                break
            idx = line.find("//", idx + 2)
        out.append(line)
    return "\n".join(out)


def balanced(text: str, open_at: int) -> int:
    """Index just past the parenthesis that closes the one at `open_at`."""
    depth = 0
    for i in range(open_at, len(text)):
        ch = text[i]
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return i + 1
    raise ValueError("unbalanced parentheses")


def split_top(text: str) -> list[str]:
    parts, depth, cur = [], 0, []
    for ch in text:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == "," and depth == 0:
            parts.append("".join(cur))
            cur = []
        else:
            cur.append(ch)
    tail = "".join(cur).strip()
    if tail:
        parts.append(tail)
    return [p.strip() for p in parts if p.strip()]


def param_type(param: str) -> str:
    param = re.sub(r"^(?:noalias|comptime)\s+", "", param.strip())
    if param == "...":
        return "..."
    m = re.match(r"^[A-Za-z_]\w*\s*:\s*(.*)$", param, re.S)
    return (m.group(1) if m else param).strip()


TAIL = re.compile(
    r"^\s*(?:(?:callconv|linksection|align|addrspace)\s*\([^()]*(?:\([^()]*\)[^()]*)*\)\s*)*(.*)$",
    re.S,
)


def parse_after_params(rest: str) -> str:
    """The return type in the text between `)` and the `;` or `{` that ends it."""
    m = TAIL.match(rest)
    return (m.group(1) if m else rest).strip()


def collect(repo_root: Path):
    decls: list[Sig] = []
    defs: dict[str, list[Sig]] = {}
    aliases: dict[str, set[str]] = {}
    file_aliases: dict[str, dict[str, str]] = {}
    files = subprocess.run(
        ["git", "ls-files", *ROOTS], cwd=repo_root, capture_output=True, text=True, check=True
    ).stdout.split()
    alias_rx = re.compile(
        r"^\s*(?:pub\s+)?const\s+([A-Za-z_]\w*)\s*(?::\s*type\s*)?=\s*([^;=]+?)\s*;", re.M
    )
    fn_rx = re.compile(r"\b(extern|export)\s+fn\s+([A-Za-z_]\w*)\s*\(")
    at_extern_rx = re.compile(r"@extern\(\s*\*const\s+fn\s*\(")
    for rel in files:
        if not rel.endswith(".zig") or rel.startswith(EXCLUDE_PREFIXES):
            continue
        raw = (repo_root / rel).read_text(encoding="utf-8", errors="ignore")
        text = strip_comments(raw)
        local = file_aliases.setdefault(rel, {})
        for m in alias_rx.finditer(text):
            rhs = re.sub(r"\s+", " ", m.group(2))
            aliases.setdefault(m.group(1), set()).add(rhs)
            local.setdefault(m.group(1), rhs)
        for m in fn_rx.finditer(text):
            kind, name = m.group(1), m.group(2)
            start = m.end() - 1
            try:
                end = balanced(text, start)
            except ValueError:
                continue
            params = [param_type(p) for p in split_top(text[start + 1 : end - 1])]
            stop = len(text)
            for ch in ";{":
                j = text.find(ch, end)
                if j != -1:
                    stop = min(stop, j)
            ret = parse_after_params(text[end:stop])
            line = text.count("\n", 0, m.start()) + 1
            sig = Sig(
                name, params, ret, rel, line, re.sub(r"\s+", " ", text[m.start() : stop]).strip()
            )
            if kind == "extern":
                decls.append(sig)
            else:
                defs.setdefault(name, []).append(sig)
        for m in at_extern_rx.finditer(text):
            start = m.end() - 1
            try:
                end = balanced(text, start)
            except ValueError:
                continue
            params = [param_type(p) for p in split_top(text[start + 1 : end - 1])]
            comma = text.find(",", end)
            ret = parse_after_params(text[end:comma])
            nm = re.match(r'\s*\.\{\s*\.name\s*=\s*"([^"]+)"', text[comma + 1 :])
            if not nm:
                continue
            line = text.count("\n", 0, m.start()) + 1
            decls.append(
                Sig(
                    nm.group(1),
                    params,
                    ret,
                    rel,
                    line,
                    re.sub(r"\s+", " ", text[m.start() : comma]).strip(),
                )
            )
    return decls, defs, aliases, file_aliases


class Normalizer:
    def __init__(
        self, aliases: dict[str, set[str]], file_aliases: dict[str, dict[str, str]] | None = None
    ):
        self.aliases = aliases
        self.file_aliases = file_aliases or {}
        self.scope: dict[str, str] = {}

    def in_file(self, path: str) -> Normalizer:
        self.scope = self.file_aliases.get(path, {})
        return self

    def resolve_name(self, name: str, depth: int = 0) -> str:
        if depth > 8 or PRIMITIVE.match(name):
            return C_INTEGERS.get(name, name)
        if name in C_INTEGERS:
            return C_INTEGERS[name]
        local = self.scope.get(name)
        if local is not None:
            candidates, global_scope = [local], False
        else:
            candidates, global_scope = sorted(self.aliases.get(name, ())), True
        # An alias is spelled in many owners, some directly and some through
        # another module's binding; it resolves when every spelling agrees.
        resolved = set()
        for target in candidates:
            if re.match(r"^[A-Za-z_][\w.]*$", target):
                leaf = target.split(".")[-1]
                if leaf == name and global_scope:
                    continue  # another module's binding of the same name
                saved, self.scope = (
                    self.scope,
                    ({} if ("." in target or leaf == name) else self.scope),
                )
                try:
                    resolved.add(self.resolve_name(leaf, depth + 1))
                finally:
                    self.scope = saved
            elif re.match(r"^(?:\?|\*|\[)", target):
                resolved.add(self.norm(target, depth + 1))
            else:
                resolved.add(name)
        resolved.discard(name)
        return next(iter(resolved)) if len(resolved) == 1 else name

    def norm(self, t: str, depth: int = 0) -> str:
        t = re.sub(r"\s+", " ", t.strip())
        t = re.sub(r"\balign\(\d+\)\s*", "", t)
        optional = t.startswith("?")
        if optional:
            t = t[1:].strip()
        m = re.match(r"^(?:\[\*c\]|\[\*(?::0)?\]|\*|\[\*:0\])\s*(?:const\s+|volatile\s+)*(.*)$", t)
        if m:
            inner = m.group(1).strip()
            if inner.startswith("fn") or inner.startswith("const fn"):
                return "fnptr"
            pointee = self.norm(inner, depth + 1)
            if pointee in ("u8", "i8", "c_char"):
                pointee = "char"
            return f"ptr({pointee})"
        if t.startswith("fn") or t.startswith("const fn"):
            return "fnptr"
        if optional:
            return self.norm(t, depth)
        if "." in t:
            # A qualified name is another module's binding; resolve it globally.
            saved, self.scope = self.scope, {}
            try:
                return self.resolve_name(t.split(".")[-1], depth)
            finally:
                self.scope = saved
        return self.resolve_name(t, depth)


# C's bool is one byte holding 0 or 1, so the owners that bind it as u8 and the
# ones that bind it as bool agree on the ABI.
ONE_BYTE_BOOL = {"bool", "u8", "bool_t"}


def compatible(a: str, b: str) -> bool:
    if a == b or {a, b} <= ONE_BYTE_BOOL:
        return True
    pa, pb = a.startswith("ptr("), b.startswith("ptr(")
    if pa and pb:
        ia, ib = a[4:-1], b[4:-1]
        # void* and char* view any object. Two named pointees are one struct seen
        # through two modules' bindings. A primitive pointee is a width claim, so
        # it must match the other side exactly.
        if "anyopaque" in (ia, ib) or "char" in (ia, ib) or ia == ib:
            return True
        return not PRIMITIVE.match(ia) and not PRIMITIVE.match(ib)
    return "fnptr" in (a, b) and (pa or pb)


def mismatches(decls, defs, aliases, file_aliases=None):
    n = Normalizer(aliases, file_aliases)
    found = []
    for d in decls:
        targets = defs.get(d.name)
        if not targets:
            continue
        reasons_per_def = []
        for t in targets:
            reasons = []
            if "..." in d.params or "..." in t.params:
                continue
            if len(d.params) != len(t.params):
                reasons.append(f"arity {len(d.params)} vs {len(t.params)}")
            else:
                for i, (a, b) in enumerate(zip(d.params, t.params, strict=True)):
                    na, nb = n.in_file(d.path).norm(a), n.in_file(t.path).norm(b)
                    if not compatible(na, nb):
                        reasons.append(f"param {i + 1}: {a} ({na}) vs {b} ({nb})")
            ra, rb = n.in_file(d.path).norm(d.ret), n.in_file(t.path).norm(t.ret)
            if not compatible(ra, rb):
                reasons.append(f"return: {d.ret} ({ra}) vs {t.ret} ({rb})")
            reasons_per_def.append((t, reasons))
        if reasons_per_def and all(r for _, r in reasons_per_def):
            t, reasons = reasons_per_def[0]
            found.append((d, t, reasons))
    return found


# --- DMCP ROM trampolines ----------------------------------------------------
#
# A ROM call is `@ptrFromInt(LIBRARY_FN_BASE + N)` cast to a function type. The
# SDK's lft_ifc.h names the function at each offset and dmcp.h / ff_ifc.h give its
# prototype. A site passes when one of its own names (the enclosing function, the
# constant, the type alias or the offset constant) names that function, and its
# type matches the prototype.

SDK_DIRS = ("upstream/dep/DMCP_SDK/dmcp", "upstream/dep/DMCP5_SDK/dmcp")
C_TYPES = {
    "int": "i32",
    "unsigned": "u32",
    "uint": "u32",
    "unsigned int": "u32",
    "int32_t": "i32",
    "uint32_t": "u32",
    "int16_t": "i16",
    "uint16_t": "u16",
    "int8_t": "i8",
    "uint8_t": "u8",
    "char": "char",
    "void": "void",
    "bool": "bool",
    "FRESULT": "u32",
    "BYTE": "u8",
    "UINT": "u32",
    "TCHAR": "char",
    "FSIZE_t": "u32",
    "DWORD": "u32",
    "WORD": "u16",
}
ROM_SITE = re.compile(
    r"@ptrFromInt\(\s*(?:[\w.]*library_fn_base|LIBRARY_FN_BASE)\s*\+\s*(\w+)\s*\)"
)


def c_type(t: str) -> str:
    t = re.sub(r"\b(?:const|volatile|struct|enum)\b", " ", t)
    if re.match(r"^\s*\w+_fn_t\s*$", t):
        return "fnptr"
    stars = t.count("*")
    base = re.sub(r"\s+", " ", t.replace("*", " ")).strip()
    norm = C_TYPES.get(base, base)
    for _ in range(stars):
        norm = f"ptr({norm})"
    return norm


def c_param(p: str) -> str:
    p = p.strip()
    if p in ("", "void"):
        return ""
    m = re.match(r"^(.*?[\s*])([A-Za-z_]\w*)(\s*\[\s*\])?$", p)
    if m and m.group(1).strip() and m.group(1).strip() not in ("const", "unsigned"):
        t = m.group(1) + ("*" if m.group(3) else "")
    else:
        t = p
    return c_type(t)


def sdk_table(sdk: Path):
    offsets = {}
    for m in re.finditer(
        r"#define\s+(\w+)\s+\(\*\(typeof\(\w+\)\*\)\(LIBRARY_FN_BASE\+(\d+)\)\)",
        (sdk / "lft_ifc.h").read_text(errors="ignore"),
    ):
        offsets[int(m.group(2))] = m.group(1)
    protos = {}
    for h in sorted(sdk.glob("*.h")):
        text = re.sub(r"/\*.*?\*/", " ", h.read_text(errors="ignore"), flags=re.S)
        text = re.sub(r"//[^\n]*", "", text)
        for name in offsets.values():
            if name in protos:
                continue
            m = re.search(
                r"(?m)^\s*([A-Za-z_][\w\s\*]*?)\b" + re.escape(name) + r"\s*\(([^;{]*)\)\s*;", text
            )
            if m and "define" not in m.group(1):
                params = [c_param(x) for x in split_top(m.group(2))]
                protos[name] = ([x for x in params if x], c_type(m.group(1)))
    return offsets, protos


def squash(name: str) -> str:
    return re.sub(r"[^a-z0-9]", "", name.lower())


def rom_sites(repo_root: Path, file_aliases):
    tables = [sdk_table(repo_root / d) for d in SDK_DIRS]
    problems, checked = [], 0
    offsets, protos = tables[0]
    for d, (o, pr) in zip(SDK_DIRS[1:], tables[1:], strict=True):
        if o != offsets:
            problems.append(
                f"{d}/lft_ifc.h: its offsets differ from {SDK_DIRS[0]}'s; one table no longer fits both boards"
            )
        for name in sorted(set(pr) & set(protos)):
            if pr[name] != protos[name]:
                problems.append(f"{d}: {name} has a different prototype from {SDK_DIRS[0]}'s")
    if not offsets:
        return [*problems, f"{SDK_DIRS[0]}/lft_ifc.h: no LIBRARY_FN_BASE entries read"], 0
    files = subprocess.run(
        ["git", "ls-files", *ROOTS], cwd=repo_root, capture_output=True, text=True, check=True
    ).stdout.split()
    for rel in files:
        if not rel.endswith(".zig") or rel.startswith(EXCLUDE_PREFIXES):
            continue
        text = strip_comments((repo_root / rel).read_text(encoding="utf-8", errors="ignore"))
        p, c = rom_in_text(rel, text, offsets, protos, file_aliases)
        problems += p
        checked += c
    return problems, checked


def rom_in_text(rel: str, text: str, offsets, protos, file_aliases):
    n = Normalizer({}, file_aliases)
    problems, checked = [], 0
    consts = {
        m.group(1): int(m.group(2))
        for m in re.finditer(r"const\s+(\w+)\s*:\s*usize\s*=\s*(\d+)\s*;", text)
    }
    fn_types = {}
    for m in re.finditer(r"const\s+(\w+)\s*=\s*(\*const\s+fn\s*\()", text):
        end = balanced(text, m.end(2) - 1)
        stop = text.find(";", end)
        fn_types[m.group(1)] = text[m.start(2) : stop]

    def enclosing_fn(pos: int):
        found = [f for f in re.finditer(r"\bfn\s+(\w+)\s*\(", text[:pos])]
        if not found:
            return None, []
        f = found[-1]
        end = balanced(text, f.end() - 1)
        return f.group(1), [
            x.split(":")[0].replace("comptime", "").strip()
            for x in split_top(text[f.end() : end - 1])
        ]

    def statement_decl(pos: int):
        start = max(text.rfind(";", 0, pos), text.rfind("{", 0, pos), text.rfind("}", 0, pos)) + 1
        return re.search(r"(?:const|var)\s+(\w+)\s*(?::\s*(.+?))?\s*=", text[start:pos], re.S)

    sites = []  # (pos, offset token, names, type text)
    for m in ROM_SITE.finditer(text):
        off_tok = m.group(1)
        fn_name, fn_params = enclosing_fn(m.start())
        decl = statement_decl(m.start())
        type_text = (decl.group(2) or "").strip() if decl else ""
        if not off_tok.isdigit() and off_tok in fn_params:
            # A helper taking the offset: judge every call to it instead.
            idx = fn_params.index(off_tok)
            type_param = next((i for i, x in enumerate(fn_params) if x == "T"), None)
            for c in re.finditer(r"\b" + re.escape(fn_name) + r"\s*\(", text):
                if text[: c.start()].rstrip().endswith("fn"):
                    continue
                args = split_top(text[c.end() : balanced(text, c.end() - 1) - 1])
                if len(args) <= idx:
                    continue
                caller, _ = enclosing_fn(c.start())
                cdecl = statement_decl(c.start())
                t = args[type_param] if type_param is not None else type_text
                names = [x for x in (caller, cdecl.group(1) if cdecl else None) if x]
                sites.append((c.start(), args[idx], names, t))
            continue
        names = [x for x in (fn_name, decl.group(1) if decl else None) if x]
        if not off_tok.isdigit():
            names.append(off_tok)
        sites.append((m.start(), off_tok, names, type_text))

    for pos, off_tok, names, type_text in sites:
        offset = int(off_tok) if off_tok.isdigit() else consts.get(off_tok)
        line = text.count("\n", 0, pos) + 1
        where = f"{rel}:{line}"
        if offset is None or offset not in offsets:
            problems.append(f"{where}: offset {off_tok} is not an lft_ifc.h entry")
            continue
        checked += 1
        sdk_name = offsets[offset]
        if type_text and re.match(r"^\w+$", type_text):
            names.append(type_text)
            type_text = fn_types.get(type_text, "")
        want = squash(sdk_name)
        if not any(want in squash(x) for x in names):
            problems.append(
                f"{where}: calls {sdk_name} (+{offset}) but is named {', '.join(names) or 'nothing'}"
            )
        proto = protos.get(sdk_name)
        fm = re.match(r"^\*const\s+fn\s*\(", type_text)
        if not proto or not fm:
            continue
        end = balanced(type_text, fm.end() - 1)
        zparams = [param_type(x) for x in split_top(type_text[fm.end() : end - 1])]
        zret = parse_after_params(type_text[end:])
        n.in_file(rel)
        zp = [n.norm(x) for x in zparams]
        zr = n.norm(zret)
        cp, cr = proto
        if len(zp) != len(cp):
            problems.append(
                f"{where}: {sdk_name} takes {len(cp)} parameters in the SDK, {len(zp)} here"
            )
            continue
        for i, (a, b) in enumerate(zip(zp, cp, strict=True)):
            if not (compatible(a, b) or (a.startswith("ptr(") and b.startswith("ptr("))):
                problems.append(
                    f"{where}: {sdk_name} parameter {i + 1} is {b} in the SDK, {a} here"
                )
        if not compatible(zr, cr) and not (zr.startswith("ptr(") and cr.startswith("ptr(")):
            problems.append(f"{where}: {sdk_name} returns {cr} in the SDK, {zr} here")
    return problems, checked


def rom_self_test() -> bool:
    offsets = {360: "date_str", 380: "key_empty"}
    protos = {"date_str": (["ptr(char)", "ptr(char)"], "ptr(char)"), "key_empty": ([], "i32")}
    body = "fn keyEmpty() c_int {{ const f: *const fn () callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + {}); return f(); }}"
    good, _ = rom_in_text("t.zig", body.format(380), offsets, protos, {})
    bad, _ = rom_in_text("t.zig", body.format(360), offsets, protos, {})
    wrong_ret, _ = rom_in_text(
        "t.zig",
        body.format(380).replace("c_int =", "void =").replace("c_int {", "void {"),
        offsets,
        protos,
        {},
    )
    return not good and bool(bad) and bool(wrong_ret)


def self_test() -> int:
    decl = Sig("f", ["u16"], "void", "a.zig", 1, "")
    good = Sig("f", ["u16"], "void", "b.zig", 1, "")
    bad_ret = Sig("f", ["u16"], "bool", "b.zig", 1, "")
    bad_width = Sig("f", ["u32"], "void", "b.zig", 1, "")
    ok = not mismatches([decl], {"f": [good]}, {})
    caught_ret = bool(mismatches([decl], {"f": [bad_ret]}, {}))
    caught_width = bool(mismatches([decl], {"f": [bad_width]}, {}))
    aliased = not mismatches(
        [Sig("f", ["calcRegister_t"], "void", "a", 1, "")],
        {"f": [Sig("f", ["i16"], "void", "b", 1, "")]},
        {"calcRegister_t": {"i16"}},
    )
    rom = rom_self_test()
    if ok and caught_ret and caught_width and aliased and rom:
        print(
            "self-test PASS: a void/bool return and a u16/u32 parameter are caught; an alias"
            " resolves; a ROM call at date_str's offset named key_empty is caught"
        )
        return 0
    print(
        f"self-test FAIL: ok={ok} ret={caught_ret} width={caught_width} alias={aliased} rom={rom}"
    )
    return 1


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        return self_test()
    repo_root = Path(args.repo_root).resolve()
    decls, defs, aliases, file_aliases = collect(repo_root)
    found = mismatches(decls, defs, aliases, file_aliases)
    paired = sum(1 for d in decls if d.name in defs)
    for d, t, reasons in found:
        print(f"{d.path}:{d.line}: {d.name} disagrees with {t.path}:{t.line}")
        for r in reasons:
            print(f"    {r}")
    print(
        f"check-extern-signatures: {len(decls)} declarations, {paired} bound to a Zig definition, {len(found)} disagree"
    )
    rom_problems, rom_checked = rom_sites(repo_root, file_aliases)
    for p in rom_problems:
        print(p)
    print(
        f"check-extern-signatures: {rom_checked} DMCP ROM calls checked against lft_ifc.h, {len(rom_problems)} problems"
    )
    if paired == 0 or rom_checked == 0:
        print("FAIL: a scan paired nothing, so it measured nothing")
        return 1
    return 1 if found or rom_problems else 0


if __name__ == "__main__":
    sys.exit(main())

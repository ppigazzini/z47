#!/usr/bin/env python3
"""move-owners.py — move z47 owner .zig files (into a subdirectory, optionally
prefix-stripping) and rewrite EVERY @import to the correct relative path from
each importer's new location, plus the build-system path literals.

Cross-*module* moves are rejected: Zig forbids @import of a file outside the
module root dir (verified), so a file may only move within its module's root
subtree (e.g. within zig_src/frontier/). This tool enforces that.

Usage:
  move-owners.py <mapfile>            # dry-run: print every rewrite, touch nothing
  move-owners.py <mapfile> --apply    # git mv + rewrite imports + build literals
  move-owners.py --verify             # assert every @import resolves to a real file
mapfile: TAB-separated  old_path <TAB> new_path  (both repo-relative)
"""
import os,sys,re,subprocess,collections

ROOT=subprocess.check_output(['git','rev-parse','--show-toplevel'],text=True).strip()
os.chdir(ROOT)
IMP=re.compile(r'@import\("([^"]+\.zig)"\)')
REFDIRS=['zig_src','zig_build']
# Path-reference surfaces beyond the build graph: the ledger, the extern/@cImport
# boundary allowlist, and any .github/project audit file that names owner paths.
REFFILES=['build.zig','.github/project/upstream-port-ledger.tsv',
          '.github/project/zig-c-boundaries.txt']

def tracked_zig():
    return subprocess.check_output(['git','ls-files','zig_src/**/*.zig','zig_build/**/*.zig'],text=True).split()
def module_of(p):        # top-level dir under zig_src = the module bucket (frontier, mathematics, ...)
    parts=p.split('/'); return parts[1] if len(parts)>2 and parts[0]=='zig_src' else parts[0]

def load_map(mf):
    m={}
    for line in open(mf):
        line=line.rstrip('\n')
        if not line or line.startswith('#'): continue
        old,new=line.split('\t')
        if module_of(old)!=module_of(new):
            sys.exit(f"REJECT cross-module move (Zig forbids outside-module @import): {old} -> {new}")
        m[os.path.normpath(old)]=os.path.normpath(new)
    return m

def resolve(importer,imp):        # abs (repo-rel) file an @import points at
    return os.path.normpath(os.path.join(os.path.dirname(importer),imp))

def main():
    args=[a for a in sys.argv[1:] if not a.startswith('--')]
    apply='--apply' in sys.argv; verify='--verify' in sys.argv
    if verify:
        bad=0
        for f in tracked_zig():
            for imp in IMP.findall(open(f).read()):
                if not os.path.exists(resolve(f,imp)): print(f"DANGLING: {f} -> {imp}"); bad=1
        print("verify OK" if not bad else "verify FAILED"); sys.exit(bad)
    mp=load_map(args[0])
    # snapshot every import edge BEFORE moving
    edges=[]  # (importer, import_str, target_abs)
    for f in tracked_zig():
        for imp in IMP.findall(open(f).read()):
            edges.append((f,imp,resolve(f,imp)))
    # plan rewrites
    rewrites=collections.defaultdict(list)   # file(new loc) -> [(old_import_str,new_import_str)]
    for f,imp,tgt in edges:
        fnew=mp.get(f,f); tnew=mp.get(tgt,tgt)
        if f not in mp and tgt not in mp: continue
        newimp=os.path.relpath(tnew,os.path.dirname(fnew))
        if newimp!=imp: rewrites[fnew].append((imp,newimp))
    # report
    print(f"# {len(mp)} moves, {sum(len(v) for v in rewrites.values())} import rewrites across {len(rewrites)} files")
    for old,new in sorted(mp.items()): print(f"  MOVE {old} -> {new}")
    for fn in sorted(rewrites):
        for a,b in rewrites[fn]: print(f"  IMPORT [{fn}]  {a} -> {b}")
    if not apply:
        print("\n(dry-run; pass --apply to execute)"); return
    # apply: git mv first
    for old,new in mp.items():
        os.makedirs(os.path.dirname(new),exist_ok=True)
        subprocess.check_call(['git','mv',old,new])
    # rewrite imports (keyed by the file's NEW path)
    for fn,pairs in rewrites.items():
        s=open(fn).read()
        for a,b in pairs: s=s.replace(f'@import("{a}")',f'@import("{b}")')
        open(fn,'w').write(s)
    # build-system path literals
    reff=[x for x in REFFILES if os.path.exists(x)]
    for d in REFDIRS: reff+=subprocess.check_output(['git','ls-files',f'{d}/**/*.zig'],text=True).split()
    for fn in set(reff):
        s=open(fn).read(); orig=s
        for old,new in mp.items(): s=s.replace(old,new)
        if s!=orig: open(fn,'w').write(s)
    print(f"applied {len(mp)} moves")

if __name__=='__main__': main()

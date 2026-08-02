// SPDX-License-Identifier: GPL-3.0-only
//
// SanitizerCoverage trace-pc-guard runtime for Zig-owner coverage (Annex A0).
//
// Linked into a host harness built with `sanitize_coverage_trace_pc_guard`
// (Zig 0.16's `-fsanitize-coverage-trace-pc-guard`, LLVM backend). The compiler
// inserts a call to __sanitizer_cov_trace_pc_guard at every instrumented edge of
// the Zig owners (and compiled-in C); this runtime records the return address of
// each FIRST-hit edge and writes the unique PC set to cov_pcs.txt at exit.
// report-zig-coverage.sh then symbolizes those PCs (llvm-symbolizer) and reports
// per-owner covered source lines -- the coverage measurement kcov would give, but
// kcov is not available in this environment and Zig has no -fprofile-instr path.
//
// This is measurement-only: it does not change behavior and is compiled only into
// the dedicated `coverage` harness, never into a product or normal-test binary.

#ifndef _GNU_SOURCE
#define _GNU_SOURCE // for dladdr / Dl_info
#endif
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

// The ubsan runtime references this sancov thread-local; provide it.
__thread unsigned long __sancov_lowest_stack;

#define COV_PC_CAP (1u << 22)
static uintptr_t cov_pcs[COV_PC_CAP];
static size_t cov_n;
static size_t cov_dropped;

// The harness is a PIE: a runtime return address is load_base + static_vaddr,
// but llvm-symbolizer --obj expects the STATIC vaddr. dladdr on a symbol in this
// same binary yields its load base, so we record pc - base.
static uintptr_t cov_base(void) {
  static uintptr_t base;
  if (!base) {
    Dl_info info;
    if (dladdr((void *)&__sancov_lowest_stack, &info) && info.dli_fbase) {
      base = (uintptr_t)info.dli_fbase;
    }
  }
  return base;
}

void __sanitizer_cov_trace_pc_guard_init(uint32_t *start, uint32_t *stop) {
  static uint32_t next_id;
  for (uint32_t *p = start; p < stop; ++p) {
    if (*p == 0) *p = ++next_id; // give every guard a non-zero id once
  }
}

static void cov_dump(void) {
  // The harness runs with the imported root as its CWD, because the ported
  // config.zig opens res/testPgms/testPgms.bin CWD-relative just as upstream's
  // config.c does. Writing cov_pcs.txt relative to that CWD would strand the
  // artefact inside the imported tree, where neither report-zig-coverage.sh nor
  // check-coverage-ratchet.sh looks for it. The build passes an absolute path;
  // the bare name is kept as the default so running the binary by hand still
  // drops the file beside the invocation.
  const char *out = getenv("Z47_COV_PCS_PATH");
  if (out == NULL || *out == '\0') out = "cov_pcs.txt";
  FILE *f = fopen(out, "w");
  if (!f) return;
  for (size_t i = 0; i < cov_n; ++i) {
    fprintf(f, "0x%lx\n", (unsigned long)cov_pcs[i]);
  }
  fclose(f);
  fprintf(stderr, "[coverage] recorded %zu unique edges (%zu dropped over cap)\n",
          cov_n, cov_dropped);
}

void __sanitizer_cov_trace_pc_guard(uint32_t *guard) {
  if (!*guard) return; // already counted this edge
  *guard = 0;          // first hit only -> the set of executed edges
  if (cov_n == 0) atexit(cov_dump);
  if (cov_n < COV_PC_CAP) {
    cov_pcs[cov_n++] = (uintptr_t)__builtin_return_address(0) - cov_base();
  } else {
    cov_dropped++;
  }
}

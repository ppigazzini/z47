// SPDX-License-Identifier: GPL-3.0-only
//
// Per-case resource budgets for a parity harness: a byte ceiling on GMP and a
// wall-clock ceiling on a single case.
//
// WHY THIS EXISTS. A differential runs both implementations of the thing it is
// measuring, so a wrapper that computes without a bound is not reported by the
// lane -- it is EXECUTED by the lane, twice. Two shapes reach that state from an
// ordinary fixture:
//
//   unbounded ALLOCATION   10^X and 2^X with a long integer X square the base
//                          once per bit of the exponent. Guarded, that stops at
//                          the calculator's long integer width; unguarded, the
//                          operand doubles every pass and the host runs out of
//                          memory long before the loop runs out of exponent.
//
//   unbounded ITERATION    WP34S_ComplexLambertW is a `while(1)` whose only exit
//                          is a convergence test, and an infinity or a NaN never
//                          satisfies it. It allocates nothing, so a byte ceiling
//                          cannot see it.
//
// Neither is hypothetical and neither is caught by the other's budget, which is
// why there are two of them.
//
// WHAT A BREACH MEANS. Not "this case is slow" or "this machine is small": the
// budgets below are orders of magnitude above what any case in a converted lane
// legitimately needs, so a breach is a wrapper computing without a bound. The
// process prints the case and stops. It does NOT return an error and continue --
// GMP's allocation function is not allowed to fail, so there is nothing to
// unwind to.
//
// THE BYTE CEILING IS THE PORTABLE HALF. The wall-clock half needs POSIX signals
// and compiles to nothing on Windows, where a hung case still hangs. Say so
// rather than letting the Windows lane read as equally protected.
//
// THE BYTE CEILING ALSO NEEDS NOTHING FROM THE LANE. Installing it is the whole
// wiring. The wall-clock budget is armed by harnessBudgetSetCase, so a lane that
// does not name its cases gets the ceiling and not the clock -- and its breach
// message says which lane rather than which case, because that is all it knows.

#ifndef HARNESS_RESOURCE_BUDGET_H
#define HARNESS_RESOURCE_BUDGET_H

#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(_WIN32)
  #define HARNESS_HAS_CASE_TIME_BUDGET 0
#else
  #define HARNESS_HAS_CASE_TIME_BUDGET 1
  #include <signal.h>
  #include <unistd.h>
#endif

// The calculator's own long integer ceiling is MAX_LONG_INTEGER_SIZE_IN_BITS --
// 3328 bits, 416 bytes -- and every other GMP value in a case is a temporary of
// that order. 4 MiB is four orders of magnitude of headroom, so it discriminates
// "unbounded" from "large" rather than "large" from "typical". The peak is
// printed at the end of every run, so the real distance to this number is a
// measurement rather than an assumption.
#ifndef HARNESS_GMP_BUDGET_IN_BYTES
  #define HARNESS_GMP_BUDGET_IN_BYTES (4u * 1024u * 1024u)
#endif

// Long enough that no currently-green case is near it, short enough that a
// non-terminating case is a coffee break and not a lost afternoon.
#ifndef HARNESS_CASE_BUDGET_IN_SECONDS
  #define HARNESS_CASE_BUDGET_IN_SECONDS 60u
#endif

// c43 keeps this running total for its own leak reporting; the allocator below
// maintains it exactly as `allocGmp` does, so installing a budget does not blind
// a lane that reads it.
extern size_t gmpMemInBytes;

static const char *harnessBudgetLane = "harness";
static char        harnessBudgetCase[192] = "<this lane does not name its cases>";
static size_t      harnessGmpLiveBytes;
static size_t      harnessGmpPeakBytes;

// The case name is the only thing that makes a breach actionable, so it is set by
// the harness immediately before each side of each case runs. It is COPIED: a
// caller that composes the name in a local buffer would otherwise leave this
// pointing into a dead frame by the time anything reads it.
static inline void harnessBudgetSetCase(const char *caseName) {
  snprintf(harnessBudgetCase, sizeof(harnessBudgetCase), "%s", caseName);
#if HARNESS_HAS_CASE_TIME_BUDGET
  alarm(HARNESS_CASE_BUDGET_IN_SECONDS);
#endif
}

static inline void harnessBudgetCaseFinished(void) {
#if HARNESS_HAS_CASE_TIME_BUDGET
  alarm(0);
#endif
}

static void harnessBudgetStop(const char *what, size_t number, const char *unit) {
  printf("%s: BUDGET EXCEEDED in case %s: %s %zu %s\n",
         harnessBudgetLane, harnessBudgetCase, what, number, unit);
  printf("%s: one side of this case computes without a bound; the lane stopped rather than exhaust the host\n",
         harnessBudgetLane);
  fflush(stdout);
  _exit(1);
}

static void harnessGmpAccountAllocation(size_t sizeInBytes) {
  harnessGmpLiveBytes += sizeInBytes;
  gmpMemInBytes       += sizeInBytes;
  if(harnessGmpLiveBytes > harnessGmpPeakBytes) {
    harnessGmpPeakBytes = harnessGmpLiveBytes;
  }
  if(harnessGmpLiveBytes > HARNESS_GMP_BUDGET_IN_BYTES) {
    harnessBudgetStop("GMP holds", harnessGmpLiveBytes, "bytes");
  }
}

static void *harnessAllocGmp(size_t sizeInBytes) {
  harnessGmpAccountAllocation(sizeInBytes);
  return malloc(sizeInBytes);
}

static void *harnessReallocGmp(void *pcMemPtr, size_t oldSizeInBytes, size_t newSizeInBytes) {
  harnessGmpLiveBytes -= oldSizeInBytes;
  gmpMemInBytes       -= oldSizeInBytes;
  harnessGmpAccountAllocation(newSizeInBytes);
  return realloc(pcMemPtr, newSizeInBytes);
}

static void harnessFreeGmp(void *pcMemPtr, size_t sizeInBytes) {
  harnessGmpLiveBytes -= sizeInBytes;
  gmpMemInBytes       -= sizeInBytes;
  free(pcMemPtr);
}

#if HARNESS_HAS_CASE_TIME_BUDGET
static void harnessBudgetAlarm(int signalNumber) {
  (void)signalNumber;
  harnessBudgetStop("no result after", HARNESS_CASE_BUDGET_IN_SECONDS, "seconds");
}
#endif

// Printed by every lane that installs a budget, from an atexit hook rather than
// from each lane's own closing line: the peak states the real headroom, and a
// non-zero residual is GMP memory the cases did not give back. A breach exits
// through _exit and so prints its own diagnosis and not this.
static void harnessReportResourceUse(void) {
  printf("%s: GMP peak %zu bytes of %u budgeted", harnessBudgetLane,
         harnessGmpPeakBytes, (unsigned)HARNESS_GMP_BUDGET_IN_BYTES);
  if(harnessGmpLiveBytes != 0) {
    printf(", %zu bytes still held at exit", harnessGmpLiveBytes);
  }
#if !HARNESS_HAS_CASE_TIME_BUDGET
  printf("; no per-case time budget on this platform");
#endif
  printf("\n");
}

// gmp.h spells this as a macro over the __gmp_ symbol, and a harness that has not
// included gmp.h still needs to install the trio.
extern void __gmp_set_memory_functions(void *(*alloc)(size_t),
                                       void *(*realloc)(void *, size_t, size_t),
                                       void (*free)(void *, size_t));

static void harnessInstallResourceBudget(const char *laneName) {
  harnessBudgetLane = laneName;
  __gmp_set_memory_functions(harnessAllocGmp, harnessReallocGmp, harnessFreeGmp);
  atexit(harnessReportResourceUse);
#if HARNESS_HAS_CASE_TIME_BUDGET
  signal(SIGALRM, harnessBudgetAlarm);
#endif
}

#endif // HARNESS_RESOURCE_BUDGET_H

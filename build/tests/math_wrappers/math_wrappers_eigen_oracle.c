// SPDX-License-Identifier: GPL-3.0-only
//
// REPORT-23 test-oracle-upgrade: a worker-level golden harness for the eigen
// engine in src/mathematics/math_matrix_eigen_owned.zig. testSuite
// matrix.txt only exercises the composed fnEigenvalues through registers; this
// pins the individual numeric workers against math-truth reference values so a
// worker regression cannot hide behind the composed result.
//
// The upstream C eigen workers (mathematics/matrix.c) are file-static, so this
// is a golden (math-truth) oracle, not a Zig-vs-C parity oracle: it drives the
// exported Zig workers on fixed input matrices and compares the real_t outputs
// against hand-verified reference eigenvalues.

#include "../../../upstream/src/c47/c47.h"

// Exported Zig workers under test (math_matrix_eigen_owned.zig). The matrices
// are interleaved-complex, row-major: element (i,j) real at [(i*size+j)*2],
// imag at [(i*size+j)*2 + 1].
void calculateEigenvalues22(const real_t *mat, uint16_t size, real_t *t1r, real_t *t1i, real_t *t2r, real_t *t2i, bool is_real_symmetric, realContext_t *realContext);
void calculateEigenvalues33(const real_t *mat, uint16_t size, real_t *t1r, real_t *t1i, real_t *t2r, real_t *t2i, real_t *t3r, real_t *t3i, bool is_real_symmetric, realContext_t *realContext);
bool isRealSymmetric(const real_t *a, uint16_t size, realContext_t *realContext);
void dropNoise(real_t *eig, uint16_t size, uint16_t dig);
void QR_decomposition_householder(const real_t *mat, uint16_t size, real_t *q, real_t *r, realContext_t *realContext);

static void initRuntime(void) {
  mp_set_memory_functions(allocGmp, reallocGmp, freeGmp);
  c47MemInBlocks = 0;
  gmpMemInBytes = 0;
  fnReset(CONFIRMED);
}

// Load a size*size interleaved-complex matrix from a flat list of decimal
// strings (2*size*size entries: re,im,re,im,...).
static void loadMatrix(real_t *mat, uint16_t size, const char *const *cells) {
  const uint32_t count = (uint32_t)size * (uint32_t)size * 2u;
  for(uint32_t k = 0; k < count; ++k) {
    stringToReal(cells[k], &mat[k], &ctxtReal39);
  }
}

static bool realEqualsText(const real_t *value, const char *text) {
  real_t expected;
  stringToReal(text, &expected, &ctxtReal39);
  return realCompareEqual(value, &expected);
}

static size_t failures = 0;

static void expectBool(const char *name, bool actual, bool expected) {
  if(actual != expected) {
    printf("eigen oracle: %s expected %s, got %s\n", name, expected ? "true" : "false", actual ? "true" : "false");
    ++failures;
  }
}

// Assert the unordered eigenvalue pair {(er1,ei1),(er2,ei2)} matches the two
// worker outputs (t1,t2) in either order (the quadratic root order is not
// contractual).
static void expectEigenPair(const char *name,
                            const real_t *t1r, const real_t *t1i,
                            const real_t *t2r, const real_t *t2i,
                            const char *er1, const char *ei1,
                            const char *er2, const char *ei2) {
  bool order_a = realEqualsText(t1r, er1) && realEqualsText(t1i, ei1)
              && realEqualsText(t2r, er2) && realEqualsText(t2i, ei2);
  bool order_b = realEqualsText(t1r, er2) && realEqualsText(t1i, ei2)
              && realEqualsText(t2r, er1) && realEqualsText(t2i, ei1);
  if(!order_a && !order_b) {
    char b1[TMP_STR_LENGTH], b2[TMP_STR_LENGTH], b3[TMP_STR_LENGTH], b4[TMP_STR_LENGTH];
    realToString(t1r, b1); realToString(t1i, b2);
    realToString(t2r, b3); realToString(t2i, b4);
    printf("eigen oracle: %s eigenvalues mismatch\n", name);
    printf("  expected {(%s,%s),(%s,%s)}\n", er1, ei1, er2, ei2);
    printf("  actual   {(%s,%s),(%s,%s)}\n", b1, b2, b3, b4);
    ++failures;
  }
}

static void runIsRealSymmetric(void) {
  real_t mat[8];
  // [[2,1],[1,2]] real symmetric -> true
  const char *sym[8] = {"2","0", "1","0", "1","0", "2","0"};
  loadMatrix(mat, 2, sym);
  expectBool("isRealSymmetric[[2,1],[1,2]]", isRealSymmetric(mat, 2, &ctxtReal39), true);

  // [[2,1],[3,2]] non-symmetric -> false
  const char *nonsym[8] = {"2","0", "1","0", "3","0", "2","0"};
  loadMatrix(mat, 2, nonsym);
  expectBool("isRealSymmetric[[2,1],[3,2]]", isRealSymmetric(mat, 2, &ctxtReal39), false);

  // complex off-diagonal (nonzero imaginary) -> false
  const char *cpx[8] = {"2","0", "1","1", "1","-1", "2","0"};
  loadMatrix(mat, 2, cpx);
  expectBool("isRealSymmetric[complex]", isRealSymmetric(mat, 2, &ctxtReal39), false);
}

static void runEigenvalues22(void) {
  real_t mat[8];
  real_t t1r, t1i, t2r, t2i;

  // [[2,1],[1,2]] symmetric -> eigenvalues {3,1}, both real.
  const char *sym[8] = {"2","0", "1","0", "1","0", "2","0"};
  loadMatrix(mat, 2, sym);
  calculateEigenvalues22(mat, 2, &t1r, &t1i, &t2r, &t2i, true, &ctxtReal39);
  expectEigenPair("eig22[[2,1],[1,2]]", &t1r, &t1i, &t2r, &t2i, "3", "0", "1", "0");

  // [[0,-1],[1,0]] rotation -> eigenvalues {+i, -i}.
  const char *rot[8] = {"0","0", "-1","0", "1","0", "0","0"};
  loadMatrix(mat, 2, rot);
  calculateEigenvalues22(mat, 2, &t1r, &t1i, &t2r, &t2i, false, &ctxtReal39);
  expectEigenPair("eig22[[0,-1],[1,0]]", &t1r, &t1i, &t2r, &t2i, "0", "1", "0", "-1");

  // [[5,0],[0,3]] diagonal -> eigenvalues {5,3}.
  const char *diag[8] = {"5","0", "0","0", "0","0", "3","0"};
  loadMatrix(mat, 2, diag);
  calculateEigenvalues22(mat, 2, &t1r, &t1i, &t2r, &t2i, true, &ctxtReal39);
  expectEigenPair("eig22[[5,0],[0,3]]", &t1r, &t1i, &t2r, &t2i, "5", "0", "3", "0");
}

// Assert the unordered eigenvalue triple {actual t1,t2,t3} equals the three
// expected pairs as a multiset (greedy match; each expected consumes one
// distinct actual). Used with distinct-spectrum test matrices.
static void expectEigenTriple(const char *name,
                              const real_t *tr[3], const real_t *ti[3],
                              const char *const er[3], const char *const ei[3]) {
  bool used[3] = {false, false, false};
  for(int e = 0; e < 3; ++e) {
    bool matched = false;
    for(int a = 0; a < 3; ++a) {
      if(!used[a] && realEqualsText(tr[a], er[e]) && realEqualsText(ti[a], ei[e])) {
        used[a] = true;
        matched = true;
        break;
      }
    }
    if(!matched) {
      char b1[TMP_STR_LENGTH], b2[TMP_STR_LENGTH], b3[TMP_STR_LENGTH];
      realToString(tr[0], b1); realToString(tr[1], b2); realToString(tr[2], b3);
      printf("eigen oracle: %s eigenvalue triple mismatch (expected %s missing)\n", name, er[e]);
      printf("  actual reals: %s, %s, %s\n", b1, b2, b3);
      ++failures;
      return;
    }
  }
}

static void runEigenvalues33(void) {
  real_t mat[18];
  real_t t1r, t1i, t2r, t2i, t3r, t3i;
  const real_t *tr[3] = {&t1r, &t2r, &t3r};
  const real_t *ti[3] = {&t1i, &t2i, &t3i};

  // Diagonal [[7,0,0],[0,4,0],[0,0,1]] -> eigenvalues {7,4,1}.
  const char *diag[18] = {
    "7","0", "0","0", "0","0",
    "0","0", "4","0", "0","0",
    "0","0", "0","0", "1","0",
  };
  loadMatrix(mat, 3, diag);
  calculateEigenvalues33(mat, 3, &t1r, &t1i, &t2r, &t2i, &t3r, &t3i, true, &ctxtReal39);
  {
    const char *er[3] = {"7", "4", "1"};
    const char *ei[3] = {"0", "0", "0"};
    expectEigenTriple("eig33 diagonal{7,4,1}", tr, ti, er, ei);
  }

  // Symmetric [[2,1,0],[1,2,1],[0,1,2]] -> eigenvalues {2-sqrt2, 2, 2+sqrt2}.
  // Assert the exact-integer middle root 2 is present (the irrational pair is
  // representation-sensitive; the integer eigenvalue is a clean pin).
  const char *sym[18] = {
    "2","0", "1","0", "0","0",
    "1","0", "2","0", "1","0",
    "0","0", "1","0", "2","0",
  };
  loadMatrix(mat, 3, sym);
  calculateEigenvalues33(mat, 3, &t1r, &t1i, &t2r, &t2i, &t3r, &t3i, true, &ctxtReal39);
  {
    bool has_two = realEqualsText(&t1r, "2") || realEqualsText(&t2r, "2") || realEqualsText(&t3r, "2");
    bool all_real = realEqualsText(&t1i, "0") && realEqualsText(&t2i, "0") && realEqualsText(&t3i, "0");
    if(!has_two || !all_real) {
      printf("eigen oracle: eig33 symmetric tridiagonal expected a real eigenvalue 2\n");
      ++failures;
    }
  }
}

// dropNoise rounds each diagonal element (i,i) real+imag to `dig` significant
// digits (HALF_UP) and leaves off-diagonal entries untouched.
static void runDropNoise(void) {
  real_t eig[8];
  // Matrix-shaped 2x2: diagonal (0,0)=idx0, (1,1)=idx6; off-diagonal idx2/idx4.
  const char *cells[8] = {
    "2.99999999","0",   "0.123456789","0",
    "0.987654321","0",  "0.99999999","0",
  };
  loadMatrix(eig, 2, cells);
  dropNoise(eig, 2, 5);
  // Diagonal rounded to 5 sig digits -> integers 3 and 1.
  if(!realEqualsText(&eig[0], "3")) { printf("eigen oracle: dropNoise diag(0,0) expected 3\n"); ++failures; }
  if(!realEqualsText(&eig[6], "1")) { printf("eigen oracle: dropNoise diag(1,1) expected 1\n"); ++failures; }
  // Off-diagonal untouched (still the noisy inputs).
  if(!realEqualsText(&eig[2], "0.123456789")) { printf("eigen oracle: dropNoise perturbed off-diagonal (0,1)\n"); ++failures; }
  if(!realEqualsText(&eig[4], "0.987654321")) { printf("eigen oracle: dropNoise perturbed off-diagonal (1,0)\n"); ++failures; }
}

// |a - b| < 10^-30 (real parts; the QR reconstruction of an integer matrix is
// near-exact but Householder involves a square root, so compare with tolerance).
static bool realCloseTo(const real_t *a, const real_t *b) {
  real_t diff, tol;
  realSubtract(a, b, &diff, &ctxtReal39);
  stringToReal("1e-30", &tol, &ctxtReal39);
  return realCompareAbsLessThan(&diff, &tol);
}

// QR factorization is not unique (Householder always applies reflections, with
// sign choices), so assert the invariants that always hold: Q*R reconstructs the
// input (within tolerance -- the reflection carries a square root) and R is
// upper-triangular. Inputs here are real, so Q and R are real.
static void checkQrReconstructs(const char *name, const char *const cells[8]) {
  real_t mat[8], q[8], r[8];
  loadMatrix(mat, 2, cells);
  QR_decomposition_householder(mat, 2, q, r, &ctxtReal39);
  for(int i = 0; i < 2; ++i) {
    for(int j = 0; j < 2; ++j) {
      real_t acc, prod;
      realSetZero(&acc);
      for(int k = 0; k < 2; ++k) {
        realMultiply(&q[(i*2+k)*2], &r[(k*2+j)*2], &prod, &ctxtReal39);
        realAdd(&acc, &prod, &acc, &ctxtReal39);
      }
      if(!realCloseTo(&acc, &mat[(i*2+j)*2])) {
        char b1[TMP_STR_LENGTH], b2[TMP_STR_LENGTH];
        realToString(&acc, b1); realToString(&mat[(i*2+j)*2], b2);
        printf("eigen oracle: %s reconstruction (Q*R)[%d][%d]=%s != input %s\n", name, i, j, b1, b2);
        ++failures;
      }
    }
  }
  real_t zero;
  realSetZero(&zero);
  if(!realCloseTo(&r[(1*2+0)*2], &zero)) { printf("eigen oracle: %s R[1][0] not zero (not upper-triangular)\n", name); ++failures; }
}

static void runQrDecomposition(void) {
  const char *upper[8] = {"2","0", "3","0", "0","0", "4","0"};
  checkQrReconstructs("QR upper-triangular", upper);
  const char *general[8] = {"1","0", "2","0", "3","0", "4","0"};
  checkQrReconstructs("QR general", general);
}

int main(void) {
  initRuntime();

  runIsRealSymmetric();
  runEigenvalues22();
  runEigenvalues33();
  runDropNoise();
  runQrDecomposition();

  if(failures != 0) {
    printf("eigen oracle failed %zu check(s)\n", failures);
    return 1;
  }
  printf("eigen oracle passed\n");
  return 0;
}

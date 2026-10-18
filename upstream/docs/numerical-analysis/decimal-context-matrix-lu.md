# Decimal context analysis for matrix LU, determinant, and inverse

## Scope and decisions

This analysis covers `fnLuDecomposition`, `fnDeterminant`,
`fnInvertMatrix`, the real and complex LU kernels, determinant formation,
triangular solution, and conversion to Real34 or Complex34. Matrix products,
eigenvalue calculation, matrix square root, and matrix division are dependent
operations but are outside the public-function scope here.

| Route | Context | Reason |
| --- | ---: | --- |
| one-element determinant | none | the input component is copied exactly |
| one-element real or complex inverse | 39 | a reciprocal is well-conditioned and five work digits cover the complex arithmetic |
| real or complex LU, order at least two | 75 | elimination can expose the full 68-digit product width of Real34 inputs |
| real or complex determinant, order at least two | 75 | the LU pivots and their product inherit elimination cancellation |
| real or complex inverse, order at least two | 75 | factorisation and two triangular solutions compound the same cancellation |

P75 is therefore the narrowest established general matrix context. The work
buffers already allocate p75 `real_t` slots, so the context increase requires
no additional memory.

P34 is not selected for any chained matrix arithmetic. A decQuad operation
requires unpacking and repacking in this implementation, so p34 offers no
speed advantage over p39 and can be slower across a sequence of operations.
The one-element determinant performs no arithmetic. The one-element inverse
keeps p39 because its real and complex reciprocal routes contain several
dependent operations and need the five extra digits.

## A two by two lower bound

For

```text
A = [ a  b ]
    [ c  d ]
```

with no row exchange, the second upper-triangular pivot is

```text
u22 = d - (c/a)*b = det(A)/a.
```

Each Real34 product in `a*d-b*c` can contain 68 significant digits. The
difference may expose any of them. Five p39 work digits, or seventeen p51
work digits, cannot in general produce a 34-digit `u22`, determinant, or
inverse.

The stored discriminator uses

```text
a = 7
b = 1.234567890123456789012345678901234
c = 0.9876543210987654321098765432109876
d = 0.1741894730528882788945500467626668
```

Exact decimal arithmetic gives

```text
det(A) = 3.419971035595208351844841960013016E-34
u22    = 4.885672907993154788349774228590023E-35.
```

A deliberate p51 build produced only 17 correct significant digits in each
value and in every inverse component. P39 produced about five correct digits
in the inverse. P75 produces all 34 asserted result digits. In this case the
34-place cancellation leaves about 41 digits after the p75 division and
multiply operations, including seven digits beyond the result width.

P75 can represent either exact 68-digit product in the equivalent expression
`a*d-b*c`, but the implemented elimination route forms `(c/a)*b`. A
nonterminating quotient therefore introduces p75 error before the
subtraction. Cancellation through almost all 68 input-product digits can
still leave fewer than 34 accurate digits. Such a matrix is too ill
conditioned for a fixed p75 factorisation to promise a correctly rounded
inverse or LU pivot.

## Small nonzero pivots

Let `delta=1E-33`, an exact Real34 value. The real matrix

```text
Ar = [       1  1+delta ]
     [ 1-delta        1 ]
```

has `det(Ar)=delta^2=1E-66` exactly. The complex matrix

```text
Ac = [          1  1+i*delta ]
     [ 1-i*delta          1 ]
```

has `det(Ac)=-delta^2=-1E-66` exactly. P39 and p51 round the decisive product
to one and classify both matrices as singular. P75 represents the products
exactly and returns the finite determinants and inverses.

The former elimination screen used the fixed relative value `1E-37` at every
work width. That value erased valid p75 pivots. The revised screen uses

```text
10^(2-p)
```

for a p-digit context, which is `1E-73` at p75. This is twenty unit roundoffs
and removes only a local residual below useful p75 resolution. The complex
screen compares element magnitudes instead of its real and imaginary parts
independently. A small component of a non-small complex pivot is therefore
preserved.

No finite threshold can distinguish every singular matrix from every
nonsingular Real34 matrix. Higher-order determinants can have more than 75
significant digits after cancellation. The screen defines numerical rank at
the selected work width; matrices nearer that boundary are conditioning
limited.

## Elimination and conditioning

Partial pivoting selects the largest absolute entry in each real pivot column
and the largest scaled complex magnitude in each complex pivot column. The
resulting multipliers have magnitude at most one before rounding. For p75,
the unit roundoff is `u=5E-75`. Standard elimination bounds give a backward
error proportional to

```text
gamma(3n) * growth,  gamma(k) = k*u/(1-k*u).
```

The largest hardware memory pool contains 65534 four-byte blocks. The inverse
route needs two 30-block-per-element complex work matrices, plus its vectors
and input matrix, which limits feasible order to the low thirties even in an
otherwise empty pool. The pessimistic partial-pivot growth factor `2^(n-1)`
then leaves more than 50 significant work digits at p75 before conditioning
of the requested result. P51 has no comparable 34-digit margin and already
fails at order two because input-product cancellation precedes that bound.

Backward stability does not imply a uniformly accurate inverse. Forward
error is amplified by the matrix condition number, and determinant relative
error is amplified by determinant conditioning. Near-defective matrices can
therefore lose any number of result digits even at p75. The existing
`TI_INACCURATE` indication remains in use for a large spread among diagonal
LU pivots.

## Exponents, pivot signs, and special values

The p39, p51, and p75 work contexts use exponent limits of plus or minus
999999. Products of feasible Real34 matrix entries remain within that work
range, including values whose final determinant lies outside the Real34
range. Final conversion applies the selected calculator rounding mode.

The tests include the exact determinant `1E-12352`. Half-even, half-up,
half-down, toward-zero, and floor conversion give zero; away-from-zero and
ceiling give the minimum positive Real34 value `1E-6176`. An upper-range
determinant becomes infinity under half-even and the largest finite Real34
value under toward-zero.

Row exchanges change the determinant sign through the pivot vector. An exact
zero pivot reports singularity for LU and inverse, while determinant returns
zero. NaN and infinity continue through the established special-result
handling. A one-element determinant needs no arithmetic, and a one-element
inverse stays on the p39 reciprocal route.

## Result modes and verification

P75 and p39 work use half-even arithmetic. Conversion to each Real34 result
component applies the selected mode. The one-element reciprocal tests use
exact subtraction and scaling to assert digit 34 under all seven modes. The
accepted p39-to-p34 boundary difference remains outside this analysis.

The existing `matrixops_cov.txt` file now includes:

- the varied 34-digit LU pivot, determinant, and inverse;
- exact real and complex determinants of magnitude `1E-66`;
- exact finite inverses of those small-determinant matrices;
- upper and lower Real34 exponent limits;
- all seven result modes for a one-element reciprocal;
- singular signed zero, NaN, and infinity cases.

Before the source change, eight grouped cases failed. P51 trials retained only
17 digits in the varied case and classified both `1E-66` determinants as
zero. The p75 implementation satisfies every stored value.

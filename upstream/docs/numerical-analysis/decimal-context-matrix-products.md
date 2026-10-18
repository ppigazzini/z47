# Decimal context analysis for matrix products and vector dots

## Scope

This analysis covers `multiplyRealMatrices`, `multiplyComplexMatrices`,
`dotRealVectors`, and `dotComplexVectors`.  Each input element is Real34.  The
scalar, integer, determinant, inverse, eigenvalue, norm, and internal wide
matrix kernels require separate analyses.

The public matrix and vector routes retain p39 as their primary context.  A
two-term compensated accumulator replaces ordinary summation, and a p75 replay
is selected when a component loses more than 20 decimal places through
cancellation.  This gives inexpensive p39 work for ordinary cells and much
stronger protection for ill-conditioned cells.

## Error-free product decomposition

For a real term `t = a*b`, the implementation computes

```text
p = RN_q(a*b)
r = FMA(a,b,-p).
```

Two Real34 coefficients produce at most 68 digits.  At p39, the part omitted
from `p` has at most 29 digits, so the fused operation obtains `r = t-p`
exactly.  At p75 the product itself is exact.  Thus `p+r=t` in either selected
context.

A finite complex component is expanded into its two real products before
accumulation:

```text
Re((a+ib)(c+id)) = ac-bd
Im((a+ib)(c+id)) = ad+bc.
```

This supplies two product decompositions to each component.  Special complex
elements continue through `mulComplexComplex`, preserving its audited NaN and
infinity semantics.

## Compensated summation bound

Each high and low product part enters a magnitude-ordered FastTwoSum
accumulator.  FastTwoSum gives `x+y=a+b` without error for finite operands in
round-to-nearest arithmetic when `|a| >= |b|`.  The low parts are added to a
separate correction, followed by one final addition.

This is the Neumaier compensated sum analysed by Ogita, Rump, and Oishi in
[Accurate Sum and Dot Product](https://doi.org/10.1137/030601818).  For `m`
floating summands, unit roundoff `u`, and `3*m*u <= 1`, its forward bound is

```text
|result - S| <= u*|S| + (3*m^2/4 + m)*u^2*A,
A = sum(abs(term_j)).
```

The real route has `m=2*n`; either finite complex component has `m=4*n`.
Available memory limits a Real34 vector to fewer than 16384 elements and a
Complex34 vector to fewer than 8192 elements.  Both cases therefore have
`m < 32768` and

```text
3*m^2/4 + m < 8.06E8.
```

For p39, `u39=5E-39`, making the second-order coefficient less than
`2.02E-68`.  The positive magnitude sum is also accumulated and compared with
the result exponent.  When the difference is no greater than 20, the component
condition number is below about `1E21`; the second-order relative contribution
is then below `2.1E-47`.  The leading p39 term is `5E-39`, five decimal orders
below Real34 unit roundoff.

If the exponent difference exceeds 20, or a non-zero magnitude sum produces
zero, the cell is recomputed at p75.  At p75 the second-order coefficient is
less than `2.02E-140`.  This supplies at least six decimal guard places for
component condition numbers through `1E100`.  Some structured cases beyond
that conservative range are also recovered, but no fixed-width accumulator
can cover every possible Real34 exponent separation.

The condition number is componentwise.  A complex result near an axis can
therefore have a well-conditioned norm and an ill-conditioned small component;
the two components select the retry independently through their magnitude
sums, while one retry recomputes both.

## Context selection

P34 is unsuitable even with compensation.  Its exponent range is the Real34
range, so products can overflow before a later cancellation.  Two maximum
finite inputs squared with opposite signs produce NaN at p34 although their
sum is zero.  P39 has exponent limits of plus or minus 999999 and safely
contains every product of Real34 elements.  It is therefore the narrowest
available primary context.

P51 is insufficient as the extended context.  In the sequence

```text
1E60 + 1 + 1E-60 - 1E60 - 1 = 1E-60,
```

a p51 two-term accumulator loses the final low part, while p75 retains it.  The
file-driven checks multiply the result by `1E60`, so the suite's normal
tolerance cannot conceal zero in place of the required value.

Only the final Real34 conversion uses the selected user rounding mode.  P39
and p75 arithmetic remains half-even, as required by the error-free
transformations.  Differences caused solely by shortening a boundary-adjacent
working value to Real34 are excluded under the requested double-rounding
policy.

## Regression cases

The existing `multiplication_realMatrix.txt`,
`multiplication_complexMatrix.txt`, and `dot.txt` files cover:

* a Fibonacci determinant whose two 67-digit products differ by one;
* `1E100 + 1 - 1E100`, which exposes ordinary summation loss;
* the p75 discriminator above, amplified before comparison;
* cancellation of two maximum-finite squares, which rejects p34 work;
* matching real and imaginary cancellation in complex matrix and vector
  products.

The former kernels succeeded in 89 of 96 focused checks after the initial
cases were added.  Disabling the p75 replay on the final corpus succeeds in
100 of 104 checks.  Replacing the replay with p51 has the same 100 of 104
result.  The selected p39/p75 implementation succeeds in all 104 checks.

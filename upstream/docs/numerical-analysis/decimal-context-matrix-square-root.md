# Decimal context analysis for matrix square root

## Scope

This analysis covers `fnMatrixSquareRoot`, the real one by one and diagonal
routes, the direct symmetric two by two real route, and the real and complex
eigensystem routes.  Matrix eigenvalues, eigenvectors, multiplication, inverse,
and norm calculations have separate analyses.

No fixed work width can provide a 34-digit componentwise guarantee for every
matrix.  A defective eigensystem or a matrix arbitrarily close to one can make
the square-root problem arbitrarily ill-conditioned.  The claims below apply to
finite well-conditioned inputs and to the stated positive-semidefinite two by
two class.

## Context selection

| Route | Context | Reason |
|---|---:|---|
| One by one and diagonal real matrices | p39 | Each entry needs one square root; the established real square-root analysis selects p39. |
| Symmetric positive-semidefinite real two by two matrices | p39 | A compensated determinant followed by positive additions, square roots, and divisions keeps five work digits. |
| Other real matrices | Existing eigensystem contexts | The route inherits p75 eigenvalue and eigenvector work, then reconstructs a Real34 matrix. |
| Complex matrices | Existing eigensystem contexts | Complex eigenvalues and vectors can be ill-conditioned; the route retains its wider work. |
| Public matrix entries | Real34 or Complex34 | The selected result mode applies at this conversion. |

A single p34 operation has the same cost class as a p39 operation and is
appropriate when Real34 lattice semantics are required.  The direct two by two
formula is a chain of dependent operations.  P34 gives no execution-time gain,
adds no guard digits, and applies the selected user mode at every internal
step.  P39 is therefore the minimum useful chained width.  P51 and p75 do not
improve the bound for the direct formula.

## Direct two by two formula

Let

```text
A = [ a  b ]
    [ b  d ]
```

be positive semidefinite and let `delta = a*d - b*b`.  Its principal square
root is

```text
sqrt(A) = (A + sqrt(delta) I) / sqrt(a + d + 2 sqrt(delta)).
```

The identity follows by squaring the right-hand side and using the
Cayley-Hamilton relation

```text
A*A - (a + d) A + delta I = 0.
```

The implementation first checks exact Real34 symmetry.  Nonnegative diagonal
entries and a nonnegative determinant are sufficient for a symmetric two by
two matrix to be positive semidefinite.  Inputs outside that class continue to
the previous eigensystem route.

## Forward error

Write `u = 5E-39`.  The compensated sum of two products used for `delta`
satisfies

```text
|delta_hat - delta| <= 2 u |delta|
```

for a nonzero finite determinant.  The residual of each product has at most 29
coefficient digits after a p39 product of two Real34 inputs, so its fused
correction is exact.  Exact product cancellation returns exact zero.

The determinant square root consequently has relative error below `2u` to
first order.  All terms in `a+d+2*sqrt(delta)` are nonnegative.  Its square root
has relative error below `3u`.  The two diagonal numerators are also
nonnegative and have relative error below `3u`.  Including the closing division
gives the conservative component bounds

```text
relative error of a nonzero diagonal entry     < 7u = 3.5E-38
relative error of a nonzero off-diagonal entry < 4u = 2.0E-38.
```

These bounds leave more than four decimal guard places before Real34
conversion.  They exclude the accepted p39-to-p34 boundary difference and do
not claim universal correct rounding.

## Exponent range

Products of Real34 entries have adjusted exponents between about `-12352` and
`+12289`.  The trace can add one leading digit and the square roots reduce those
exponents.  Every finite intermediate therefore fits within the
`+/-999999` p39 exponent range.  A p34 chain can overflow the determinant
products of a finite matrix before their subtraction.

The rank-one input with all four entries equal to `1E6144` exercises this
range.  Its principal square root has every entry equal to

```text
7.071067811865475244008443621048490...E3071.
```

## Eigensystem limitation

The general route computes eigenvalues and eigenvectors with their audited
wider kernels.  Their public matrices are nevertheless Real34 before the
closing products.  Reconstruction can therefore lose a component much smaller
than the order-one eigenvector terms even when the source matrix contains that
component exactly.  Increasing only the closing matrix multiplication width
cannot recover those discarded digits.

For

```text
A = [ 1       1E-34 ]
    [ 1E-34   1     ],
```

the eigenvalues are `1+e` and `1-e`, where `e=1E-34`.  Its square root has
off-diagonal entry

```text
e / (sqrt(1+e) + sqrt(1-e)) = 5E-35 + O(1E-103),
```

and diagonal entries `1+O(1E-68)`.  The former eigensystem reconstruction
returns zero for the off-diagonal entries.  The direct p39 formula returns the
Real34 matrix with off-diagonal entries `5E-35`.

## Verification

The existing `matrix.txt` file contains the near-identity case, the maximum
finite rank-one case, a negative off-diagonal rank-one case, ordinary positive
definite matrices, invalid matrices, and the previous real and complex matrix
square-root cases.  With the near-identity case added, the earlier source
reports 199 successful checks from 200.  The revised source reports 202 from
202.  The maximum finite and signed rank-one cases also confirm the direct
formula's exponent and sign behaviour.

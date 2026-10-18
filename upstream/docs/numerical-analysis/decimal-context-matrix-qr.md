# Decimal contexts for public matrix QR decomposition

## Scope and decision

This analysis covers `fnQrDecomposition`, `real_QR_decomposition`,
`complex_QR_decomposition`, and their use of the Householder kernel. The
eigensystem also uses that kernel, but its iterative context policy is covered
by `decimal-context-matrix-eigen.md`.

The public real and complex routes now use p75 throughout the Householder
calculation. P75 is the narrowest established project context for these
routes. Conversion of `Q` and `R` to Real34 or Complex34 remains the only
result-width operation.

The work arrays already contain p75 `real_t` values, so the context change
does not increase their size. A single p34 operation has no extra cost and is
appropriate when one correctly rounded Real34 operation is the required
calculation. QR decomposition is instead a dependent sequence of norms,
divisions, products, and subtractions. Repeated p34 unpacking and repacking
provides no speed advantage over p39 and can increase the cost of such a
sequence. Accuracy considerations reject both p39 and p51 here.

## Householder error scale

For a p-digit half-even context, use

```text
u_p = 5 * 10^(-p).
```

Each reflector has the form

```text
H = I - 2 v v*.
```

The implementation obtains the vector norm from fused square accumulation,
normalises the reflector vector, and applies the reflector through complex
matrix products. Correctly rounded addition, subtraction, multiplication,
division, fused multiplication-addition, and square root give a local error
proportional to `u_p`. An inner product of length `n` has a first-order factor
of the form

```text
gamma(k) = k*u_p/(1-k*u_p),
```

where `k` is proportional to `n`. Composition of the reflectors therefore
gives a normwise backward perturbation

```text
A + Delta A = Q R,
norm(Delta A) <= C(n) * u_p * norm(A),
```

for finite inputs away from arithmetic range limits. `C(n)` also includes
the matrix-product work. This is a backward-error statement. A small entry of
`R`, or any requested component affected by near column dependence, can have
its relative error enlarged by the relevant condition number.

Every product of two Real34 input components has at most 68 coefficient
digits. P75 can form such a product without coefficient rounding and supplies
41 work digits beyond the output width for the later divisions and matrix
products. P51 supplies 17 extra digits and p39 supplies five. Neither narrower
width covers cancellation that exposes more than those extra digits.

## Two by two discriminators

Let `d=1E-18`. For the real matrix

```text
Ar = [     1  1+d ]
     [ 1-d      1 ]
```

define

```text
s = sqrt(1 + (1-d)^2).
```

The selected reflector signs give

```text
Q = [   -1/s  -(1-d)/s ]
    [ -(1-d)/s      1/s ]

R = [ -s  -2/s ]
    [  0  d^2/s ].
```

The small diagonal entry is about `7.071E-37`, while the input norm is near
two. Its relative sensitivity to work-scale perturbations is consequently of
order `u_p/d^2`. The p39 scale is about `5E-3`, and the implementation returned
only two correct significant digits. The p51 scale is about `5E-15`; its
result had fourteen correct significant digits. P75 has about 39 digits at
this scale before the modest two-by-two operation factor and produced the
independently evaluated 34-digit value

```text
7.071067811865475247543977526981228E-37.
```

The complex discriminator is

```text
Ac = [       1  1+i*d ]
     [ 1-i*d      1   ].
```

Its small diagonal entry is

```text
-d^2/sqrt(2+d^2)
= -7.071067811865475244008443621048490E-37
```

after Real34 conversion. The p39 and p51 mutations again retained only two
and fourteen significant digits, respectively. P75 produced every asserted
digit in both real and complex cases.

These examples establish p75 over the available p39 and p51 alternatives.
They do not establish a uniform componentwise forward-error guarantee. With
`d=1E-33`, the same small diagonal lies near `7E-67`; even p75 then has only
about eight useful digits because `u75/d^2` is about `5E-9`. No fixed p75 QR
calculation can produce 34 relative digits for every representable matrix
arbitrarily close to rank deficiency.

## Range and result conversion

P39, p51, and p75 use work exponent limits of plus or minus 999999. Squares
and products of finite Real34 components, whose adjusted exponents are bounded
by the decimal128 range, fit comfortably inside that work range. P34 has the
decimal128 exponent range and can overflow or underflow an intermediate norm
even when a scaled mathematical decomposition is finite.

The internal contexts use half-even arithmetic. Conversion of each `Q` and
`R` component applies the selected calculator rounding mode. The analysis
claims faithful 34-digit results where conditioning leaves the stated p75
margin; it does not claim universal correct rounding or accuracy for
arbitrarily rank-deficient inputs.

One by one matrices execute no reflector step: `Q` is exactly one and `R` is
the input. Non-square matrices retain the existing type error. NaN and
infinity propagation retains the existing arithmetic semantics and is
outside the finite backward-error argument.

## Verification

The cases were added to the existing file-driven `matrix_cov.txt` suite. Each
small `R` matrix is subtracted from its independently evaluated Real34 matrix
and multiplied by `1E70`, so the ordinary 30-digit comparison cannot conceal
a difference in the final stored digits.

With the selected p75 routes, the focused file succeeds in all cases. A p39
mutation fails both new decompositions and returns small diagonal entries near
`7.09E-37`; a p51 mutation also fails both and returns only fourteen correct
digits. The real and complex p75 results match all 34 asserted digits.

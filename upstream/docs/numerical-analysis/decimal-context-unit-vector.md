# Decimal context analysis for unit vectors

## Scope

This analysis covers `unitVectorCplx`, including its use as the complex sign operation, and the real and complex matrix routes `unitVectorRema` and
`unitVectorCxma`. Scalar real and integer values are rejected by the unit-vector command.

## Scalar recommendation

Keep all five arithmetic operations in `ctxtReal39`. This is the narrowest suitable established context among 34, 39, 51 and 75 digits. It retains a relative
working error below `1.51E-38` for each non-zero result component and its wide exponent range contains every intermediate formed from decimal128 inputs. The
34-digit context has neither an adequate error margin nor the required intermediate exponent range. Contexts of 51 and 75 digits add no useful accuracy to the
decimal128 output.

No source change is required. The added file-driven cases make the context choice and its range requirements explicit.

## Finite calculation

For `z = a+ib`, write

```text
S = a^2+b^2,
N = sqrt(S),
u_r = a/N,
u_i = b/N.
```

The implementation evaluates

```text
q = RN_p(a^2)
s = RN_p(q+b^2)
n = RN_p(sqrt(s))
r = RN_p(a/n)
j = RN_p(b/n).
```

The sum of squares uses a fused multiply-add. For a nearest decimal context with unit roundoff `u_p`, non-negative terms give

```text
|s-S|/S <= E = 2u_p+u_p^2.
```

The exact square-root sensitivity and the rounded square root give

```text
B = E/(1+sqrt(1-E)) + u_p + u_p*E/(1+sqrt(1-E))
```

as a bound for `|n-N|/N`. Division by the perturbed norm, followed by one rounded division, then gives each non-zero component the bound

```text
|computed-u_component|/|u_component| <= B/(1-B) + u_p + u_p*B/(1-B).
```

At 39 digits, `u_39 = 5E-39`, so the right side is below `1.51E-38`. This leaves more than four decimal guard digits before conversion to decimal128. A zero input
component produces an exact zero result component whenever the norm is non-zero.

The 39-digit work contexts use exponent limits of `+/-999999`. Decimal128 component squares have adjusted exponents from `-12352` through `12289`, their sum stays
within the same wide range, and its square root returns to the input scale. The final divisions also remain within the wide range before decimal128 conversion.

## Final conversion

The work context uses half-even rounding, and conversion to decimal128 applies the selected user mode. The `1.51E-38` bound is below `3.02E-5` of the normal
34-digit unit roundoff. Differences confined to the accepted 39-to-34 boundary intervals are outside this analysis.

For extremely imbalanced finite components, the smaller unit-vector component can lie below the decimal128 subnormal range. Nearest modes can then return zero;
directed modes can return the minimum subnormal. The absolute conversion error is at most `0.5E-6176` for nearest modes and below `1E-6176` for directed modes.

## Why 34 digits fail

At 34 digits, the bound above approaches `1.51E-33`, more than one half ulp at the output precision. In addition, `ctxtReal34` follows the selected user rounding
mode rather than the nearest work rounding used by the bound.

The finite input

```text
a = 5.759770874473226418130647797E+35
b = 2.287758707029974973665301802E+37
```

has the high-precision unit vector

```text
a/N = 0.025168503540506092241720334290872488366687888158...
b/N = 0.999683223040944872042715401149364351187892678915...
```

The half-even decimal128 imaginary component ends in `3644`. Running the five operations in `ctxtReal34` instead returns a value ending in `3645`. The scaled
file-driven checks expose analogous errors under every user mode.

Range loss is more severe. Squaring `1E-6176` in `ctxtReal34` underflows before the norm is formed, while squaring the maximum finite decimal128 value overflows.
Equal minimum or equal maximum components should both normalise to `1/sqrt(2)` in each component; a 34-digit work context cannot compute either case. A temporary
34-digit build succeeds in only 34 of the 45 focused cases, with seven rounding failures and four exponent-range failures.

## Zero and special values

The zero vector has no defined direction. The existing primitive sequence returns `NaN+iNaN`, which the tests retain. An infinite component also has no finite
magnitude ratio in decimal arithmetic: the corresponding division forms `infinity/infinity`, while a finite component divided by an infinite norm becomes zero.
No context width changes these classifications.

## Matrix normalisation

Let `m` be the number of squared real components.  A real matrix has one
component per entry; a complex matrix has two.  Available storage gives
`m < 16384` for either route.  Both routes evaluate

```text
S = sum(x_j^2)
N = sqrt(S)
u_j = x_j/N
```

in `ctxtReal39`.  The terms in `S` are nonnegative, so cancellation cannot
amplify the summation error.  With `u39=5E-39`, the ordinary dot-product bound
is

```text
|S_hat-S|/S <= gamma_m,
gamma_m = m*u39/(1-m*u39) < 8.20E-35.
```

Square-root sensitivity divides the leading summation error by two.  Including
the rounded square root and the closing division gives a conservative relative
component error below `4.2E-35` for each nonzero finite output component.  This
is less than one tenth of Real34 unit roundoff.  P39 is therefore the narrowest
established context for matrix normalisation.  P51 and p75 reduce an error that
already has a 34-digit margin.

A p34 arithmetic operation is cost-neutral when used alone.  Matrix
normalisation is a dependent chain with as many as 16384 products and
additions, followed by a square root and divisions.  P34 adds no work digit and
has no execution-time advantage for this chain.  Its positive summation bound
is also about `8.20E-30`, before the closing operations.

The p39 exponent range contains every Real34 square.  Summing fewer than 16384
terms can add at most five adjusted-exponent places.  The matrix norm and every
finite quotient therefore remain inside the p39 range.  P34 can underflow or
overflow the first square even though the unit-vector entries are near one.

For a finite complex matrix, division by the real norm now uses one direct
division per component.  The general complex-division kernel previously
formed the norm square and two products before its two divisions.  Removing
those exact-real-denominator operations reduces the arithmetic count and its
rounding contribution.  A special numerator or norm still uses the general
kernel, preserving its established NaN and infinity classifications.  A zero
norm produces NaN components, as on the scalar route, and a finite nonzero norm
preserves signed zero.

## Tests

`unitVector.txt` checks the independently calculated scalar result under all
seven modes using subtraction and scaling, equal minimum and maximum
components, extreme component imbalance under nearest and directed rounding,
and the zero vector.  The matrix cases repeat the full-exponent checks for real
and complex matrices, amplify the scalar discriminator after placing it in a
real matrix, and cover zero, signed zero, NaN, and infinity.

A deliberate p34 matrix mutation succeeds in 50 of 56 checks from the first
matrix corpus.  It fails all four full-exponent cases and both amplified
finite-result cases.  The selected p39 implementation with the direct finite
complex divisions succeeds in all 60 checks.

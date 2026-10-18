# Decimal context for atan2 and complex argument

## Scope and result

This analysis covers the public scalar and real-matrix `atan2` routes in `atan2.c`, the real, complex, and matrix argument routes in `arg.c`, and the p39 atan table
and polynomial used by `C47_WP34S_Atan2` in `wp34s.c`.

The scalar and matrix `atan2` routes remain at `ctxtReal39`. It is the narrowest established context that supplies a 34-digit result with an accuracy margin and
keeps every quotient of finite real34 operands inside the work exponent range. The p39 kernel has a conservative relative error below `7e-36` for every finite nonzero
angle. For a tiny angle in the table cell centred on zero, the sharper relative bound is below `2.1e-37`. These are faithful-accuracy bounds, not universal
correct-rounding results. Differences confined to an accepted 39-to-34 rounding boundary are outside this analysis.

Complex argument now calls the same p39 `atan2(imaginary, real)` kernel directly. This removes an unused magnitude calculation, preserves signed-zero branch-cut
information, and prevents a p39 matrix angle from being narrowed to real34 before angular-mode conversion.

## Finite atan2 calculation

For finite nonzero coordinates, write

```text
t = y/x
theta = atan(t)                         when x > 0
theta = atan(t) + sign(y)*pi            when x < 0.
```

The p39 context uses round-to-nearest-even and has unit roundoff

```text
u39 = 0.5e-38 = 5e-39.
```

The real34 input conversion is exact. Since `ctxtReal39` has exponent limits of `+/-999999`, the quotient cannot overflow or underflow: real34 coordinate exponents
can differ by only about 12320 decimal orders. For a finite nonzero exact quotient `t`, its rounded value satisfies

```text
t_hat = t*(1+delta),  |delta| <= u39.
```

The mean-value theorem and `atan'(t)=1/(1+t^2)` give

```text
|atan(t_hat)-atan(t)| <= u39/(2*(1-u39)) < 2.51e-39 radians.
```

This bound is independent of the coordinate ratio and includes ratios close to zero or infinity.

## Table reduction and polynomial

Requests through 39 digits use

```text
a = min(|t|, 1/|t|)
c = j/10, where j is the nearest integer to 10*a
q = (a-c)/(1+a*c), so |q| <= 1/20
atan(a) = atan(c) + atan(q)
atan(q) ~= q*P(q^2).
```

The centres `j/10` are exact decimal values. For `j != 0`, `a/c` is between one half and two, so subtraction of the centre is exact by Sterbenz's lemma. The `j=0`
subtraction is also exact. The positive denominator has no cancellation.

An independent 100-digit decimal evaluation used the stored 39-digit coefficients. It formed the derivative polynomial for the approximation error and evaluated all
real critical points on `0 <= q^2 <= 0.0025`. The resulting uniform relative approximation bound is

```text
|atan(q) - q*P(q^2)|/|q| < 2.929e-41.
```

The p39 atan table constants contribute at most `5e-40` radians. The stored pi-family constants contribute at most `5e-39` radians. Fewer than forty rounded arithmetic
steps occur from the initial quotient through a full 13-coefficient evaluation and quadrant correction. The Horner terms stay positive after each small alternating
correction, table addition cannot reduce a nonzero table-cell result below `atan(0.05)`, inversion returns at least `pi/4`, and quadrant addition returns at least
`pi/2`. Thus no arithmetic branch has unbounded cancellation.

Direct forward accounting with `gamma_40 = 40*u39/(1-40*u39)` gives an absolute error below `3e-37` radians outside the zero-centred cell. Division by the smallest
possible nonzero magnitude on that route, `atan(0.05)`, gives the conservative relative bound below `7e-36`. In the zero-centred cell the exact zero table entry removes
the absolute table-constant term; the calculation is relative-stable and its bound is below `gamma_40 + 2.929e-41 < 2.1e-37`.

Optional inversion, quadrant addition, and conversion to degrees, gradians, or multiples of pi do not worsen these stated relative bounds. Their results do not suffer
cancellation, and each adds at most one p39 rounding plus its p39 constant error.

## Context choice

At 34 digits, `u34=5e-34`. The internal atan dispatcher raises only the table evaluation to 36 digits. The preceding quotient, the following quadrant addition, and
angular-mode conversion would still use 34 digits. The quotient perturbation alone can approach half a 34-digit unit roundoff, and the remaining arithmetic has no
accuracy margin. The decimal128 exponent range would also underflow or overflow the most imbalanced real34 coordinate ratios before atan reduction.

The 39-digit context keeps the full route in the wide exponent range and leaves more than one decimal guard digit under the conservative global bound, with a much
larger margin for tiny angles. A 51-digit request selects the 75-digit Taylor atan implementation while the surrounding arithmetic stays at 51 digits. A 75-digit
request keeps the whole route at 75 digits. Neither width improves a 34-digit result enough to justify its cost.

## Quadrants and special values

`C47_WP34S_Atan2` determines signs before arithmetic and implements these exact branches:

- A NaN coordinate returns NaN.
- Nonzero `y` with zero `x` returns signed `pi/2`.
- Signed-zero `y` with positive `x`, including positive zero, returns the sign of `y` on zero.
- Signed-zero `y` with negative `x`, including negative zero, returns signed `pi`.
- Infinite coordinate pairs return signed `pi/4` or `3*pi/4`; one infinite coordinate returns the corresponding signed axis value.
- Finite `x<0` adds `+pi` for positive `y` and `-pi` for negative `y`. The result is at least `pi/2` in magnitude, so the quadrant correction does not cancel leading
  digits.

Scalar `atan2` reports a domain error for two zero coordinates when special results are disabled. With special results enabled it exposes the signed-origin rules above.
Complex argument has no domain-error branch at the origin and now uses those same signed-origin rules.

Away from the origin, the differential

```text
d theta = (x*d y - y*d x)/(x^2+y^2)
```

gives `|d theta| <= ||d(x,y)||_2/sqrt(x^2+y^2)`. Uniform scaling therefore has no effect on the angle. The argument is undefined at the origin and discontinuous across
the negative real axis; the sign of an exact zero imaginary component selects the corresponding side.

## Argument routes

Real argument is unchanged. It returns zero for a positive real, 180 degrees for a negative real, propagates NaN, and preserves the sign of real zero when special
results are enabled. Angular-mode conversion then uses the existing p39 route.

The former complex route calculated `sqrt(real^2+imaginary^2)` even though argument discarded that magnitude. Its explicit polar special branches also converted
negative imaginary zero on the negative real axis to positive pi, and converted a negative finite imaginary component beside either signed real infinity to a
nonnegative axis value. Direct p39 atan2 removes the square, fused multiply-add, and square root while applying one quadrant implementation to scalar and matrix
complex values.

The former complex-matrix route narrowed the p39 radian angle to real34 before converting angular modes. The new route converts the p39 angle first and performs one
final real34 conversion under the selected calculator rounding mode.

## Rounding modes and verification

Intermediate work uses the fixed half-even p39 context. The final real34 conversion applies half-even, half-up, half-down, away from zero, toward zero, ceiling, or
floor. The file-driven scalar cases assert all seven modes against an independently evaluated 100-digit value of `atan(2/3)`. Other cases cover both sides of the 0.05
table boundary, the widest real34 exponent separation, signed zeros, every infinite quadrant, NaNs, the negative-real branch cut, and scalar and matrix complex
argument.

Before the argument change, the focused files reported the wrong side of the cut for negative imaginary zero, negative finite imaginary values beside negative
infinity, signed complex origins, and the corresponding complex-matrix element. The direct p39 route succeeds in all focused cases.

A source-reverted build succeeded in 102 of the 109 focused cases and failed the seven new behavioural assertions. The changed build succeeded in all 109 focused
cases. A clean `make test` run succeeded in all 14111 repository cases.

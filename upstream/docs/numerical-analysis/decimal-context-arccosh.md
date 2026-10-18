# Decimal context analysis for inverse hyperbolic cosine

## Scope and result

This analysis covers the scalar and complex Real34 routes in `arccosh.c`, the
shared `realArcosh` helper, and elementwise real and complex matrix application.
The Bessel caller of `realArcosh` retains its supplied context and is a dependency
rather than a user-visible inverse-hyperbolic-cosine route.

| Calculation | Former context | Selected context | Reason |
| --- | ---: | ---: | --- |
| finite scalar, `x >= 1` | p75 | p39 | a cancellation-free `ln1p` identity needs five guard digits rather than the complete 68-digit input square |
| finite complex components | p39 | p39 | distance-to-foci formulae remove cancellation and retain tiny components across the Real34 exponent range |
| real and complex matrices | p75 or p39 per element | p39 per element | matrix dispatch adds no arithmetic |

P39 is the narrowest established context among 34, 39, 51, and 75 digits for
both public routes. The wider contexts use round-to-nearest, ties-to-even, and
the final Real34 conversion applies the selected calculator rounding mode.
Differences confined to a p39-to-p34 rounding boundary are outside this analysis.

## Scalar route

For `x >= 1`, put `d = x-1`. The revised helper evaluates

```text
acosh(x) = log1p(d + sqrt(d(x+1))).
```

This is algebraically equal to `log(x+sqrt(x^2-1))`, but it does not subtract
one from a rounded value of `x^2`. When `1 <= x < 2`, `x-1` is exact by
Sterbenz's lemma. When `x >= 2`, subtraction from one has condition number at
most two. The addition `x+1`, product, square root, and addition of two
nonnegative terms are all well-conditioned.

Let `u39 = 5e-39`. Correct rounding of the elementary operations perturbs the
positive argument supplied to `WP34S_Ln1P` by less than `7u39` relatively,
apart from higher-order terms. The condition factor for a relative perturbation
of positive `t` in `log1p(t)` is

```text
t / ((1+t) log(1+t)) <= 1.
```

The compensated p39 `WP34S_Ln1P` dependency removes the rounded addition of one.
The natural-logarithm analysis bounds its elementary-operation contribution by
about `9.1e-37`. Including the input formation and compensation operations gives
the conservative scalar bound

```text
|computed acosh(x) - acosh(x)| / acosh(x) < 1.1e-36
```

for finite `x > 1`. At `x=1`, every operation and the result are exact zero.
This leaves more than two decimal digits beyond a 34-digit result.

The p39 exponent range is also necessary. The largest finite Real34 input has a
square near `1e12290`; this remains far inside the p39 work range but overflows a
p34 decimal128 context even though its inverse hyperbolic cosine is only about
14150. A p34 mutation failed four full-digit cases near one and the largest-input
case. P51 and p75 add no useful margin after the stable transformation.

The reusable `realArcosh` helper performs the same calculation at its supplied
context. The Bessel asymptotic route therefore receives the stability improvement
without changing its independently selected context.

## Complex component formulae

For finite `z=x+iy` with `y` nonzero, define the distances to the two branch
points

```text
r = sqrt((x+1)^2+y^2)
s = sqrt((x-1)^2+y^2)
A = (r+s)/2
delta = A-1
q = sqrt(A^2-1) = sqrt(delta(delta+2)).
```

The calculator's established branch convention selects

```text
sigma = sign(x),                 x != 0
sigma = sign(y),                 x = 0
u = sigma log1p(delta+q)
v = atan2(sigma y A, x q).
```

The confocal-ellipse identity

```text
x^2/A^2 + y^2/q^2 = 1
```

shows that `cos(v)=x/A` and `sin(v)=sigma*y/q`. Hence

```text
cosh(u+iv) = x+iy.
```

This convention gives a positive real component in the right half-plane, a
negative real component in the left half-plane, and a real-component sign equal
to the imaginary input on the imaginary axis. It matches the existing finite
values while removing the ill-conditioned intermediate `z^2-1` and the
subsequent complex logarithm.

## Stable formation of `delta`

Directly subtracting one from `A` would lose a small result. Rationalising both
distance increments gives the exact identity

```text
delta = max(|x|-1, 0)
      + y^2/2 * (1/(r+|x+1|) + 1/(s+|x-1|)).
```

Every term and denominator is nonnegative. For nonzero `y`, both denominators
are positive. The p39 magnitude dependency has relative error below `1.01e-38`.
Accounting for the square, denominator additions, divisions, positive sum, and
the optional base term gives the conservative bound

```text
|computed delta-delta| / delta < 1e-37.
```

The calculation of `q`, the positive sum `delta+q`, and the compensated
logarithm then gives a real-component relative error below `1.2e-36`. The bound
does not depend on how close `z` is to either branch point or to the open real
cut. A component of order `1e-4000` is therefore retained even though adding its
squared contribution to an order-one value would discard it.

## Complex angle

The `atan2` operands are scaled by the positive common factor `A*q`:

```text
sin(v) : cos(v) = sigma*y*A : x*q.
```

Their p39 products remain inside the work exponent range for every finite
Real34 pair. If their relative perturbations are `e1` and `e2`, first-order angle
sensitivity gives

```text
|d v| <= |e1-e2|/2.
```

Combining this with the `delta` and `q` bounds and the audited p39 `atan2` error
gives an absolute angle error below `5e-37` radians away from the zero-centred
table cell. In that cell the `atan2` dependency is relatively stable below
`2.1e-37`, so a tiny nonzero angle retains the same margin.

P34 has no comparable margin. A deliberate 34-digit precision mutation using
the wide exponent range failed four directed-mode, full-digit component checks.
A true p34 context also underflows `y^2` for inputs such as `y=1e-4000`, despite
the corresponding Real34 result component remaining representable. P39 is
therefore the narrowest established context; p51 and p75 are unnecessary after
rationalisation.

## Real axis, branches, and special values

For an exact zero imaginary component, separate formulae avoid `0/0` at the
branch points:

- `|x| <= 1` returns an exact zero real component and
  `atan2(sqrt((1-x)(1+x)),x)` in `[0,pi]`;
- `x > 1` uses the scalar positive result with a positive zero angle;
- `x < -1` negates the scalar result and returns `+pi` for either zero sign.

This removes the spurious `-1e-39` real part formerly produced at `0.5+i0`.
Near `x=+/-1`, a nonzero imaginary component produces both square-root-scale
components without subtracting nearly equal order-one quantities.

NaN in either component returns two NaNs. Infinite inputs use the limits of the
same branch convention. Examples include

```text
acosh(+infinity+i0)       = +infinity+i0
acosh(-infinity+i0)       = -infinity+i*pi
acosh(-2+i*infinity)      = -infinity-i*pi/2
acosh(0-i*infinity)       = -infinity+i*pi/2
acosh(-infinity-i*infinity) = -infinity+i*3*pi/4.
```

## Matrix route and verification

`processRealComplexMonadicFunction` sends real and complex matrices through the
same scalar entry functions one element at a time. Each element is converted to
Real34 once after the p39 calculation. No matrix-level operation adds error.

Independent 300-digit decimal evaluation gives

```text
acosh(0.5 + 1.234567890123456789012345678901234e-34 i)
  = 1.4255562073912922006985226113506011191692854...e-34
  + 1.0471975511965977461542144610931676280657231... i.
```

The file-driven checks assert all 34 digits under all seven rounding modes by
subtracting the expected complex value and scaling the residual. They also cover
the Real34 exponent extremes, both branch points, the open cut, signed zero,
NaNs, every representative infinite direction, and real and complex matrices.

With the unchanged implementation, 97 of 116 focused checks succeeded and 19
failed. The failures cover the cut neighbourhood, branch-point components,
special values, and complex matrix elements. The
selected implementation succeeds in all 116 focused checks.

A clean build followed by the complete integrated suite succeeds in all 15,000
checks with no failures in 236.31 seconds.

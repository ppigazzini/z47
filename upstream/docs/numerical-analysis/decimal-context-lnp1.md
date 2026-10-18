# Decimal context analysis for `ln(1+x)`

## Result

`fnLnP1` has three numerical routes:

| Route | Context before this change | Selected context | Reason |
| --- | ---: | ---: | --- |
| finite scalar real | 39 | 39 | five guard digits are retained for the compensated `WP34S_Ln1P` calculation |
| small complex series, `|z| < 10^-6` | 75 | 51 | the series remainder and rounded-operation bounds leave more than thirteen guard digits |
| other finite complex values | 75 | 75 | products of decimal128 components can require 70 digits before cancellation around the unit circle |

The fixed working contexts keep round-to-nearest, ties-to-even. The selected user mode is applied when the wide result is converted to decimal128. The analysis does not
change this established division of work.

The claims involving `WP34S_Ln` and `WP34S_Ln1P` are conditional on those helpers returning their requested working precision with a modest operation-error constant.
Their independent audits remain pending. The elementary additions, subtractions, multiplications, divisions and square roots are treated as correctly rounded at their
working widths.

## Scalar real route

The domain guard forms `r = 1+x` at 39 digits. A decimal128 input close enough to `-1` for cancellation has an exact sum at this width. Thus `x=-1` is detected exactly,
the two adjacent finite sides retain the small signed residual, and the existing real, complex and special-result branches remain unchanged. Signed zero is copied by
`WP34S_Ln1P`; infinities and the `x=-1` branch are resolved before the finite calculation.

For tiny `x`, `WP34S_Ln1P` computes `u = RN(1+x)` and `v = RN(u-1)`. If `v` is zero it returns `x`. The relative error in that shortcut satisfies

```text
|log(1+x) - x| / |x| <= |x| / (2(1-|x|)).
```

An `x` lost by a 39-digit addition at one has magnitude at most about `5e-39`, so the bound is below `2.6e-39`. Otherwise the ratio `x/v` compensates the rounded addition
before multiplication by `log(u)`. Near `x=-1`, the exact small `u` goes directly to the logarithm helper. For a positive `x` large enough that the added one disappears,
`log(1+x)-log(x) = log(1+1/x) < 1/x`, which is already below the five-digit working margin.

A 34-digit working context leaves no allowance for the addition, compensation ratio and logarithm dependency. The 39-digit context is therefore retained. The fixed
half-even working mode is also retained because changing every internal operation to a directed mode changes the approximation error of `WP34S_Ln` rather than merely
selecting the final decimal128 rounding.

## Small complex series

For `r = |z| < 10^-6`, the 51-digit route selects `n = (51/5) | 1 = 11` and includes terms through degree 12:

```text
S12 = z - z^2/2 + ... - z^12/12.
```

The omitted terms satisfy

```text
|R12| <= r^13 / (13(1-r)) < 7.693e-80.
```

Also,

```text
|log(1+z)| >= r - r^2/(2(1-r)),
```

so the relative truncation error is below `7.7e-74`. A conservative count of fewer than 150 rounded real operations covers the compensated complex products, divisions
and additions. With half-even unit roundoff `u = 5e-51`, `gamma(150) < 7.6e-49`. The sum is dominated by its first term because all later magnitudes total less than
`r^2/(2(1-r))`; allowing a wider constant for component cancellation still leaves at least thirteen digits beyond the decimal128 result.

At 39 digits the corresponding rounded-operation allowance is only about two to three digits beyond the result width. It cannot support the required accuracy margin.
At 75 digits the degree-16 series has absolute truncation error below `5.883e-104` and relative truncation error below `5.9e-98`, which is far more than required. The
51-digit cap is consequently the narrowest available project context supported by these bounds.

## Complex values away from the small series

Write `w = 1+z = a+ib`. The real component is

```text
Re(log(w)) = log(sqrt(a^2+b^2)) = log(a^2+b^2)/2.
```

The former magnitude-then-log calculation is ill-conditioned when `a^2+b^2` is close to one. A correctly rounded 75-digit square root has a small absolute error, but
`log(rho)` amplifies that error without limit as `rho` approaches one. For `rho` between one half and two, the revised calculation forms

```text
delta = a^2+b^2-1 = (a-1)(a+1) + b^2
Re(log(w)) = log1p(delta)/2.
```

The factored expression avoids subtracting one from a rounded square. Here `a=1+Re(z)` has at most 35 significant digits, `(a-1)(a+1)` has at most 70, and `b^2` has
at most 68. The 75-digit context therefore evaluates each product without discarding a coefficient digit and gives the final fused addition five further digits. A
51-digit context can discard 19 digits from the first product and 17 from the second before their cancellation is exposed, so it cannot guarantee a 34-digit result.

Outside this annulus, `|log(rho)| >= log(2)` and the direct magnitude-then-log route is well-conditioned. It remains unchanged. The angle still comes from the 75-digit
`atan2` route, preserving the principal branch on both sides of the negative-real cut. The exact branch point `z=-1+0i` remains handled before this calculation.

## Regression values

The new unit-circle case uses

```text
z = -2 + 1.234567890123456789012345678901234e-34 i
w = -1 + 1.234567890123456789012345678901234e-34 i
```

An independent 200-digit decimal calculation gives

```text
Re(log(w)) = 7.6207893766194183752476757812833339615150760567139...e-69.
```

The tests assert digit 34 after exact subtraction and scaling in all seven rounding modes. The lower side of the branch cut uses the negative imaginary component and
asserts

```text
Im(log(w)) = -3.141592653589793238462643383279503
```

at 34 digits under round-to-nearest, ties-to-even. The magnitude-first implementation loses most significant digits of the tiny real component; the factored calculation
retains it.

## Special values

NaN propagates. With special results enabled, positive infinity returns
positive infinity whether or not complex results are enabled. Negative
infinity returns NaN when complex results are disabled and the principal value
`+infinity + i*pi` when they are enabled. With special results disabled, either
infinity sign reports the established domain error. Tests cover tagged and
untagged positive infinity and both complex-result settings.

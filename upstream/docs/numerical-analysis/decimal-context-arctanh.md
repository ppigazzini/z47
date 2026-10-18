# Decimal context analysis for inverse hyperbolic tangent

## Scope and result

This analysis covers the scalar, complex, real-matrix, and complex-matrix routes in `arctanh.c`, the shared `WP34S_ArcTanh` helper, and the direct dependencies
`WP34S_Ln1P` and `C47_WP34S_Atan2`.

| Calculation | Former context | Selected context | Result |
| --- | ---: | ---: | --- |
| finite scalar with `|x| < 1` | 39 | 39 | two compensated logarithms avoid a delicate transformed argument near `-1` |
| finite complex components | 39 | 39 | direct component formulae avoid the ill-conditioned complex quotient |
| real and complex matrix elements | 39 | 39 | each decimal128 element uses the corresponding scalar route |

The revised complex route is accurate across the decimal128 exponent range without a 51-digit or 75-digit intermediate. The 39-digit context is the narrowest
established context with a defensible 34-digit margin and a work exponent range wide enough for squared decimal128 components. The results are faithfully accurate to
34 digits. Universal correct rounding after the final 39-to-34 conversion is not claimed, and differences confined to that conversion are outside this analysis.

The fixed work mode is round-to-nearest, ties-to-even. Conversion to decimal128 applies the selected calculator mode.

## Scalar calculation

For `-1 < x < 1`, the revised helper evaluates

```text
atanh(x) = (log1p(x) - log1p(-x))/2.
```

The two logarithms have opposite signs for every nonzero input. Their subtraction therefore adds magnitudes and introduces no cancellation. A decimal128 input and
its negation are exact in the 39-digit work format. The `WP34S_Ln1P` analysis gives a relative shortcut error below `2.6e-39` when `x` disappears in `1+x`; otherwise
its correction ratio removes the rounded-addition error. The p39 `WP34S_Ln` analysis bounds its elementary-operation contribution below `9.1e-37`. Allowing the
compensation operations, the subtraction, and the final multiplication gives the conservative bound

```text
|computed atanh(x) - atanh(x)| / |atanh(x)| < 1.1e-36.
```

This also covers decimal128 values adjacent to either branch point. Exact positive and negative zero use a separate zero branch, with the sign retained. Exact
`+/-1`, out-of-domain finite values, infinities, and NaNs use the existing flag-controlled branches before the finite helper.

At 34 digits, the corresponding logarithm operation count permits an error near `9.1e-32`, so there is no 34-digit accuracy margin. The 39-digit context is the
narrowest established choice for this route.

## Complex real component

For `z = a+ib`, put `alpha = |a|`. The real component is evaluated as

```text
D = (1-alpha)^2 + b^2
r = 4*alpha/D
Re(atanh(z)) = sign(a)*log1p(r)/4.
```

Both terms in `D` are nonnegative. Near `alpha=1`, where `D` can be small, subtraction of the decimal128 `alpha` from one is exact at 39 digits. Away from that region
the subtraction is well-conditioned. If a tiny `alpha` disappears in the subtraction, the resulting relative perturbation of `D` is below the p39 rounding scale.
If `alpha` is so large that one disappears, `D` is dominated by `alpha^2`.

With `u39 = 5e-39`, the subtraction, square, fused square addition, and division give a relative perturbation below `5u39` in `r`, apart from higher-order terms.
The relative condition factor of `log1p` for a relative perturbation in positive `r` is

```text
r / ((1+r)*log(1+r)) <= 1.
```

The audited p39 logarithm bound and the two final half multiplications therefore give a conservative relative error below `1.1e-36` for every nonzero finite real
component. When `r` disappears in `1+r`, the `WP34S_Ln1P` shortcut has a smaller relative error. When the added one disappears beside a large `r`, the difference
between `log(1+r)` and `log(r)` is less than `1/r` and is also below the required margin.

The former quotient first formed `1+z` and `1-z`. It discarded `a` when `|a|` was much smaller than one, and discarded the added or subtracted one when `|a|` was
much larger than one. The subsequent division and logarithm could not recover the lost real component. The direct positive-ratio formula removes both failures and
does not depend on the complex-division kernel.

## Complex imaginary component

The imaginary component is evaluated as

```text
P = (1-a)*(1+a)
q = P-b^2
y = 2*b
Im(atanh(z)) = atan2(y,q)/2.
```

For `|a| <= 1`, both factors in `P` are exact at 39 digits for a decimal128 input. The product and fused subtraction give

```text
|delta q| <= 2*u39*(P+|q|)
```

apart from second-order terms. With `t=|b|`, `q=P-t^2`, and `y=2t`, angle sensitivity to `q` gives

```text
|d atan2(y,q)/d q| = 2t/(q^2+4t^2).
```

The factor

```text
2t*(P+|q|)/(q^2+4t^2)
```

is at most two. For `q >= 0`, use `P=q+t^2`, `t<=1`, `4tq<=2(q^2+t^2)`, and `2t^3<=2t^2`. For `q < 0`, its maximum is below one half for `t<=1`, while for
`t>=1` the denominator is at least `(t^2-1)^2+4t^2=(t^2+1)^2`, whose resulting maximum is `3*sqrt(3)/8`. Thus cancellation where `a^2+b^2` is close to one does not
amplify the product error beyond a small constant.

For `|a| > 1`, `P` and `-b^2` have the same sign, so `q` has no cancellation and its relative error is below a small multiple of `u39`. The multiplication by two is
exact for a decimal128 `b`. The established p39 `atan2` bound is below `3e-37` radians away from its zero-centred table cell and below `2.1e-37` relatively within that
cell. After division by two, the total absolute error is below `1.7e-37` radians outside the zero-centred cell. Within that cell `q` has no severe cancellation, and
the relative error is below `3e-37`. These bounds provide the required margin for both ordinary and tiny nonzero imaginary components.

The factorisation of `1-a^2` retains the distance from the unit-circle transition. The sign of an exact zero `b` reaches `atan2`, selecting the upper or lower side of
each real-axis cut.

## Range, branch points, and matrices

A finite decimal128 component has adjusted exponent from `-6176` through `6144`. Every square has adjusted exponent between about `-12352` and `12288`, and each ratio
used above has magnitude inside the `+/-999999` exponent range of `ctxtReal39`. The direct formulae therefore avoid work-format overflow and underflow. A 34-digit
decimal128 context would not provide this range.

The special branches implement these principal values:

- A NaN component returns two NaN components.
- Any infinite component, with no NaN, returns a real zero signed from `a` and `+/-pi/2` signed from `b`.
- `+/-1` with a zero imaginary component returns the corresponding signed real infinity and copies the imaginary zero.
- A finite point on either real-axis cut uses the sign of its imaginary zero to select `+pi/2` or `-pi/2`.
- The complex origin retains both zero signs.

Complex inverse hyperbolic tangent is dimensionless and returns its imaginary component in radians, independent of the selected angular mode. Matrix processing places
each decimal128 element in the scalar register path, so the same error and branch analysis applies without an additional matrix arithmetic stage.

## Independent values and verification

An independent 220-digit decimal evaluation used the defining real logarithms and an atan series with Machin's formula for pi. Representative values are

```text
atanh(-0.9999999999999999999999999999999999)
  = -39.490520171178749283014470790363279788256475373869...

atanh(1.234567890123456789012345678901234e-50 + i)
  = 6.172839450617283945061728394506169999999999999...e-51
    + i*0.785398163397448309615660845819875721049292349843...

atanh(1 + 1.234567890123456789012345678901234e-34*i)
  = 39.385159660020923002486969935118968102132863311166...
    + i*0.785398163397448309615660845819875751913489602930...
```

For the largest finite positive decimal128 value, the real component starts

```text
1.0000000000000000000000000000000001000000...e-6145.
```

The file-driven cases cover all seven rounding modes, both exponent extremes, signed zeros, exact and nearby branch points, both cut sides, infinities, NaNs, and real
and complex matrices. With the former source, the focused file lost tiny and extreme real components, returned NaNs at exact branch points and infinities, and selected
the wrong cut side for negative zero. That source succeeded in 76 of 90 cases. The revised source succeeds in all 90.

# Decimal context analysis for direct curve-fit evaluation

## Scope and result

This analysis covers the decimal forecast and inverse routes in `fnYIsFnx`, `fnXIsFny`, `yIsFnx(useREAL39, ...)`, and `xIsFny`. Coefficient estimation remains
unchanged and produces p75 working values. The native `useFloating == 0` plotting route remains unchanged.

| Fit | Forward context | Inverse context | Main reason |
| --- | ---: | ---: | --- |
| linear and orthogonal | 75 | 39 | forward product and intercept can cancel; inverse subtraction is one correctly rounded operation |
| exponential | 51 | 75 | forward exponential composition needs the audited p51 margin; inverse logarithms can cancel |
| logarithmic | 75 | 39 | forward product and intercept can cancel; finite inverse exponential bounds its p39 argument error |
| power | 51 | 75 | forward power uses the audited p51 route; inverse exponent formation can amplify a logarithmic difference |
| root | 51 | 75 | forward power uses the audited p51 route; inverse denominator is a logarithmic difference |
| hyperbolic | 75 | 75 | both directions can expose a small difference between order-one terms |
| parabolic | 75 | 75 | polynomial cancellation and the two-root calculation use p75 coefficient information |
| Gaussian | 51 | 75 | forward exponential composition needs p51; centred inverse roots need p75 product recovery |
| Cauchy | 75 | 75 | denominator and centred inverse roots can cancel |

The contexts use round-to-nearest, ties-to-even. `convertRealToResultRegister` applies the selected mode at the Real34 result boundary. A single p34 operation is
cost-neutral, but these routes contain chained work. P34 supplies no intermediate margin and repeated p34 operations can cost more through unpacking and repacking.

For a correctly rounded elementary operation at p digits, use `u_p = 0.5 10^(1-p)` and `gamma_n = n u_p/(1-n u_p)`. Thus

```text
u39 = 5e-39,  u51 = 5e-51,  u75 = 5e-75.
```

## Forward evaluation

The linear and orthogonal forms evaluate `a0 + a1*x`. The logarithmic form replaces `x` by `ln(x)`, and the hyperbolic form uses the same sum as a denominator.
The parabolic and Cauchy forms contain equivalent additive stages. A rounded product error is amplified by

```text
K = |product| / |sum|
```

when the sum is small. `K` is unbounded, so no fixed context proves 34 relative digits for every fitted data set and forecast point. P75 is nevertheless the
narrowest established width that preserves all available fitted-coefficient digits through a useful cancellation range. P39 or p51 would discard coefficient
information before the result is formed.

The stored linear fit has exact mathematical coefficients `a0=1` and `a1=1/3`. At

```text
x = -2.999999999999999999999999999999999
y = 3.333333333333333333333333333333333...e-34.
```

A deliberate p51 evaluation returns only `3.33333333333333333e-34`, with 18 correct significant digits. P75 returns the expected Real34 result in all seven output
modes. The original p39 route retained only six significant digits. This case distinguishes p75 from every narrower established context.

The parabolic expression now uses Horner form,

```text
y = (a2*x + a1)*x + a0,
```

which removes one multiplication and one separately rounded term. The remaining additions still require p75 because either may cancel.

Exponential, power, root, and Gaussian forecasts contain no closing addition on the output route. Their exponent or power formation uses p51. The completed general
power analysis bounds fewer than 180 logarithm calculations by `gamma_180 < 9.1e-49` at p51. A finite nonzero Real34 exponential result constrains the effective
exponent magnitude to less than 14,222 unless a finite fitted scale compensates it. Even using the helper's wider formation interval, the p51 argument error stays
well below one Real34 result unit. P39 has no defensible margin for the corresponding composed power; the general-power audit found errors above `1e-32` in its
exponent and a concrete wrong digit 34. P51 is therefore the narrowest established width for these non-additive forecast forms. The fitted nonintegral-power case in
the curve-fit test file exercises this route through result digit 34.

## One-root inverse forms

Linear and orthogonal inversion use

```text
x = (y-a0)/a1.
```

Correctly rounded subtraction operates on the complete operands before rounding its result, so cancellation does not first shorten either input. The following
division gives a relative arithmetic error bounded by `gamma_2 < 1.1e-38` for a nonzero result. P39 provides five decimal guard digits and is the narrowest useful
intermediate width.

Logarithmic inversion uses

```text
x = exp((y-a0)/a1).
```

For a finite nonzero Real34 result, the exponential argument has magnitude below about 14,222. Its p39 formation error is below `1.6e-34` in absolute value, before
the audited p39 exponential error of at most `1e-38` relatively. This remains below half of a Real34 relative result unit away from a conversion boundary. P39 is
therefore adequate under the accepted p39-to-p34 boundary exclusion.

Exponential inversion now forms

```text
x = (ln(y)-ln(a0))/a1
```

instead of `ln(y/a0)/a1`. Computing a p39 quotient first can round a ratio close to one before the logarithm exposes its small difference. The logarithm difference
also avoids premature quotient overflow or underflow. Both logarithms and the subtraction use p75 because cancellation can expose the low fitted-coefficient digits.

For positive power inputs, inversion uses

```text
x = exp((ln(y)-ln(a0))/a1).
```

P75 protects the logarithmic difference and its possibly large reciprocal exponent. Nonpositive and special inputs retain the established `xthRootReal` route, now
requested at p75, so negative-base real roots and existing error behaviour remain available.

Root inversion uses

```text
x = ln(a1)/(ln(y)-ln(a0)).
```

The denominator can be arbitrarily small, so p75 is required to preserve the fitted values. Hyperbolic inversion changes from `1/y-a0`, where the rounded division
can lose the later difference, to

```text
x = (1-a0*y)/(a1*y).
```

The cancellation now occurs before division and all operations use p75.

## Two-root inverse forms

For `a*x^2+b*x+c=0`, direct evaluation of

```text
(-b +/- sqrt(b^2-4*a*c))/(2*a)
```

loses the smaller root when `b` and the square root nearly agree. The revised parabolic route computes

```text
q = -0.5 * (b + copysign(sqrt(b^2-4*a*c), b)),
r_far = q/a,
r_near = c/q.
```

The root order remains the public minus-root then plus-root order. For the exact fit `y=x^2+x` and

```text
y = 1.234567890123456789012345678901234e-50,
```

the direct p75 formula returns only 24 correct significant digits in the small root and leaves a scaled residual of `1.78901234e15`. The product formula returns all
34 expected digits. The other root rounds to `-1`.

Cauchy inversion first forms

```text
r^2 = (1-a2*y)/(a0*y),  c = -a1,
```

and Gaussian inversion forms

```text
r^2 = a2*(ln(y)-ln(a0)),  c = a1.
```

Both models have roots `c-r` and `c+r`. The route evaluates the root whose sign agrees with `c` directly, then obtains the other from

```text
(c^2-r^2)/r_far.
```

This removes the final subtraction for the small root. P75 retains enough digits in `c^2-r^2` for the Real34 inputs exercised here. Stored adjacent-value cases
produce `5e-35` for a Cauchy fit and `2.171472409516259138255644594583025e-34` for a Gaussian fit; the former direct expressions lose these small components.

NaN, infinity, and a degenerate parabolic coefficient use the direct formulas. The product identities can otherwise introduce an avoidable infinity divided by
infinity. Finite ordinary values use the stable formulas.

## Conditioning limit and verification

No fixed width guarantees 34 relative digits when a forecast is arbitrarily close to a model zero, a logarithmic inverse denominator approaches zero, or two
inverse roots have an arbitrarily large magnitude ratio. P75 preserves every available fitted-coefficient digit and extends the useful cancellation range by 36
digits over p39. Stable logarithmic, rational, and root identities prevent avoidable early rounding within that range.

The cases are in the existing `curvefit_cov.txt` file. They cover all fit selections, every output rounding mode for a digit-34 cancellation, p51 composed-power
evaluation, stable parabolic, Cauchy, and Gaussian small roots, and direct inverse checks.

With the original p39 forecast and quadratic inverse, the initial two exact cases each failed both their direct and scaled checks. With a deliberate p51 linear
forecast, 111 of 125 focused checks succeeded; all seven linear values and their seven scaled residuals failed. With the direct p75 quadratic formula, 123 of 125
checks succeeded. The selected contexts and stable formulas succeed in all 125 focused checks.

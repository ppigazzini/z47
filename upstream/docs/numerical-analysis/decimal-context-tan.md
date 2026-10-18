# Decimal context analysis for tangent

## Scope

This analysis covers the public scalar, complex, and matrix tangent paths and the shared `TanComplex` kernel. It relies on the separate sine/cosine reduction analysis and the real exponential analysis. The relative-error claim for very small imaginary parts is conditional on the separate `WP34S_ExpM1` audit.

The accepted 39-to-34-digit boundary effect is outside this analysis.

## Recommendations

For a scalar result, request the selected 34-digit context from `C47_WP34S_Cvt2RadSinCosTan`. The helper still uses the following internal widths:

- 12,321 digits for radian reduction on builds with sufficient memory;
- 75 digits for unit conversion and the reduced angle;
- 51 digits for the sine/cosine series and tangent division;
- 34 digits only for the selected final output mode.

For a public complex result, use 39 digits with the exponential representation described below. The former 51-digit hyperbolic representation is unnecessary after this rewrite. Callers that supply a wider context continue to receive that width.

## Scalar tangent

The shared trigonometric helper folds the angle into the first octant. It evaluates sine and cosine at 51 digits and forms either

```text
sin(a) / cos(a)
```

or its reciprocal after the complementary-angle fold. The sine series has the form `a*S(a)`, where `S(a)` is close to one. Consequently a small folded angle retains relative accuracy. This is important near a tangent pole, where the result is the reciprocal of that small angle. The division itself is assumed correctly rounded at its working width.

The sine/cosine analysis bounds the 51-digit series arithmetic below `1.6E-46` relative error and keeps the wide phase until quadrant selection is complete. The final helper conversion is the first operation performed at the requested 34-digit context. Asking for 75 digits at the public entry therefore did not improve the stored result.

The file-driven cases for `tan(0.3)` use exact subtraction and scaling to check every output mode through digit 34. The 34-digit request succeeds in all seven modes.

## Stable complex formula

The former code evaluated

```text
(sin(a) cosh(b) + i cos(a) sinh(b))
-------------------------------------------------
(cos(a) cosh(b) - i sin(a) sinh(b))
```

and then used generic complex division. For large `|b|`, both hyperbolic values overflow even though the exact tangent approaches `sign(b)i`. Products in the numerator and denominator can also reach the same large scale before division.

Set

```text
t = exp(-2|b|)
m = 1 - t = -expm1(-2|b|).
```

Multiplying the standard double-angle formula by `2t` gives

```text
D  = m^2 + 4t cos(a)^2
Re = 4t sin(a) cos(a) / D
Im = sign(b) m(1+t) / D.
```

All terms in `D` are nonnegative. No subtraction of nearby working values occurs: `m` comes from `expm1`, and `D` is a sum. The real-axis branch uses the direct sine/cosine quotient and copies the input zero sign before result conversion.

For finite nonzero components, perturbations in the supplied `sin`, `cos`, `t`, and `m` values are not amplified by cancellation in the new arithmetic. Near a mathematical zero, an absolute bound is appropriate; no uniform componentwise-relative claim is possible. Sensitivity near a real tangent pole is inherent in the function rather than introduced by the formula.

There are 13 correctly rounded elementary operations outside the three shared helpers. With directed-rounding unit `u39=1E-38`, their standard product bound is

```text
gamma_13 = 13u39 / (1 - 13u39) < 1.31E-37.
```

The audited trigonometric and exponential helpers contribute errors at the same or a smaller scale. Once the `expm1` dependency supplies its corresponding relative bound, the complete nonzero-component estimate is their sum plus this fixed arithmetic term and second-order products. At 34 digits the fixed arithmetic term alone can reach `1.31E-32`, so a complete 34-digit margin is unavailable. A deliberate 34-digit complex mutation changed the imaginary result of `tan(0.3+0.4i)` by one decimal128 unit. Thus 39 digits is the narrowest established existing context for the public complex route.

If `t` underflows in the 39-digit work context, `|b|` is so large that its correction is far below the decimal128 result range. The exact decimal128 limit is then `0 + sign(b)i`, which the formula produces without a positive exponential or a hyperbolic overflow.

## Special values

For finite real part and imaginary part `+/-Infinity`, the rewritten formula gives `0 +/- i`. A NaN in either input propagates to both components. An infinite real part makes the trigonometric factors NaN and therefore gives two NaNs. On the real axis, the direct quotient preserves the negative zero internally; the ordinary complex-result conversion applies the project's established zero representation.

## Tests

The new cases are in the existing `tan.txt` file-driven suite. They cover all seven scalar rounding modes, an ordinary exact digit-34 complex result, a finite imaginary argument whose hyperbolic representation overflows, positive and negative imaginary infinity, a finite point near a real pole, and a real-axis signed zero.

With the final cases present, the former complex implementation succeeds in 60 of 63 checks. Its failures are the finite-overflow sign check and both imaginary-infinity limits. The rewritten implementation succeeds in all 63 checks. A deliberate complex 34-digit mutation succeeds in 62 of 63 checks and misses the ordinary complex result by one unit in its imaginary component.

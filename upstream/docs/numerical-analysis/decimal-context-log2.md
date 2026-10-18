# Decimal context analysis for base-two logarithm

## Result

The public decimal128 routes use these working contexts:

| Calculation | Selected context | Reason |
| --- | ---: | --- |
| finite positive scalar | 39 | the precision-39 natural logarithm and one division retain a sufficient margin beyond decimal128 |
| complex magnitude, angle and values away from the unit circle | 39 | these calculations remain well-conditioned for the real component away from magnitude one |
| complex real component for `1/2 < |z| < 2` | 75 | decimal128 component squares can cancel through 68 coefficient digits |

The scalar route remains `Ln(x)/ln(2)` at 39 digits. The public complex route now evaluates its sensitive real component as

```text
Re(log2(a+ib)) = log1p(a^2+b^2-1) / (2 log(2))
```

at 75 digits near the unit circle. The angle and its division by `log(2)` remain at 39 digits. The scalar `log2Real` entry continues to use `logxyReal`, while the
complex `log2Cplx` entry has its own rectangular calculation. The long-integer and short-integer entries are outside this audit.

All fixed working contexts use round-to-nearest, ties-to-even. The user-selected mode is applied when the wide result is converted to decimal128. Differences caused
only by a 39-digit half-even intermediate landing on a decimal128 directed-rounding boundary are outside this decision.

## Scalar route

For a positive finite input, the implementation computes

```text
y = WP34S_Ln(x)
result = y / L39,
```

where `L39` is the 39-digit value of `log(2)`. The natural-logarithm audit establishes precision 39 as the narrowest project context supported for a decimal128 input.
Its reduced series has `|a| <= 0.2`, an omitted-tail bound below `1e-38/24`, and fewer than 180 rounded elementary operations. The conservative operation bound is
`gamma(180) < 9.1e-37`. Precision 34 has no adequate margin before the base conversion is included.

Let the relative natural-logarithm error be `e_ln`, the relative constant error be `e_L`, and the precision-39 division unit roundoff be `u=5e-39`. Away from the exact
zero at `x=1`, the base conversion has relative error bounded by

```text
(|e_ln| + |e_L| + u + second-order terms) / (1-|e_L|).
```

The 39-digit constant gives `|e_L| < 5e-39`. The extra division is small against the established logarithm bound. At `x=1`, the natural logarithm and division both
return exact zero. For a decimal128 input next to one, subtraction from one is exact in the precision-39 logarithm route, and division by `L39` is well-conditioned.
An exact regression also checks the real input `2`, whose base-two logarithm is one.

Finite decimal128 adjusted exponents range from -6176 through 6144, while the precision-39 context uses exponent limits of plus or minus 999999. The logarithm's stored
exponent reduction and every intermediate remain in range. Exact tests use the minimum positive subnormal and the largest finite decimal128 input. A 34-digit context
is not supported by the natural-logarithm bound, while 51 and 75 digits add no useful accuracy for the public scalar result. Precision 39 is therefore retained.

## Complex real component

The magnitude-first expression

```text
log2(sqrt(a^2+b^2))
```

is ill-conditioned when the magnitude is close to one. A small absolute error in the rounded magnitude is divided by a real result approaching zero. Dividing by
`log(2)` changes the scale but not this unbounded condition number.

Within the annulus selected by the precision-39 magnitude, the revised public complex route forms

```text
delta = (d-1)(d+1) + s^2,
```

where `d` is the rectangular component with greater absolute value and `s` is the other component. This choice retains the square of a very small component when the
greater component is exactly `+1` or `-1`. It also avoids subtracting one from a rounded squared magnitude.

For decimal128 input in this annulus, `d` is comparable with one. Its additions with one are exact at 75 digits, their product needs at most 70 coefficient digits, and
`s^2` needs at most 68. The fused addition retains at least five further digits when the terms can cancel. If their exponents are widely separated, the smaller term
cannot affect the decimal128 result unless the greater product is zero, in which case the fused operation retains the small square.

After `delta` is formed, `WP34S_Ln1P(delta)` uses the audited compensated logarithm route. A tiny `delta` keeps `1+delta` in the natural-logarithm interval that avoids
the 39-digit exponent constant, so the calculation benefits from the full 75-digit context. The final division uses `L39`; its relative constant error is below
`5e-39`, leaving almost five decimal guard digits.

Precision 51 is insufficient. For

```text
a = 0.7
b = 0.7141428428542849997999399811367265,
```

an independent 220-digit decimal calculation gives

```text
a^2+b^2-1 = -3.981577319274742665135691286419775e-35
Re(log2(a+ib)) = -2.8721009267168220903385563505303218523...e-35.
```

At 51 digits, information is lost in the order-one products before their cancellation is exposed. The exact regression differs from digit 18 of the decimal128 result,
with a residual of `2.5149282642552033e-52`. The 75-digit context succeeds and is the narrowest established context supported for every decimal128 point in the annulus.

Outside the annulus, `|log2(|z|)| >= 1`, apart from a harmless displacement at a selection boundary caused by magnitude rounding. The direct magnitude,
natural-logarithm and division route is well-conditioned there. The magnitude supplies the angle and selects the real-component formula; it does not supply the
sensitive real component inside the annulus.

## Angle and branch cut

The imaginary component is

```text
atan2(b,a) / log(2)
```

in the principal interval `(-pi/log(2), pi/log(2)]`. The angle is calculated and divided at 39 digits. The negative-real cut approaches the positive endpoint for a
positive imaginary component and the negative endpoint for a negative imaginary component. An exactly zero imaginary component, including negative zero, uses the
existing positive endpoint when the real component is negative.

This angle conclusion is conditional on the pending independent `atan2` audit. The complex magnitude has a separate precision-39 error analysis and is used only for
the angle and route selection here. The sensitive real calculation uses real multiplication and fused addition; it invokes no complex multiplication or division.

## Zero, NaN and infinity

Positive and negative scalar zero produce negative infinity when special results are enabled and otherwise report a domain error. Complex zero follows the same rule
and returns `-infinity+0i` when enabled. The sign of an input zero does not change this result.

NaN input propagates to NaN. With special results enabled, positive scalar infinity returns positive infinity independently of the complex-result flag. Negative
scalar infinity returns NaN when complex results are disabled and the principal complex value when they are enabled. Complex infinities produce an
infinite real component and the quadrant angle divided by `log(2)`.

## Regression values

For

```text
z = -1 + 1.234567890123456789012345678901234e-34 i,
```

an independent 220-digit decimal calculation gives

```text
Re(log2(z)) = 1.0994475041308129748666595107766521670...e-68.
```

Exact subtraction and scaling assert digit 34 in all seven output rounding modes. The magnitude-first implementation returns zero and fails all seven cases. The lower
side of the branch cut asserts `-4.532360141827193809627682945716667` under round-to-nearest, ties-to-even. Further exact cases exercise a power of two, a scalar next
to one, both decimal128 exponent limits, the 75-versus-51 cancellation case, signed zero and complex special values.

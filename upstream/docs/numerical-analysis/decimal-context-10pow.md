# Decimal context analysis for `10^x`

## Scope and result

This analysis covers the scalar and complex decimal128 entry routes in `src/c47/mathematics/10pow.c`. Short and long integers are excluded. The matrix routes reuse these scalar and complex functions element by element.

| Route | Previous work | Selected work | Result |
| --- | --- | --- | --- |
| finite scalar | `x * ln(10)` and `exp` at p39 | fractional exponent at p39, exact decimal scaling | p39 is the narrowest established context |
| integral scalar | `x * ln(10)` and `exp` at p39 | exact coefficient and exponent | no rounded arithmetic is needed |
| complex magnitude | `a * ln(10)` and `exp` at p39 | scalar formulation above | p39 is retained |
| complex phase | `b * ln(10)` and trigonometry requested at p39 | p75 product with p75 `ln(10)`, then p75 trigonometry | p75 is the narrowest established fixed context for the tested range |
| final complex products | p39 | p39 | no cancellation occurs in either product |

The p39 scalar result is conditional on the pending `realExp` audit. The p75 complex result is conditional on the pending sine and cosine kernel audit. `realPolarToRectangular` performs angle reduction before those kernels.

## Scalar error analysis

Write a finite decimal128 input as

```
x = n + f,  n = trunc(x),  |f| < 1.
```

The revised formulation computes

```
10^x = 10^n exp(f ln(10)).
```

The factor `10^n` is represented by changing the decimal exponent. This change is exact. An integral input in the working context range therefore needs no multiplication or exponential evaluation.

Let `u_p = 0.5 * 10^(1-p)` be the relative error limit for a normal p-digit, half-even operation. The p39 `ln(10)` constant and one correctly rounded multiplication give

```
|delta(f ln(10))| <= ln(10) (2 u_39 + u_39^2)
                    < 2.303e-38.
```

The first-order relative error contributed to the exponential is the same size. The direct formulation had a bound proportional to `|x|`. Near the decimal128 result limits, where `|x| < 6178`, its corresponding argument error bound was about `1.43e-34`. That consumed almost the complete margin behind a 34-digit result. The revised formulation removes this factor of `|x|`.

At p34, argument formation alone has an error bound near `2.303e-33`. It cannot support a 34-digit exponential result. P39 leaves about four decimal guard digits before the `realExp` error and the accepted p39 to p34 result boundary. A wider scalar context is not supported by the operation bound after the exact scaling rewrite.

The independently computed case

```
10^-4852.239021962641007039350671796724
  = 5.76737296559571143733396575071813447725380533114326028...e-4853
```

rounded one decimal128 unit too high with the direct p39 argument. Subtracting the expected decimal128 result and multiplying by `1e4900` produced `-1e14`. The fractional formulation produces zero in that check.

Integral inputs exposed a related directed-rounding defect. The approximate route produced an adjacent value for `10^6144` in rounding modes 4 and 6; the scaled difference was `1e6110`. Exact decimal scaling returns `1e6144` in every rounding mode.

## Complex error analysis

For `z = a + ib`,

```
10^z = 10^a (cos(b ln(10)) + i sin(b ln(10))).
```

The magnitude now uses the scalar formulation. An exact zero imaginary component takes this route directly and avoids trigonometric work. For a nonzero imaginary component, the two closing multiplications remain at p39. Each multiplies a magnitude by one trigonometric component and has no subtractive cancellation.

Phase formation differs because its absolute error grows with `|b|`. With a p-digit `ln(10)` constant and one p-digit multiplication,

```
|delta theta| <= |b| ln(10) (2 u_p + u_p^2).
```

At `b = 1e20`, the bounds from argument formation are approximately `2.31e-18`, `2.31e-30`, and `2.31e-54` for p39, p51, and p75 respectively. The previous p39 route returned component errors near `8.46e-20` and `7.05e-20`. A deliberate p51 substitution in the revised route made the exact component checks fail by `2.286e-31` and `1.906e-31`. P51 therefore cannot protect result digit 34 for this ordinary decimal128 input. P75 supplies the required phase digits, subject to the trigonometric dependency.

Independent 220-digit evaluation gives

```
10^(i 1e20) =
  -0.6404623000583477935208924244953045384179467...
  -0.7679896107396055627451440560882092629838046... i.
```

The file-driven checks subtract the two rounded decimal128 components and multiply each difference by `1e40`. Both checks now produce zero.

No established fixed context can protect 34 phase digits over the complete decimal128 range of `b`. Even p75 argument formation reaches a half-unit phase error near `|b| = 2e39`, before including the trigonometric error. Decimal128 permits adjusted exponents through 6144. Reducing `b` modulo `2 pi / ln(10)` before multiplication would require a new period with thousands of verified digits and a target implementation of comparable precision. The present large-angle reduction cannot recover digits already lost in `b * ln(10)`. P75 is therefore a material extension of the accurate range, not a global guarantee for every finite complex input.

## Rounding modes and exceptional values

All working contexts retain their half-even mode. The selected decimal128 rounding mode is applied at result conversion, so the accepted p39 to p34 boundary behaviour is unchanged.

Exact integral powers are independent of rounding until decimal128 conversion. With special results disabled, `10^6145` exceeds the maximum finite decimal128 value. Modes 0, 1, 2, 3, and 5 request an infinite conversion, which the calculator reports as overflow while preserving register X. Modes 4 and 6 return `9.999999999999999999999999999999999e6144`. At the lower edge, `10^-6177` becomes `1e-6176` in modes 3 and 5 and positive zero in modes 0, 1, 2, 4, and 6. The tests also bracket the half-even transition at `log10(0.5e-6176)`.

Both signs of scalar zero map to positive one. With special results enabled, positive infinity maps to positive infinity, negative infinity maps to positive zero, and NaN propagates. A complex input with an exact zero imaginary component follows the `expComplex` precedent: `+infinity + 0i`, `-infinity + 0i`, and `NaN + 0i` map to `+infinity + 0i`, `0 + 0i`, and `NaN + 0i` respectively. This route avoids the invalid product between an infinite or NaN magnitude and a computed zero sine. A nonzero special imaginary component produces two NaNs through the polar route.

## Regression evidence

The focused file has 88 checks. Before the changes, the complex p39 phase cases failed, the large nonintegral scalar case was one decimal128 unit high, and two directed integral cases were adjacent to the exact result. The previous pure-real complex route also returned a NaN imaginary component for positive infinity and NaN. With p51 substituted for the new complex work, both complex component checks failed. With the selected implementation, all 88 focused checks succeed.

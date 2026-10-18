# Decimal context analysis for erf and erfc

## Scope and result

This analysis covers the public real `erf` and `erfc` functions, their reusable WP34S helpers, and elementwise real-matrix evaluation. Complex inputs remain outside the supported interface. Integer conversion is outside this audit.

| Calculation | Former context | Selected context | Result |
| --- | ---: | ---: | --- |
| public `erf` | 39 | 39 | a local power series removes tiny-input logarithm error |
| public `erfc` | 39 | 51 | direct upper-gamma evaluation retains far-tail digits |
| `erf` local series | caller | caller | p39 is sufficient for the public route |
| finite saturation markers | none | caller | directed conversion retains the mathematical side |
| real matrices | 39 | 39 or 51 | each element uses the corresponding scalar context |

The working contexts use round-to-nearest, ties-to-even. Decimal128 conversion applies the selected calculator mode. Differences caused only by the accepted p39-to-p34 boundary effect are outside this analysis.

## Error function near zero

The former implementation evaluated

```text
erf(x) = gamma(1/2, x^2) / sqrt(pi).
```

For a tiny `x`, the incomplete-gamma series reconstructed its scale through

```text
exp((1/2)*ln(x^2) - x^2).
```

The absolute error of the logarithm grows with the decimal exponent. Five p39 guard digits are then insufficient at some Real34 inputs near the lower exponent limit. The revised helper uses

```text
erf(x) = (2*x/sqrt(pi)) * sum((-x^2)^n / (n!*(2*n+1)), n=0..infinity)
```

when `|x| < 0.1`.

At the boundary, the magnitude ratio of consecutive terms is at most `0.01/n`. The term through `n=13` has magnitude below `6e-38`, and the next term is below `4e-41`. The absolute sum is at most `exp(0.01)`, while the signed sum is greater than `1-0.01/3`. Thus cancellation increases accumulated arithmetic error by less than `1.014`.

There are fewer than 90 p39 rounded operations before the closing square root, multiplication, and division. With `u39=5e-39`, a conservative relative arithmetic bound is below `4.7e-37`; the omitted series tail is below `4.1e-41`. The selected p39 constant for pi contributes less than one additional p39 unit. This leaves more than three decimal orders below one Real34 unit.

A p34 evaluation has an analogous accumulated bound near `4.7e-32`, without a 34-digit margin. In the independent discriminator set, changing only public `erf` to p34 caused 194 failures among its 960 exact-residual checks. P39 is therefore the narrowest established context among p34, p39, p51, and p75.

## Error function away from zero

For `0.1 <= |x| < sqrt(1.5)`, the incomplete-gamma helper uses a positive series. Its terms have no cancellation, and the exponential argument has bounded magnitude because `x^2 >= 0.01`. For larger `|x|`, the helper evaluates the positive upper continued fraction and subtracts it from `Gamma(1/2)`. At the transition, `|erf(x)|` already exceeds `0.91`, so that subtraction has a condition factor below `1.1`; it improves as `|x|` increases.

Only inputs with `|x|` below about nine have a non-saturated 34-digit result. In this interval the sensitivity of the exponential factor to a relative error in `x^2` is below `81*u39=4.05e-37`. The series and continued-fraction termination at p39, together with the completed p39 logarithm and exponential bounds, remains below one hundredth of a Real34 unit in the sampled transition interval.

For every finite nonzero input, the mathematical magnitude is strictly below one. If p39 arithmetic produces exactly `+1` or `-1`, one p39 neighbour toward zero records that strict inequality. Nearest conversion is unchanged, while directed modes receive the correct side of the endpoint.

## Complementary error function

The former helper formed `-x*sqrt(2)`, delegated to a normal CDF, and multiplied by two. The revised calculation uses the defining upper incomplete gamma directly:

```text
erfc(x) = Gamma(1/2, x^2) / sqrt(pi),             x > 0
erfc(x) = 2 - Gamma(1/2, x^2) / sqrt(pi),         x < 0.
```

For `|x| < 0.1`, it instead computes `1-erf(x)` from the stable local series. This removes the extra square-root-of-two multiplication and its later squaring, and it reuses the accurate small correction.

The far positive tail makes the context requirement different from `erf`. For large `x`,

```text
erfc(x) ~= exp(-x^2) / (sqrt(pi)*x),
```

so a relative error `delta` in `x^2` perturbs the result by approximately `x^2*delta`. Every nonzero nearest Real34 result has `x^2 < 1.5e4`. At p39, the square alone can therefore contribute about `7.5e-35` relative error, too close to a Real34 rounding boundary. The retained discriminator

```text
x = 68.21623271245100928879337295285882
erfc(x) = 8.8699381796613704410393801015294935402952070017824...e-2024
```

rounds one Real34 unit low with p39 work and correctly with p51 work.

At p51 the corresponding squared-input contribution is below `7.5e-47`. Even the 1,000-iteration implementation cap, counted conservatively as fewer than 9,000 rounded operations, contributes less than `4.6e-47` before conditioning. The logarithm, exponential, square root, and division add the same order. P51 also selects the p75 pi storage, so a p39 constant does not limit the wider calculation. The resulting working error is over twelve decimal orders below one Real34 unit throughout the representable tail.

P51 is the narrowest established context for public `erfc`. P75 offers no final-format benefit after this rewrite.

## Endpoints and directed modes

The exact special values are

```text
erf(+infinity) = +1,     erf(-infinity) = -1,
erfc(+infinity) = 0,     erfc(-infinity) = 2.
```

The prior normal-CDF route returned one for both infinite `erfc` inputs. NaNs now propagate explicitly, and `erf(-0)` retains its sign.

For finite inputs, `0 < erfc(x) < 2`. If the wider arithmetic reaches zero or two, one work-context neighbour toward the interior records the strict inequality. The same technique records whether a tiny finite result is above or below one. These markers alter no nearest Real34 result and provide the required minimum subnormal or adjacent endpoint under directed conversion.

## Verification

The durable cases remain in the existing `erf.txt` and `erfc.txt` file-driven suites. They cover all seven calculator modes, a tiny lower-exponent input, the p51 tail discriminator, signed zero, finite saturation, NaN, infinities, and real matrices.

An independent 1,024-bit MPFR comparison used 320 Real34 inputs for each function. Each reference was checked through subtract-and-scale assertions, producing 1,920 checks. The selected p39/p51 implementation succeeds in all 1,920. The same set gives 1,919 successes with p39 `erfc`, and 1,726 successes when `erf` alone is reduced to p34.

The former source succeeds in 117 of the final 125 durable checks. Its eight failures cover tiny-input accuracy, negative finite saturation, signed zero in scalar and matrix evaluation, the p51 tail discriminator, positive directed underflow, and both infinite `erfc` endpoints. The selected durable files succeed in all 125 checks. The final clean repository suite succeeds in all 15,675 checks, with zero failures and no GMP allocation remaining.

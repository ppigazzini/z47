# Gamma and log-Gamma decimal contexts

## Scope and result

This audit covers `fnGamma`, `fnLnGamma`, their scalar and complex callbacks, the shared Lanczos calculations in `wp34s.c`, reflection, and elementwise matrix use. Incomplete Gamma and probability distributions are outside this change.

The public callbacks remain at `ctxtReal39`. The selected calculator rounding mode is applied when the result is converted to `real34_t`. The Lanczos calculations require `ctxtReal75`, including 75-digit coefficients. A 51-digit calculation loses significant digits near the zeros of log-Gamma. Reflection arithmetic remains at the caller width after an exact period reduction removes cancellation next to the poles.

| Route | Working context | Reason |
| --- | --- | --- |
| Real or complex Lanczos sum and formula | 75 | Alternating coefficient cancellation followed by cancellation in log-Gamma near 1 and 2 |
| Positive integer product, 1 through 205 | 39 | At most 204 correctly rounded products; exhaustive decimal128 comparisons found no differing result |
| Small real argument, `abs(x) < 1e-24` | 39 | The omitted terms are below `1e-48` relative for Gamma and below `2e-50` relative for log-Gamma |
| Real and complex reflection outside the Lanczos calculation | 39 | Exact period reduction followed by a well-conditioned multiply by pi |
| Complex log-Gamma winding selection | 39 | The existing Stirling reference only selects an integer multiple of `2*pi`; this change preserves that rule |
| Real and complex matrices | Same scalar callbacks | Matrix processing converts each decimal128 element to `real_t`, invokes the callback, then converts the result to decimal128 |

Differences confined to the accepted 39-to-34 rounding boundary are outside this analysis.

## Lanczos calculation

For `z = x - 1`, the implementation evaluates

```text
A(z) = c0 + sum(c[k] / (z + k), k = 1..29)
L(z) = log(A(z)) + (z + 1/2) log(z + g + 1/2) - (z + g + 1/2)
Gamma(x) = exp(L(z))
```

The coefficient magnitudes reach `5.9568927402677002e16` and alternate in sign. Near `x = 1`, `log(A(z))` cancels the other two terms to produce zero. A decimal128 input adjacent to one can make the result approximately `5.8e-34`, so this final cancellation consumes about 34 decimal places in addition to the cancellation within `A`.

At 51 digits, the input

```text
x = 1.000000000000000000000000000000001
```

produces

```text
lnGamma(x) = -5.772156649015338e-34
```

instead of the 768-bit MPFR value rounded to decimal128,

```text
-5.772156649015328606065120900824016e-34
```

Only 15 significant result digits agree. Scaling the subtraction by `1e70` exposes a residual of about `9.393934879099176e21`. The same case fails in every result rounding mode and through the real-matrix callback. A 39-digit candidate fails more broadly. Therefore 39 and 51 are both unsuitable for the shared Lanczos calculation.

The 75-digit candidate retains about 24 more decimal places than the 51-digit candidate through the same arithmetic graph. The coefficient source literals contain more than 75 significant digits, so storing them at 75 digits does not invent precision. Tests adjacent to both zeros of log-Gamma, random positive arguments, negative nonintegral arguments, near-pole arguments, and complex arguments show no unexplained loss through digit 34. This is an accuracy result supported by independent high-precision calculations, not a claim that every finite input is correctly rounded.

The context is raised only inside each Lanczos helper. The caller width is saved and restored before the result is rounded back to that width. The real exponential, logarithm, complex logarithm, complex multiplication, and complex division are separate audited dependencies.

## Small arguments and integers

For small nonzero real `x`, the shortcut uses

```text
Gamma(x) = 1/x - EulerGamma
```

The first omitted absolute term is `(EulerGamma^2/2 + pi^2/12) x`. Relative to `1/x`, its size is below `1e-48` when `abs(x) < 1e-24`. For log-Gamma, taking the logarithm of this approximation differs from the expansion of `log(Gamma(x))` by less than `x^2`, apart from a coefficient below two. The absolute error is below `2e-48`, while the result magnitude is at least about 55. The 39-digit route is sufficient.

For positive integral `x <= 205`, Gamma is `(x - 1)!`. With `u39 = 5e-39`, the usual product bound is

```text
gamma(204) = 204*u39 / (1 - 204*u39) < 1.03e-36.
```

This leaves more than two decimal places beyond the 34-digit result. All integers from 1 through 205 were compared with independently calculated integer factorials under nearest rounding. The intermediate product is independent of the selected result mode, and the established decimal128 conversion applies that mode. The 39-digit product route is retained. Larger positive integers and all positive nonintegers use Lanczos. Exact nonpositive integers are detected as poles before reflection.

## Reflection near poles

The reflection formula is

```text
Gamma(x) = pi / (sin(pi*x) Gamma(1 - x)).
```

The former real route reduced `x` modulo two but then formed an angle near `-pi`, `0`, or `pi`. If `x = n + delta`, the absolute error in the 39-digit pi constant competes with `pi*delta` after the trigonometric reduction. A decimal128 `delta` can be near `1e-32` around `x = -41`, so this order of evaluation can lose many result digits.

The revised real route maps the exact remainder to `[-0.5, 0.5]` while preserving the sine sign, then multiplies by pi. No subtraction of nearly equal pi values follows. On this interval, `abs(t*cot(t)) <= 1`, so the relative perturbation in the reduced argument is not amplified by the real sine.

The complex route maps the real component into the same interval and records whether an odd integer was removed. It evaluates `sin(pi*r + i*pi*y)` and negates both components for odd parity. The identity

```text
sin(pi*(n + r) + i*pi*y) = (-1)^n sin(pi*r + i*pi*y)
```

makes the transformation exact. Near a complex pole, the reduced complex argument is small and `sin(w) = w + O(w^3)`, so relative input accuracy is retained. The logarithmic route can change its intermediate argument by a multiple of `2*pi`; the existing Stirling comparison selects the final winding integer.

Before the reduction, `lnGamma(-41.00000000000000000000000000000001)` differed from the independent value by `2.0036658968770341e-7`. The revised calculation agrees through digit 34. Scalar and complex Gamma cases on both sides of the pole show the same improvement.

## Special values, range and matrices

The change does not alter the established domain rules. NaN propagates. Positive real infinity returns positive infinity when special results are enabled; negative infinity and exact nonpositive integers return NaN. Complex special-value handling is unchanged. Signed real zero remains a pole under the existing domain policy.

For large finite arguments, the 75-digit calculation uses the wide `real_t` exponent range and the final decimal128 conversion applies overflow or underflow handling. A 1024-bit Spouge reference verifies the reflected complex case `-10.25 + 5000i`, whose Gamma components are near `1e-3451`, and its log-Gamma winding near `3.7569e4`.

Elementwise real and complex matrices invoke the same callbacks. The file-driven cases include the near-one log-Gamma cancellation and scalar and complex values next to `-41`.

## Verification

Independent references used 768-bit MPFR for real Gamma and log-Gamma and a 1024-bit, 140-term Spouge calculation for complex values. The latter used a high-precision Stirling leading term only to select the same log-Gamma winding convention.

The scalar search contained 45,988 Gamma checks and 43,600 log-Gamma checks, including inputs next to every pole from 0 through -205. The revised Gamma calculation matched all 45,988 decimal128 nearest-rounding values. The focused file-driven tests cover all seven result rounding modes, both sides of a negative-integer pole, complex values next to a pole, a large imaginary component, special values already present in the files, and real and complex matrices.

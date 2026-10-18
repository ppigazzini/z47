# Incomplete-gamma decimal contexts

## Scope and result

This audit covers the four real incomplete-gamma operations in `gammaX.c` and their shared calculation in `wp34s.c`:

```text
lower:  gamma(a,x) = integral(t^(a-1) exp(-t), t=0..x)
P:      P(a,x) = gamma(a,x) / Gamma(a)
upper:  Gamma(a,x) = integral(t^(a-1) exp(-t), t=x..infinity)
Q:      Q(a,x) = Gamma(a,x) / Gamma(a)
```

The public operations retain `ctxtReal39`. Five guard digits are needed by the ordinary series and continued fraction, while `ctxtReal34` also has an exponent range that is too narrow for their intermediate values. Two unstable parameter regions now use specialised calculations:

| Region | Working context | Calculation |
| --- | --- | --- |
| Ordinary lower series or upper continued fraction | 39 | Existing series/fraction with the audited logarithm and Gamma dependencies |
| `0 < a <= 1` and `0 < x <= 1`, upper result | 39, with one 75-digit log-Gamma quotient | Direct upper series without subtracting the lower result from Gamma |
| `a >= 9000` and `((x-a)/a)^2 < 200/a` | 39 | Temme uniform asymptotic expansion for the smaller regularised tail |
| `a >= 9000`, outside the preceding region, and `((x-a)/a)^2 <= 1/40000` | 51 | Temme expansion with enough precision for the conditioning of extreme tails |

The calculator rounding mode is applied at the final decimal128 conversion. Differences confined to the accepted 39-to-34 rounding boundary are outside this analysis. The result is a faithful 34-digit calculation over the tested regions, not a universal correct-rounding claim.

## Ordinary series and continued fraction

The lower series accumulates

```text
sum = 1/a + x/(a(a+1)) + x^2/(a(a+1)(a+2)) + ...
P(a,x) = sum * exp(a*ln(x) - x - lnGamma(a)).
```

The upper route uses a modified-Lentz continued fraction. Both iterations stop when the p39 value no longer changes and have a limit of 1,000 terms. For the existing non-transition domain, the observed iteration counts and a conservative allowance of 1,000 rounded operations give

```text
gamma(1000) = 1000*u39/(1-1000*u39) < 5.01e-36,
```

before the conditioning of the requested tail. This leaves more than two decimal guard places for ordinary well-conditioned results. The smaller tail is formed directly; complement subtraction is reserved for the larger tail. The logarithm, exponential, and log-Gamma bounds are documented by their separate audits.

A deliberate p34 public-context mutation disagreed with independent high-precision results in 375 of 508 sampled checks. For example, `P(1/2,1)` ended in `6098` instead of `6093`. This is a five-unit error in the decimal128 result, independent of the excluded p39-to-p34 boundary issue. P39 is therefore the narrowest established project context for this route.

## Small shape and upper-tail cancellation

For small `a`, subtracting the lower integral from `Gamma(a)` removes nearly the entire `1/a` term. The former route became negative for inputs such as `a=1e-40, x=0.5`. The direct upper expression is

```text
Gamma(a,x) = x^a * (
  expm1(lnGamma(1+a) - a*ln(x))/a
  + x/(a+1) - x^2/(2!(a+2)) + x^3/(3!(a+3)) - ...).
```

This form contains no subtraction of two quantities near `1/a`. Evaluation of `lnGamma(1+a)/a` needs extra precision because both the addition `1+a` and log-Gamma are followed by division by `a`. For `a > 1e-37`, those operations use p75 and the quotient is then converted to p39. Near the threshold this retains about 38 significant quotient digits; p51 would retain only about 14.

For `a <= 1e-37`, the limit

```text
lnGamma(1+a)/a = -EulerGamma + zeta(2)*a/2 + O(a^2)
```

is used. The first omitted term is below `8.23e-38`, so it cannot affect a faithful 34-digit result. At `a=1e-100, x=0.5`, the revised upper value is

```text
0.5597735947761608117467959393150852
```

and the regularised ratio is the same coefficient times `1e-100`. Both agree with a 2,048-bit MPFR calculation through digit 34.

## Large-shape transition

The lower series and upper fraction need on the order of `sqrt(a)` terms when `x` is near `a`. They therefore reach the 1,000-term limit for large decimal128 shapes. The former result was NaN at `a=x=1e40` and `a=x=1e100`.

For `a >= 9000`, where `sigma=(x-a)/a`, the revised transition route forms

```text
phi = sigma - ln(1+sigma)
y = a*phi
eta = sign(sigma)*sqrt(2*phi)
tail = erfc(sqrt(y))/2
       + sign(sigma)*exp(-y)/sqrt(2*pi*a)
         * sum(C[k](eta)/a^k, k=0..7).
```

`tail` is `P` below the transition and `Q` above it. The other regularised result is `1-tail`. The stable power series for `phi` avoids cancellation when `sigma` is small. Each `C[k]` polynomial uses fused multiply-add. The retained polynomial degrees for `C0` through `C7` are 30, 28, 26, 24, 22, 16, 14, and 12. At the smallest admitted `a`, direct interval evaluation over the p39 central band gives `abs(eta) < 0.158`. Summing absolute values of every tabulated contribution from `C8/a^8` through `C13/a^13`, including the final scale but conservatively omitting the factor `exp(-y)`, gives less than `7.78e-38`.

The `phi` series needs at most 48 included terms over this region. Its sum of absolute terms divided by `phi` is below 1.22, and weighting each term by the number of recurrence operations gives a p39 relative error below `2.9e-37`. Thus the absolute error in `y`, which is below 112, is less than `3.3e-35`. For `y >= 1`, the logarithmic sensitivity of `erfc(sqrt(y))` to `y` is below 1.32; below one its absolute conditioning is smaller than the resulting bound. The remaining p39 arithmetic and the correction combination give a conservative relative working error below `5e-35`. P39 therefore retains a full 34-digit result margin. Repeating this bound at p34 leaves fewer than 30 reliable digits at the outer boundary.

The ordinary lower series is also slow directly below `x=0.995a`. For shapes above `8e6`, the p39 central band no longer reaches that boundary. The transition route is therefore extended through `sigma^2 <= 1/40000`, using p51 outside the central band. In this outer band `abs(eta) < 0.00501`; the p51 error in `y` is amplified by at most about 14,215 for a nonzero decimal128 tail. Including 1,000 ordinary operations in the recursively evaluated complementary error function gives a conservative arithmetic contribution below `1e-44` relative. The p39 coefficient errors enter only through a correction whose magnitude is below `0.0024` of the tail, contributing less than `3e-42` relative. Terms beyond `C7/a^7` are smaller here than at the already bounded `a=9000` central boundary. P51 consequently leaves more than seven guard digits in the outer result.

P39 is not sufficient for this extended band. For

```text
a = 2.695814906907037610215033943e29
x = 269581490690645116457379069486.4786,
```

the independently evaluated result rounds to

```text
P(a,x) = 1.962660116183939644794303739869132e-2773.
```

An outer calculation deliberately retained at p39 ends in `...131`, one decimal128 unit low; p51 gives `...132`. The regression scales this residual before comparison, so the test driver's usual 30-digit tolerance cannot hide the last-place error.

The coefficients originate in Boost.Math's 113-bit implementation of Temme's expansion. The formula and its error structure are described in [Temme, SIAM Journal on Mathematical Analysis 10(4), 1979](https://doi.org/10.1137/0510071) and [DLMF section 8.12](https://dlmf.nist.gov/8.12). The source values are distributed under the Boost Software License 1.0.

At the lower boundary `a=x=9000`, the p39 result agrees with a 2,048-bit MPFR reference through digit 34. The same comparison succeeds at `a=x=5e5`, where the former ordinary route retained only 25 correct digits, and at offsets through fifteen square roots for shapes from `9000` through `2e6`. The file-driven cases include both sides. At `a=x=1e40`, the results are

```text
P = 0.5000000000000000000013298076013381
Q = 0.4999999999999999999986701923986619.
```

At `a=x=1e100`, both round to `0.5`. Unregularised incomplete Gamma exceeds the decimal128 result range throughout this transition region: already `Gamma(9000)` is about `9e31677`, and multiplication by the smallest admitted tail cannot bring it below `1e6144`. Returning positive infinity there is therefore exact in the result format.

## Endpoints, domains, and matrices

The valid real domain is `a > 0` and `x >= 0`. NaN, a nonpositive shape, a negative abscissa, and an infinite shape produce NaN. At `x=+infinity`, the exact results are `Gamma(a)`, one, zero, and zero for lower, P, upper, and Q respectively. The former endpoint mapping had all four values reversed. The `x=0` identities remain unchanged.

The public callback accepts real scalar arguments. Matrix and complex arguments follow the existing type-error path, so there is no elementwise matrix context to select in this family.

## Verification

References for small and ordinary parameters used 2,048-bit MPFR. A separate 240-digit Decimal implementation of the complete 113-bit Temme expression, including an asymptotic complementary-error-function evaluation for the smallest tails, checked the large-shape outer band. Direct MPFR comparisons at shapes from `9000` through `2e6` verify the centre and offsets through fifteen square roots. The p39 central window was limited below the first observed discrepancy at twenty square roots; the p51 band covers the remaining gap to the ordinary-series boundary and the full nonzero decimal128 tail range for very large shapes.

The focused file-driven suite contains 199 checks across the four existing incomplete-gamma files. It includes all seven result modes, the p34 and outer-p39 discriminators, the small-shape cancellation case, large-shape transition values, infinity endpoints, and unregularised overflow. No separate regression program is required.

The final clean repository suite completed 15,934 checks with zero failures and zero bytes owned by GMP. Compilation emitted no diagnostic from the changed source; the existing macOS linker-alignment warning remained.

# Decimal context analysis for covariance and statistical error measures

This analysis covers sample and population covariance, correlation, the
minimum exponential deviation, parameter error estimates, and their internal
statistical helpers in `src/c47/mathematics/variance.c`. The arithmetic,
geometric, and weighted deviations in the first part of that file have a
separate analysis in `decimal-context-standard-deviation.md`.

Observations are Real34 values in the two-column `STATS` matrix. First and
second moments are maintained at p75 by `stats.c`. Differences caused only by
p39-to-p34 final double rounding are outside this audit.

## Failure of the uncentred covariance

The former covariance kernel evaluated

```
n * sum(x_i * y_i) - sum(x_i) * sum(y_i)
```

at p75 before division by `n` and either `n` or `n - 1`. This subtraction can
remove every available digit. Increasing the context by a fixed amount cannot
cover every permitted row count and Real34 offset.

A file-driven data set has 3,200 rows. Its base pair is

```
(999999999999999999999.9999999999998,
 999999999999999999999.9999999999998).
```

One row increases only `x` by `1e-13`, and another increases only `y` by
`1e-13`. The exact centred cross-product sum is `-1e-26/3200`. The former p75
subtraction returns zero because the two terms near `1e49` round to the same
p75 value. The sample covariance, population covariance, and correlation then
return zero instead of

```
-9.768677711784932791497342919662394e-34
-9.765625e-34
-0.0003125976867771178493279149734291966.
```

## Centred evaluation

The revised kernel obtains p75 means from the stored first moments and forms
the sum from the existing matrix entries:

```
Cxy = sum((x_i - mean_x) * (y_i - mean_y)).
```

Sample covariance is `Cxy/(n-1)` and population covariance is `Cxy/n`.
Correlation uses

```
Cxy / (sqrt(Cxx) * sqrt(Cyy)),
```

so no sample divisor is introduced and then cancelled. `Cxx` and `Cyy` are
centred square sums. The correlation is clamped to its mathematical interval
when finite; a zero marginal deviation still produces NaN.

As with centred variance, a p75 mean error enters a cross-product sum through
the product of the two mean errors:

```
sum((x_i - mean_x_hat) * (y_i - mean_y_hat))
  = Cxy + n * (mean_x_hat - mean_x) * (mean_y_hat - mean_y).
```

This removes the first-order loss in the uncentred expression.

## Context selection

The isolated `fnStatSX_SY` square sums use p39. Their terms are nonnegative,
and the previous deviation analysis establishes a relative accumulation bound
below `2.1e-35` for at most 4,095 rows. Division and square root at p39 retain
the required margin for a Real34 deviation.

Each public covariance applies one final division to the p75 centred sum.
Correctly rounded p34 division therefore produces the Real34 result directly;
p39, p51, and p75 provide no additional accuracy under the accepted final
rounding policy. The internal sample covariance remains p75 because orthogonal
fitting consumes it before a final result is formed.

The signed cross-product sum needs p75. Each product of two Real34 values can
require 68 coefficient digits, and positive and negative products can cancel.
The four-row discriminator uses 34-digit integers `A`, `B`, `C`, and `D` with

```
A*C - B*D = 1
```

and rows `(A,C)`, `(-A,-C)`, `(B,-D)`, and `(-B,D)`. Its centred product sum is
two and its sample covariance is exactly `2/3`. A deliberate p51 substitution
returns `-116902442308625780`; p75 returns the independently computed Real34
result. P75 is therefore the narrowest available context established for the
signed kernel. Covariance at or very near zero remains intrinsically
ill-conditioned, so no fixed context provides a uniform relative bound.

`fnStatR` uses p75 square sums, roots, divisions, and the p75 cross-product.
Linear and orthogonal fitting formerly replaced that result with the
uncentred expression. They now retain the centred correlation. The roots and
divisions need p75 because fitting consumes the correlation before conversion.

## Stable residual measures

The former minimum-deviation and parameter-error routes obtained a small
residual through `1-r^2`. For nearly collinear data, rounding `r` loses most or
all of that difference. Let

```
Cxx = sum((x_i - mean_x)^2)
Cxy = sum((x_i - mean_x) * (y_i - mean_y))
b   = Cxy/Cxx.
```

The minimum deviation formula is algebraically equivalent to

```
SMI^2 = sum(((y_i - mean_y) - b*(x_i - mean_x))^2)
        / ((n - 1) * (1 + b^2)).
```

The revised route evaluates these residuals directly. When `abs(b) > 1`, it
uses `a = 1/b` and the equivalent numerator
`a*(y_i-mean_y) - (x_i-mean_x)`. The selected ratio is at most one in
magnitude, which avoids unnecessary coefficient and exponent growth in
`1 + ratio^2`.

The parameter-error formula receives the same treatment. Its slope error and
intercept error are evaluated as

```
s(a1)^2 = SSE / ((n - 2) * Cxx)
s(a0)   = s(a1) * sqrt(Cxx/n + mean_x^2),
```

where `SSE` is the direct vertical residual sum. The logarithmic,
exponential, and power models apply the corresponding logarithmic
transformation while reading the stored observations. These expressions are
equivalent to the previous formulas but avoid the small `1-r^2` subtraction.

Means, centred moments, slopes, transformations, and residual FMAs use p75.
A 30-row case formed from three repeated Real34 pairs has an exact line
departure near `1.58e-40`. P51 returns
`6.064576098676213715575162053607192e-41` for its minimum deviation; p75
returns the independently computed Real34 result
`6.064576098676213715565706554828286e-41`. This establishes p75 as the
narrowest available context for the cancellation-sensitive work. The former
`1-r^2` route returns zero for the associated parameter errors.

Residual squares and their sum are nonnegative, so p39 gives the same
`2.1e-35` accumulation bound as the centred variance. The following positive
products, quotients, and square roots also use p39. No fixed context gives a
uniform relative error bound as the observations approach an exactly fitted
line; p75 preserves the widest available margin.

The p75 statistical accumulators remain unchanged. A common accumulator also
serves transformed curve fitting and powers through `x^4`; one Real34 fourth
power can require 136 coefficient digits, and signed totals can be arbitrarily
ill-conditioned. No narrower common context is established. Covariance and
raw correlation no longer depend on the stored second moments.

## Domains and special values

Covariance and correlation require at least two observations. Parameter error
estimates require three because their formula divides by `n-2`; the former
two-observation gate admitted an undefined division. Minimum exponential
deviation keeps its existing minimum of 30 observations.

Finite constant data returns zero covariance and NaN correlation. NaN or
infinite observations propagate through the centred arithmetic. These
functions consume the `STATS` matrix rather than dispatching over a matrix in
X; the matrix form of `Sigma+` is covered by the close-offset case.

## Verification

The focused `stats_cov.txt` and `curvefit_cov.txt` set contains 189 checks. The
uncentred source fails all three 3,200-row covariance and correlation checks.
The centred source succeeds for all 189. A deliberate p51 cross-product
substitution fails the three four-row determinant checks. The selected source
also covers matrix ingestion, insufficient data, zero marginal deviation,
three-point zero parameter errors, p75 residual cancellation, large translated
means, and the 30-point minimum-deviation gate.

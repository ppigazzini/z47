# Normal-distribution decimal contexts

## Scope and result

This audit covers the normal and log-normal density, lower probability, upper
probability, and inverse functions in `src/c47/distributions/normal.c`. The
public result type is Real34. Matrix operands have no elementwise distribution
route and produce the established type error.

The revised routines target faithful 34-digit results. They do not claim
universal correct rounding for the transcendental approximations. Differences
caused only by conversion from p39 to Real34 are outside this audit.

| Calculation | Selected context | Reason |
| --- | ---: | --- |
| normal density and probabilities | 51 | tail exponentiation needs more than the five p39 guard digits |
| log-normal density and probabilities | 75 | the logarithm and scale transformation can consume the p51 margin |
| standard normal inverse | 39 | two fourth-order corrections give the required quantile accuracy |
| location-scale and log-normal inverse | 75 | three corrections and fused scaling protect ordinary cancellation |
| detected severe cancellation | 159 | up to 68 lost decimal places were exhibited by Real34 inputs |
| final public result | Real34 | calculator rounding is applied after the complete scalar calculation |

## Density and direct probabilities

For a standardised argument `z`, the density and probabilities are

```text
phi(z) = exp(-z^2/2) / sqrt(2*pi),
Phi(z) = erfc(-z/sqrt(2)) / 2,
Q(z)   = erfc( z/sqrt(2)) / 2.
```

The direct `erfc` form avoids subtracting a small upper tail from one. It also
gives the correct endpoints for both signs of infinity. The public normal
functions use p51 for these expressions and select the p75 storage for `2*pi`.

Let `U(p)=10^(1-p)` conservatively bound one p-digit elementary operation. A
nonzero finite Real34 density has `z^2/2` below about 14,220. Rounding the
square at p39 can therefore perturb the exponential by about
`14220 U(39)`, or `1.4e-34`, before the other operations are counted. This is
not a 34-digit error margin. At p51 the same contribution is below `1.5e-46`,
leaving more than eleven decimal orders for the remaining operations.

A deterministic 160-result comparison against a 2,048-bit MPFR computation
gave 471 successes from 480 subtract-and-scale checks at p39. Five density
values and four upper-tail values differed. P51 gave 480 successes from 480.
One retained discriminator is

```text
z = 47.96890669070418330307583280827874
phi(z) = 8.742432823889452068129797730765922e-501.
```

The location-scale normal transformation `(x-mu)/sigma` also uses p51. When
`x-mu` has cancellation, the subtraction of the two Real34 operands is exact
at that width before division. Widely separated operands have no harmful
cancellation.

## Log-normal transformation

For positive `x`, the log-normal functions use

```text
z = (ln(x)-mu)/sigma,
f(x) = phi(z)/(sigma*x).
```

Ordinary evaluations use p75. A p51 calculation loses the final Real34 value
for the following retained case:

```text
x = 2.718281828459045235360287471352662,
mu = 1,
sigma = 1e-34.
```

P75 gives the independently computed density and both probabilities. It is the
narrowest established project context for this ordinary route.

No fixed p75 route covers every Real34 input. For

```text
x = 1.000000000000000000000000000000001,
mu = 9.999999999999999999999999999999995e-34,
sigma = 3.333333333333333333333333333333333e-100,
```

the expansion

```text
ln(1+d) = d - d^2/2 + d^3/3 - ...
```

cancels its first two represented contributions against `mu`. The remaining
term occurs beyond p75. The p75 subtraction can become zero, while the correct
standardised argument is close to one.

The implementation measures the adjusted-exponent loss in `ln(x)-mu`. A loss
greater than 32 places selects a local p159 context. Its logarithm uses decimal
range reduction, repeated square roots, and the atanh series

```text
ln(y) = 2 * sum(a^(2*n+1)/(2*n+1)),
a = (y-1)/(y+1).
```

Range reduction keeps `abs(a)` below about 0.172. `ln(10)` is evaluated in the
same p159 context, so no p75 constant limits the fallback. The wide frame is
created only after cancellation is detected. At a loss of 32 places, p75 keeps
43 significant digits. Normal tail exponentiation can consume fewer than five
more decimal places for a nonzero Real34 result, leaving at least four guard
digits. This establishes the selection boundary.

## Inverse

The inverse first obtains a signed normal quantile estimate, then applies
fourth-order corrections based on a direct tail residual and the density. The
central residual uses the alternating normal series rather than incomplete
Gamma. This matters because the revised p75 incomplete-Gamma route supplied
only about 58 useful digits in the severe central-cancellation discriminator.

The standard normal inverse uses p39 and two corrections. The relative error
of a tail probability is divided by approximately `z^2` when converted to a
relative quantile error, so the p39 tail error that is unsuitable as a direct
probability remains below the quantile requirement. A 60-result independent
comparison gave 154 successes from 180 checks at p34 and 180 from 180 at p39.

Location-scale and log-normal inverses use p75, three corrections, and the
fused expression

```text
mu + sigma*q.
```

This retains a 34-place cancellation case that p51 loses. A larger loss is
detected from the exponents of `mu`, `sigma*q`, and their fused result. The
following Real34 rational pair consumes 68 places, so even p75 leaves only a
few meaningful digits:

```text
p = 0.75,
mu = -3047222357676761574378897691720593,
sigma = 4517818627771437330773345452549820,
result = 7.056971285873559834177565009898152e-35.
```

The conditional p159 route refines the p75 estimate twice, evaluates the final
fused expression at p159, and rounds the completed result to 34 digits. It also
resolves the audited far-tail case at `p=1e-34`. P159 leaves at least 57 work
digits after the exhibited 68-place cancellation and the 34-digit result.
For a loss of at most 32 places, the ordinary p75 fused result retains at least
43 digits. This is also sufficient before finite log-normal exponentiation,
whose argument magnitude is below about 14,150.

For `abs(q)<8`, the wide residual uses the alternating central series. Its
largest intermediate scale is about `exp(32)`, so fewer than fourteen decimal
places are lost before the subtraction that forms the upper probability. For
`abs(q)>=8`, a modified Lentz fraction evaluates the upper tail directly. The
successive-value termination is an accuracy criterion rather than a formal
continued-fraction remainder bound. Independent values cover both branches.

## Endpoints, domains, and directed rounding

The exact standard and location-scale endpoints are

```text
Phi(-infinity)=0,  Phi(+infinity)=1,
Q(-infinity)=1,    Q(+infinity)=0,
phi(+/-infinity)=0.
```

Finite normal densities and direct tails are strictly positive. If work
arithmetic reaches zero, one context neighbour toward one records the strict
inequality for directed Real34 conversion. A finite probability that reaches
one receives the corresponding neighbour toward zero. Exact infinite
endpoints do not receive these markers. Log-normal inverse exponentiation uses
the analogous finite underflow and overflow markers.

Normal parameters require finite `mu` and finite positive `sigma`. Log-normal
`x=0` has its exact support values. Negative log-normal arguments produce the
domain result, or NaN when special-result mode is enabled. Inverse probability
must be finite and strictly between zero and one. Real and complex matrices are
rejected by the scalar register conversion.

## Dependency and regression evidence

The public p51 normal probabilities call `WP34S_Erfc`, which in turn uses the
revised `WP34S_GammaP`. The p39 inverse tail residual has the same dependency.
The p159 cancellation route is self-contained: its central series, tail
fraction, density, and logarithm do not use incomplete Gamma.

Disabling the p159 selection produced four failures in a 92-check focused set:
the 68-place inverse case and the density and two probabilities for the
near-unit log-normal case. The selected implementation gave 92 successes from
92. The expanded existing file-driven normal-distribution files gave 255
successes from 255, with no remaining GMP allocation. The new cases also cover
p39 and p51 discriminators, selected directed-rounding boundaries, NaN,
infinities, invalid parameters, negative log-normal arguments, and matrix
rejection. The final repository suite succeeds in all 15,974 checks, with zero
failures and no GMP allocation remaining.

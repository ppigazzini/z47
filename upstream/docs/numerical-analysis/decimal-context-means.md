# Decimal context analysis for statistical means

This analysis covers arithmetic, geometric, harmonic, root-mean-square (RMS),
and weighted means in `src/c47/mathematics/mean.c`. Statistical accumulators
are p75 values maintained by `stats.c`; this analysis treats those stored
values as the inputs to the final mean calculation.

These public functions consume the scalar p75 accumulators. Matrix input is
expanded into real statistical observations before these functions run, and
`mean.c` has no complex or elementwise matrix callback. Matrix ingestion and
p75 accumulation are dependencies outside this final-mean calculation.

Differences caused only by p39-to-p34 final double rounding are outside this
audit.

## Direct quotient means

The arithmetic mean is `sum(x)/n`, the harmonic mean is
`n/sum(1/x)`, and the weighted mean is `sum(x*y)/sum(y)`. Each final kernel is
one division. Division is correctly rounded in its supplied context, so p34
computes the selected Real34 result directly. A later conversion to Real34
does not change it. P39, p51, and p75 add no accuracy under the accepted
double-rounding policy.

Each direct quotient contains one p34 operation, which is cost-neutral. This
does not propose p34 for chained arithmetic: geometric and RMS means retain
p39 across their division and transcendental operation, where repeated p34
work would have no speed advantage and could require extra unpacking and
repacking.

The stored sums can lie beyond the Real34 exponent range. That does not force
a wider division context: the exact quotient determines the result range. For
ordinary finite arithmetic means its magnitude cannot exceed the largest
input magnitude. The focused case with two maximum finite values confirms
that a p34 quotient of the wide p75 sum returns the finite endpoint without an
intermediate overflow. Two minimum subnormal values similarly retain the
minimum subnormal harmonic mean.

The p75 accumulation remains a separate limitation. With severe cancellation,
the condition number `sum(abs(x))/abs(sum(x))` is unbounded, and no fixed-width
final division can recover digits already absent from an accumulator. The
context changes here neither improve nor weaken that earlier calculation.

## Geometric mean

The geometric mean is evaluated as

```
L = sum(ln(x)) / n
G = exp(L).
```

The stored logarithmic sum is p75. For a finite nonzero Real34 result,
`abs(L)` is below about 14,222. A p39 division perturbs `L` by at most
`u39*abs(L)`, below `7.2e-35`. Exponential conditioning transfers that absolute
argument error to approximately the same relative result error. The audited
p39 exponential contributes at most `1e-38` relative error from its working
approximation. This leaves a useful margin beyond 34 digits, subject to the
accuracy of the stored p75 logarithmic sum.

At p34 the division term alone can reach `7.2e-30` relative error near the
Real34 exponent limits. P34 is therefore unsuitable. P39 is the narrowest
existing context with an established margin; p51 and p75 are unnecessary in
the final two operations.

## RMS mean

Write the stored nonnegative square sum as `S`. The RMS result is

```
q = S / n
R = sqrt(q).
```

Correctly rounded p39 division contributes at most `u39` relative error to
`q`. Square-root sensitivity halves this perturbation, and the correctly
rounded p39 square root contributes at most another `u39`. Including the
product term gives a bound below `1.51u39`, or `7.51e-39`, relative to a
nonzero `R`.

At p34 the corresponding bound is about `7.51e-34`, which has no complete
34-digit margin. A file-driven discriminator uses

```
x1 = 6.220504644630588869860143057304340
x2 = 1.386466957379140208711177696561762.
```

Rounding both final operations at p34 gives
`4.506493573598818487239854561418072`, one Real34 unit below the independently
evaluated result ending in `073`. The selected p39 route returns the latter.
Thus p39 is the narrowest established context for RMS.

## Weighted-mean domain

The weighted mean formula is defined for positive fractional total weight as
well as for totals at least one. The earlier `sum(y) < 1` gate rejected valid
weights. The revised gate rejects zero and negative totals, and lets a NaN
total flow to the arithmetic result. The focused data `(2,0.1)` and `(4,0.2)`
now give `10/3`; the former source raised a data-count error and left 4 in X.

## Selected contexts and verification

| Function | Context | Reason |
| --- | ---: | --- |
| arithmetic mean | p34 | one correctly rounded division |
| harmonic mean | p34 | one correctly rounded division |
| weighted mean | p34 | one correctly rounded division |
| geometric mean | p39 | division error is amplified by `exp` at extreme exponents |
| RMS mean | p39 | composed division and square root need guard digits |

The focused `stats_cov.txt` set contains 61 checks. The earlier weighted gate
succeeds for 60 and fails the fractional-weight case. The selected source
succeeds for all 61. A deliberate p34 substitution in the geometric and RMS
paths succeeds for 60; the RMS discriminator leaves a scaled residual of 1.
The clean repository run succeeds for 16,496 of 16,496 checks with zero
GMP-owned bytes.

The later joint mean and order-statistics audit retains every selected mean
context. Its new special-value correction is confined to percentile handling
in `median.c`; no mean arithmetic changes are required.

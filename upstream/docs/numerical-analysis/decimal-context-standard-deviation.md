# Decimal context analysis for statistical deviations

This analysis covers arithmetic, geometric, and weighted sample/population
deviations and errors of the mean in the first part of
`src/c47/mathematics/variance.c`. Covariance, correlation, and curve-fit error
calculations later in that file require separate audits.

The observations are Real34 values in the `STATS` matrix. First moments are
maintained at p75. Differences caused only by p39-to-p34 final double rounding
are outside this audit.

## Failure of the uncentred formula

The earlier kernel evaluated

```
sum(x^2) - sum(x)^2 / n
```

through a p75 mean followed by an FMA. P75 is not enough when the first term
and product agree for more than 75 places. Three Real34 observations

```
1e20, 1e20, 1e20 + 1e-13
```

have exact sample deviation `1e-13/sqrt(3)`. The earlier p75 kernel returns

```
5.773502735197527671933658151471699e-14,
```

which has only eight correct significant digits. The population deviation and
error of the mean have the same relative error. Increasing the context cannot
solve the complete Real34 input range with this formula: squared inputs have
up to 68 coefficient digits and their cancellation can expose a result about
66 decimal places smaller.

## Centred evaluation

The revised calculation first obtains the p75 mean from the stored first
moment, then visits the existing matrix observations and forms

```
S = sum((x_i - mean)^2).
```

Geometric variants use `ln(x_i)` and weighted variants use
`sum(w_i * (x_i - mean)^2)`. No uncentred second-moment subtraction remains.
The mean error enters this square sum quadratically because

```
sum((x_i - mean_hat)^2)
  = sum((x_i - mean)^2) + n * (mean_hat - mean)^2.
```

This is materially more stable than the earlier first-order cancellation.
The p75 mean also has 41 digits beyond each Real34 observation before this
quadratic term matters.

For arithmetic observations and nonnegative weights, the centred squares are
nonnegative. With at most 4,095 rows and `u39 = 5e-39`, sequential p39 FMA
accumulation has

```
gamma_4095 < 2.05e-35.
```

Rounded deviations and squares add less than `3u39` per term. A conservative
bound below `2.1e-35` relative to the nonzero square sum leaves more than one
decimal guard digit for a Real34 result. P34 has
`gamma_4095` near `2.05e-30` and no useful margin. A three-observation
file-driven case gives a final sample-deviation result one Real34 unit high
when all centred work is deliberately changed to p34. P39 is the narrowest
established context for the arithmetic and weighted centred kernels.

Signed weights can make the weighted square sum ill-conditioned. The bound
above applies to the usual nonnegative statistical weights; cancellation from
signed weights has no uniform relative guarantee.

## Geometric deviation

Geometric deviation applies `exp` to the standard deviation of the p75
logarithms. If the final geometric deviation is finite, its logarithm is below
about 14,150. A p39 centred-sum bound near `2.1e-35` would give a square-root
relative error near `1.1e-35`, then an absolute logarithmic error as large as
`1.6e-31`. Exponentiation transfers that to relative result error, so p39 is
not adequate for all finite outputs.

At p51, `gamma_4095 < 2.05e-47`; its contribution after square root and the
largest finite exponential argument is below `1.6e-43` relative. The closing
p39 square root can contribute about `7.1e-35` absolute at that argument, and
the audited p39 exponential adds at most `1e-38` relative error. This retains
a 34-digit margin. P51 is therefore the narrowest established context for the
geometric centred kernel, while p39 suffices for the closing root and
exponential.

The file-driven pair `1, 1e2808` distinguishes the contexts. P39 centred work
produces a geometric sample deviation ending in `445`; p51 gives the
independently evaluated Real34 result ending in `446`. The scaled residual is
one.

## Errors of the mean

The earlier code formed `sqrt(variance) / sqrt(n)`. The revised form computes

```
sqrt(variance / n).
```

Division occurs in the p39 or p51 centred context before one p39 square root.
This removes a square root and a division, avoids another composed-error
stage, and is algebraically identical for positive `n`.

## Weighted domain

Population weighted deviation requires positive total weight. Sample weighted
deviation and its error require total weight greater than one because this
implementation uses the frequency-weight denominator `sum(w)-1`. The earlier
code checked only the number of matrix rows and returned zero for positive
fractional weights whose total was at most one. The revised checks report the
existing insufficient-data error for that undefined sample case, while the
population deviation remains valid. For `(x,w)=(2,0.1),(4,0.2)` it is

```
0.9428090415820633658677924828064654.
```

## Verification

The focused statistics file contains 85 checks. The earlier p75 uncentred
kernel succeeds for 67 of the 70 checks present at the time of its replay; the
three close-cluster deviations fail with only eight correct digits. The final
centred implementation succeeds for all 85.

A deliberate p34 arithmetic-centre substitution succeeds for 84 of 85 checks
and leaves a scaled residual of -1. A deliberate p39 geometric-centre
substitution succeeds for 83 of 85 checks; both the exact subtraction and its
scaled form detect the adjacent geometric result. The selected contexts are
p39 for arithmetic and weighted centred work, p51 for geometric centred work,
p39 for square root and exponential, and p75 only for the stored mean.

A clean repository-wide `make test` run succeeds for all 16,572 checks, with
zero GMP-owned bytes. Compilation emits only the existing Mach-O section
alignment warning.

# Geometric distribution decimal contexts

## Scope and result

This audit covers the geometric probability mass, lower probability, inclusive
upper probability, inverse, and calculator entry functions in
`src/c47/distributions/geometric.c`. The parameterisation is

```text
Pr(K=k) = p (1-p)^k,  k = 0, 1, ...
```

The public result type is Real34. Differences caused only by conversion from
p39 to Real34 are outside this audit.

| Calculation | Selected context | Reason |
| --- | ---: | --- |
| mass | 39 | the logarithm, exponent product, exponential, and final product need five guard digits |
| lower probability | 39 | `log1p` and `expm1` avoid both endpoint subtractions |
| inclusive upper probability | 39 | the logarithmic form preserves a probability parameter below the gap at one |
| inverse estimate | 39 | p34 changes the final Real34 digit for large quantiles |
| inverse adjacent classification | 51 | a CDF step can differ from a Real34 target by less than half a p39 unit |
| final result | caller context, then Real34 | calculator rounding is applied after the complete result is available |

The revised calculations target faithful 34-digit results. They do not claim
universal correct rounding or universal discrete classification when an exact
CDF step is arbitrarily close to a Real34 probability.

## Stable survival logarithm

All four calculations need

```text
ell = log(1-p).
```

For `p<=1/2`, the revised helper evaluates `log1p(-p)`. If `p` is too small to
change one at p39, the compensated implementation returns `-p`; the omitted
relative correction starts at `p/2`, below a p39 unit in that range.

For `p>1/2`, it first forms `q=1-p` and evaluates `log(q)`. The Real34 input
and one differ by less than a factor of two, so the subtraction is exact. This
route avoids a correction ratio near the `p=1` endpoint. At `p=1`, `ell` is
negative infinity and the separate zero-index case defines the point mass.

The former inclusive upper probability formed `q=1-p` for every parameter and
then evaluated `q^ceil(x)`. With

```text
p = 1e-6176,  x = 1e6144,
```

p39 rounded `q` to one and the result was one. Direct logarithmic evaluation
gives

```text
Pr(K>=ceil(x))
= 0.9999999999999999999999999999999900...,
```

which differs in the final two Real34 places. The corresponding lower
probability is

```text
9.999999999999999999999999999999950e-33...
```

## Mass and tails

For integral `k>=0`, the mass uses

```text
exp(k*ell) * p.
```

The separate `k=0` route returns `p` exactly and also defines the degenerate
`p=1` mass. Negative, nonintegral, and infinite indices have zero mass.

For finite `x`, the lower and inclusive upper probabilities are

```text
L(x) = -expm1((floor(x)+1)*ell),  x>=0,
R(x) =  exp(ceil(x)*ell),          ceil(x)>=1.
```

The direct `expm1` form prevents cancellation when the lower probability is
small. The upper probability is evaluated directly, so a small requested tail
is not obtained from a rounded lower probability.

For a result inside the Real34 exponent range, the exponential argument has
magnitude at most about

```text
log(10^6176) < 14222.
```

Multiplication can therefore amplify a relative logarithm error by fewer than
4.2 decimal places. P39 supplies five guard digits and retains a margin beyond
Real34; p34 does not. Independent 180-digit decimal calculations give

```text
p = 0.1234567890123456789012345678901234,  k = 123

Pr(K=k)   = 1.128845783933117467674771408867983e-8...
Pr(K>=k)  = 9.143650932151109885754923223383903e-8...
```

A deliberate p34 substitution changed the scaled mass residual by `4e4` and
the scaled upper residual by `3.5e5`. For

```text
p = 1e-34,  x = 1e33,
```

the lower probability is

```text
0.09516258196404042683575094055356347...,
```

and the p34 scaled residual changed by `3e5`. These retained residual cases
establish p39 as the narrowest tested context for all three public routes.

Finite, nondegenerate mass and tail values are strictly inside their relevant
probability endpoints. If the working exponential underflows, an adjacent p39
value records that strict side before conversion. Consequently, upward and
toward-positive conversion of a positive value below the Real34 range returns
`1e-6176`, while nearest and downward conversion returns zero. A finite lower
probability too close to one similarly converts to the Real34 predecessor
under downward rounding. Exact support and `p=1` endpoints are not adjusted.

## Inverse

For `0<u<1`, the exact quantile is

```text
ceil(log1p(-u) / ell) - 1.
```

The implementation forms `floor(ratio-1)` and then classifies its CDF. Away
from a discrete boundary this is the quantile or its predecessor. At a
boundary, the adjacent CDF test supplies the exact discrete choice.

P34 is insufficient for the ratio. For

```text
p = 1.958079851970846282562006398700402e-54
u = 0.07211560266196917375288943563991330,
```

an independent calculation gives the integer quantile

```text
38225267327241127582748743326127104915161065939264638,
```

which rounds to

```text
3.822526732724112758274874332612710e52.
```

The p34 estimate ends in `...2711e52`; p39 gives `...2710e52`.

The shared adjacent helper evaluates the CDF at p51 and compares that value
directly with the Real34 target. The following retained case exposes the
classification digits that a p39 reduction discards:

```text
p = 0.000004437523649444452986436945480874079
u = 0.9647858929614629660014656050472651
k = 754091
```

Independent decimal arithmetic gives

```text
L(k) = 0.9647858929614629660014656050472650999995215793243...
u-L(k) = 4.7842067566773205796e-40...
L(k+1) = 0.9647860492248957435779233738487208084...
```

The p39 image of `L(k)` equals `u`. Direct comparison with the p51 CDF returns
754092; reducing the CDF to p39 returns 754091. P51 has eleven decimal places
beyond the measured gap and is the narrowest established classification
context. The geometric inverse uses the shared helper, so its comparison
follows the same rule as the other discrete distributions.

## Domains, endpoints, and matrices

The calculator functions require `0<p<=1`. Mass and tail functions extend over
the real line by their support values: negative arguments give mass zero,
lower probability zero, and inclusive upper probability one. Positive
infinity gives zero, one, and zero respectively. NaN is an argument-domain
error. NaN and infinite parameters are distribution-parameter errors.

The public inverse retains its strict `0<u<1` domain. The exported inverse
kernel defines `u=0` as zero and `u=1` as positive infinity. At `p=1`, every
interior inverse probability returns zero.

Real and complex matrices are rejected by `getRegisterAsReal`; no elementwise
geometric calculation is defined. Retained file-driven cases assert that
interface behaviour for all four public functions.

## Regression evidence

The original focused files completed 97 of 97 cases. With the first set of new
domain, endpoint, extreme-tail, matrix, and adjacent-step cases, the former
source failed 12 of 145 cases. The revised source without strict-side markers
then failed six directed cases in the 162-case set. A deliberate p34
substitution failed four low-order discriminators in a 150-case focused run.
The settled focused run completes 162 of 162 cases.
A clean repository-wide run on integration base `d99db46` completes 16,613 of
16,613 tests.

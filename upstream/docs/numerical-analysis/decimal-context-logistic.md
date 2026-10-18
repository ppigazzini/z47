# Logistic-distribution decimal contexts

## Scope and result

This audit covers the logistic density, lower probability, upper probability,
inverse, and calculator entry functions in `src/c47/distributions/logistic.c`.
The public result type is Real34. Real and complex matrices have no elementwise
distribution route and produce the established type error.

The revised routines target faithful 34-digit results. They do not claim
universal correct rounding for the transcendental approximations. Differences
caused only by conversion from p39 to Real34 are outside this audit.

| Calculation | Selected context | Reason |
| --- | ---: | --- |
| density and both probabilities, `abs(z)<=100` | 39 | stable positive formulas retain over one decimal guard digit |
| density and both probabilities, `abs(z)>100` | 51 | exponential sensitivity can consume over two of the five p39 guard digits |
| ordinary inverse | 39 | a central series or endpoint logarithms avoid probability cancellation |
| inverse after 2 to 13 lost places | 51 | the location-scale sum retains at least one decimal guard digit |
| inverse after 14 to 37 lost places | 75 | the wider fused sum protects stronger cancellation |
| inverse after more than 37 lost places | 159 | local series and a fused closing sum protect deep cancellation |
| final public result | Real34 | calculator rounding follows the complete scalar calculation |

Here `z=(x-mu)/s` and `s>0`.

## Density and probabilities

Put `a=abs(z)` and `t=exp(-a)`. The revised route uses

```text
small = t/(1+t)
large = 1-small
density = t/(s*(1+t)^2).
```

The sign of `z` and the requested tail select `small` or `large`. Every
intermediate after the exponential is nonnegative, `0<t<=1`, and `1<=1+t<=2`.
The density route never forms `cosh(z/2)` and the smaller probability is never
obtained by subtracting a rounded value from one. This preserves the finite
upper probability at `z=100`,

```text
3.7200759760208359629596958038631183373...e-44,
```

for which the former hyperbolic formula returned zero.

For Real34 `x` and `mu`, p39 subtraction is exact when cancellation matters.
When the exponents are far enough apart to require rounding, the omitted term
is already below a p39 unit of the larger operand. Division gives an absolute
error in `z` below `abs(z)*u`, where the directed-rounding unit is
`u=1e-38` at p39. The relative condition of `exp(-a)` with respect to `a` is
one for absolute perturbations. Thus `abs(z)<=100` contributes less than
`1e-36` relative error. The audited p39 exponential and four positive rounded
operations raise the conservative bound to less than `1.2e-36` for a finite
nonzero density or smaller probability. The larger probability has the same
absolute bound. P34 supplies no work-digit margin, so p39 is the narrowest
established context on this interval.

For larger `abs(z)`, the quotient and all following operations are recomputed
at p51. A nonzero Real34 tail requires `abs(z)<14222`; a nonzero Real34 density
can extend to about twice that magnitude when a small scale offsets the
exponential. Consequently, the p51 quotient contributes less than `3e-46`
relative error throughout the range where 34 significant result digits exist.
The exponential and fixed arithmetic keep the bound below `4e-46`. P39 can
approach `1.5e-34` at the smallest Real34 tails, so p51 is the narrowest
established fixed context for this extreme interval.

If a finite result is below the Real34 range, an adjacent value records its
strictly positive sign before each narrowing conversion. Similarly, a finite
probability too close to one retains the strict lower side. Half-even
conversion still gives the nearest endpoint, while directed conversion can
select the minimum positive subnormal or the predecessor of one. Infinite
variates use exact endpoints and receive no adjacent marker.

## Inverse probability transform

The inverse is

```text
q(p) = mu + s*log(p/(1-p)).
```

The former expression `2*atanh(2p-1)` rounded `2p-1` to minus one for a small
positive probability and lost its relative accuracy near one half. The revised
transform separates the domain:

```text
1/4 < p < 3/4:
  r = 2p-1
  logit(p) = 2*(r + r^3/3 + r^5/5 + ...)

p <= 1/4 or p >= 3/4:
  h = min(p,1-p)
  abs(logit(p)) = log1p(-h)-log(h).
```

The central terms have one sign and `r^2<=1/4`. The first unchanged p39 sum
therefore has a geometric omitted tail below one p39 unit. At most about 70
terms are needed, and a directed-rounding accumulation gives a conservative
relative error below `2e-36`. The endpoint route uses the audited p39 `ln` and
`ln1p` calculations and has the same conservative bound. In particular,
`p=1e-6176` now gives

```text
-14220.76553433122614449511522413063...
```

and the closest Real34 value above one half gives `4e-34` before location and
scale. P34 has no margin for either route, while p39 retains at least one
decimal guard digit when the closing sum is well conditioned.

## Location-scale cancellation

The closing expression uses a fused multiply-add. Its condition is measured
from the adjusted exponents of `mu`, `s*logit(p)`, and their result. If the p39
sum loses more than one place, the complete transform is repeated at p51. A
loss above 13 places selects p75, and a loss above 37 places selects p159.

Scaling the p39 transform bound by these widths gives conservative
pre-cancellation relative bounds below `2e-36`, `2e-48`, and `2e-72` at p39,
p51, and p75 respectively. At each selection boundary, the amplified bound
is below `2e-35`. This keeps at least one decimal guard digit before Real34
conversion. A rounded Real34 approximation to `ln(3)` supplies a p75 case:

```text
p  = 0.25
mu = 1.098612288668109691395245236922526
s  = 1
q  = 2.953525094421772505482653056663625057...e-34.
```

For p159, local logarithm and central-series routines use buffers sized to that
context. Decimal range reduction confines the logarithm series argument to
an absolute value below `0.172`; its squared term ratio is below `0.030`.
Fewer than 1,000 directed rounded operations give a conservative arithmetic
bound below `1e-155` before cancellation. The closing expression remains
fused.

The following Real34 convergent to `ln(4)` consumes about 68 decimal places:

```text
p  = 0.8
mu = -9948943080304746708466068847957130
s  = 7176645422021113052528987965980483
q  = 6.321932881050330324635955817629240126...e-35.
```

All seven rounding modes select the expected Real34 endpoint from independent
220-digit decimal evaluation. P159 supplies over fifty decimal places beyond
this measured cancellation. An arbitrarily ill-conditioned affine sum cannot
support a universal correct-rounding claim from a fixed work width, which is
why the result claim remains faithful rather than universal.

## Domains, special values, and dispatch

Location and scale must be finite, and scale must be positive. A NaN variate
propagates through the public kernels. Density at either variate infinity is
zero. The lower probabilities at negative and positive infinity are zero and
one respectively; the upper probabilities use the opposite endpoints. The
inverse kernel has mathematical limits of negative and positive infinity at
probabilities zero and one, while the calculator command retains its strict
open probability domain. NaN probability is rejected.

Parameter and inverse-domain errors honour special-result mode without adding
a stale error code. The file-driven cases also confirm that real matrices are
rejected by the scalar register conversion.

## Regression evidence

On integration base `35fb528e`, the old upper probability at `x=100` was zero
and the old upper probability at positive infinity was one. The old deep
inverse example above returned `0.00006`. The revised simulator returns the
independently evaluated 34-digit results.

Disabling the p159 selection in the revised source made four focused directed
cases fail. The half-even value became
`6.321911789297634180385486013166042e-35`, with only five correct significant
digits. Restoring the adaptive selection makes all retained logistic cases
succeed. The focused file-driven run completes 135 of 135 cases, and the full
repository test target completes without failure. The cases are in the four
existing logistic file-driven test files; no extra executable test is
required.

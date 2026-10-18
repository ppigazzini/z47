# Binomial-distribution decimal contexts

## Scope and result

This audit covers the binomial density, lower probability, upper probability,
inverse, calculator entries, and their use by the shared discrete-quantile
solver. The public result type is Real34. The conventions are

```text
P(x) = Pr[X=x],
L(x) = Pr[X<=floor(x)],
R(x) = Pr[X>=ceil(x)],
I(u) = min { k : L(k)>=u }.
```

The parameter range is a finite integer `n>=0` and a finite probability
`0<=p<=1`. Matrix arguments do not have an elementwise distribution route and
produce the established type error.

| Calculation | Selected context | Reason |
| --- | ---: | --- |
| support and degenerate endpoints | caller p39 | results are exact zero or one |
| finite density | 51 | stable logarithmic beta prefix needs more than the five p39 guard digits |
| beta probability with either shape below `1e5` | 51 | conditioned Lanczos prefix plus a direct-tail continued fraction |
| beta probability with both shapes at least `1e5` | 75 | concentrated beta integration magnifies p51 input error |
| inverse search state | 39 | the shared discrete solver needs its established five guard digits; its CDF selects p51 or p75 internally |
| final public value | caller p39, then Real34 | calculator rounding is applied after the distribution calculation |

Differences caused only by conversion from p39 to Real34 are outside this
audit.

## Density

The former expression evaluated three large logarithmic terms independently,
using the generic `log(n choose k)` routine. For a finite interior parameter,
the revised form uses

```text
a = k+1,  b = n-k+1,
T = p^a (1-p)^b / B(a,b),
Pr[X=k] = T / (p (1-p) (n+1)).
```

`T` is the stable beta prefix shared with the F distribution. Its logarithm
groups the Lanczos terms and, for large shapes, groups the powers around the
beta mode. The two probability components and their logit are formed without
recovering a small component by subtracting from a rounded one. The input has
at most 34 digits, so `1-p` is exact in p51. `log1p` supplies the logarithm of
the component close to one.

The integrated Gamma analysis bounds the 30-term Lanczos-sum condition factor
below `9.5e13`. A conservative 100-operation p51 contribution is below
`5e-35` after that factor. Subsequent logarithmic arithmetic and the audited
p51 exponential remain below a Real34 unit. The largest finite Real34 `n`
adds fewer than seven decimal positions to `log(n+1)`, leaving ample p51
margin even when the density is close to one. P75 has no demonstrated density
benefit.

P39 is too narrow. At

```text
n=1000, k=400, p=0.37
```

4,096-bit MPFR gives

```text
Pr[X=400] =
0.003810328130974442554226345437431296130496281046437...
```

A deliberate p39 substitution in the stable formula has an error near
`-1.75686290e-28`; p51 gives the asserted Real34 value. At
`n=1e40, k=5e39, p=0.5`, the former formula underflowed to an effectively zero
result. The p51 beta-prefix expression gives

```text
7.978845608028653558798921198687637e-21.
```

The cases `p=0`, `p=1`, and `n=0` are evaluated before logarithms. This avoids
indeterminate products such as `0*log(0)` and gives the exact point masses.

## Lower and upper probabilities

For integer `k=floor(x)` and `m=ceil(x)`, the two public probabilities are

```text
L(x) = I_(1-p)(n-k, k+1),
R(x) = I_p(m, n-m+1).
```

Each requested side is obtained from a paired incomplete-beta calculation.
The smaller side is evaluated directly; the other side is its complement.
This prevents a small upper probability from being formed as `1-L`. A
modified Lentz fraction uses p51 and a `1e-42` successive-change criterion
when at least one beta shape is below `1e5`. Including the Lanczos bound above,
p51 is the narrowest established context for this route.

The same `n=1000, k=400, p=0.37` case gives

```text
L(400) = 0.9766949451853648761648148333437772947005319583139...
R(400) = 0.02711538294560956638941151209365400142996432273250...
```

With the stable algorithm forced to p39, the errors are about `7.652368e-28`
and `-4.04925419e-27`, respectively. P51 gives both Real34 assertions.

When both shapes are at least `1e5`, the shared beta routine integrates the
logit density in a coordinate scaled by

```text
sqrt((a+b)/(a*b)).
```

The density is formed relative to its mode, avoiding cancellation of terms
proportional to `a+b`. This route uses p75. The F-distribution audit bounds the
finite interval and double-exponential discretisation, and records identical
Real34 results when the node spacing is halved.

P51 is not sufficient for concentrated binomial probabilities. Symmetry gives

```text
L(n/2) = R(n/2) = 1/2 + Pr[X=n/2]/2
```

for even `n` and `p=1/2`. At `n=1e40`, independent MPFR evaluation of the
central mass gives

```text
L(5e39) = R(5e39)
         = 0.5000000000000000000039894228040143267793994605993...
```

A deliberate p51 calculation differs by about `-3.30e-32`, changing a Real34
digit. P75 gives

```text
0.5000000000000000000039894228040143.
```

If an interior finite probability rounds to zero or one at the work width, a
one-unit direction marker preserves its mathematical side before public
conversion. True support and degenerate endpoints remain exact.

## Inverse

The shared discrete solver retains p39 state, as established by its separate
audit. Its final integer is selected from adjacent CDF values, and each CDF
now chooses p51 or p75 from its beta shapes. Wider state would not add a digit
to the integer result.

The former starting approximation overwrote the mean `n*p` with the variance
and used `sqrt(1-p)` as the standard deviation. The corrected quantities are

```text
mean = n*p,
variance = n*p*(1-p),
standard deviation = sqrt(variance).
```

Newton refinement and adjacent-CDF selection are unchanged. The former code
returned `2.5e39` for `I(0.5)` with `n=1e40, p=0.5`; the corrected route
returns `5e39`. For `n=1e6, p=0.5`, explicit 4,096-bit MPFR sums give

```text
L(493881) = 9.840952662636792177510157795794896e-35,
L(493882) = 1.008639091720711517180443237880263e-34.
```

The resulting inverse at `u=1e-34` is `493882`; the symmetric upper case at
`u=0.9999999999999999999999999999999999` is `506118`.

## Domains, matrices, and evidence

Forward functions accept values outside `[0,n]` and return their exact support
values. Lower probability uses `floor(x)` and upper probability uses
`ceil(x)`. In particular, `R(n+epsilon)=0`; the earlier endpoint test admitted
this argument to an invalid beta shape. `n=0`, `p=0`, and `p=1` now produce
their degenerate distributions. NaN parameters produce the normal domain
error or a NaN when special results are enabled. Infinite `n` is rejected;
infinite forward `x` uses the support endpoint.

Real and complex matrices are rejected by `getRegisterAsReal`; no binomial
kernel receives a matrix element. The existing four file-driven suites now
exercise this interface explicitly.

Independent values used 4,096-bit MPFR logarithmic Gamma for density and
explicit probability sums for finite `n` through `1e6`. The large symmetric
case combines the MPFR central mass with the exact identity above. The former
source succeeded in 13 of 19 focused audit checks. The stable implementation
forced entirely to p39 succeeded in 14 of 19; forced entirely to p51 succeeded
in 17 of 19; the selected p51/p75 split succeeded in all 19. The expanded
existing binomial files succeed in all 150 checks. The clean repository suite
succeeds in all 16,056 checks, with zero failures and no GMP allocation left.

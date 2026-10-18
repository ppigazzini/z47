# Negative-binomial decimal contexts

## Scope and result

This audit covers negative-binomial mass, lower probability, upper probability,
inverse, calculator entries, and the calls made by the shared discrete-quantile
solver. The public result type is Real34. For

```text
Pr[X=k] = C(k+r-1,k) p^k (1-p)^r,
```

the conventions are

```text
P(x) = Pr[X=x],
L(x) = Pr[X<=floor(x)],
R(x) = Pr[X>=ceil(x)],
I(u) = min { k : L(k)>=u }.
```

The parameter range is a finite positive integer `r` and a finite probability
`0<=p<1`. At `p=0` the law is a point mass at zero. The other probability
endpoint has no finite negative-binomial law and remains a domain error.

| Calculation | Selected context | Reason |
| --- | ---: | --- |
| support and the `p=0` endpoint | caller p39 | results are exact zero or one |
| finite mass | 51 | stable logarithmic beta prefix needs more than the five p39 guard digits |
| beta probability with either shape below `1e5` | 51 | conditioned Lanczos prefix plus a direct-tail continued fraction |
| beta probability with both shapes at least `1e5` | 75 | concentrated beta integration magnifies p51 input error |
| inverse search state | 39 | the shared discrete solver uses five guard digits; each CDF or mass call selects its wider context internally |
| final public value | caller p39, then Real34 | calculator rounding is applied after distribution evaluation |

Differences caused only by conversion from p39 to Real34 are outside this
audit.

## Mass

The former formula evaluated a combination coefficient and two powers through
separate logarithmic terms. Its subtraction loses nearly all useful digits
when `x` and `r` are large. The revised form puts `a=x+1`, `q=1-p`, and uses

```text
T = p^a q^r / B(a,r),
Pr[X=x] = T / (p (x+r)).
```

`T` is the stable beta prefix shared with the F and binomial distributions.
The Lanczos terms are grouped, and large shapes use powers relative to the
beta mode. The two probability components and their logit are formed without
recovering a small component by subtraction from a rounded complement. A
Real34 input makes `1-p` exact in p51, and `log1p` supplies the logarithm of
the component close to one.

The integrated Gamma analysis bounds the 30-term Lanczos-sum condition factor
below `9.5e13`. The shared beta-prefix analysis places its p51 error below a
Real34 unit with at least three guard digits for moderate shapes. This mass
adds one logarithm and two subtractions before the audited p51 exponential.
The `x=0` route uses `r*log(1-p)` directly, avoiding an unnecessary
`log(p)` subtraction. No p75 density benefit was found.

P39 is too narrow. At

```text
r=601, x=400, p=0.37,
```

4,096-bit MPFR gives

```text
Pr[X=400] =
0.0024005067225138988091625976255817165622126570592554154996111477...
```

A deliberate p39 substitution in the stable formula leaves an expected-minus-
calculated residual near `-1.10682362e-28`. It also changes results in the
small pre-existing cases by as much as about `1e-27`. P51 gives the retained
Real34 results.

For the concentrated symmetric case `r=x=1e40`, `p=1/2`, the identity

```text
Pr[X=r] = C(2r,r) 4^(-r) / 2
```

and independent MPFR evaluation give

```text
Pr[X=r] =
2.82094791773878143474039725780386292922021788479602254945...e-21.
```

The former formula gives about `3.6164e-652`. The revised p51 beta-prefix form
gives `2.820947917738781434740397257803863e-21`.

## Lower and upper probabilities

For `k=floor(x)` and `m=ceil(x)`, the two probabilities are

```text
L(x) = I_(1-p)(r,k+1),
R(x) = I_p(m,r).
```

Each requested side comes from the paired incomplete-beta calculation shared
with the F distribution. The smaller side is evaluated directly and the other
side is its complement, so a small upper probability is not obtained by
subtracting a near-one lower probability from one.

When at least one beta shape is below `1e5`, a modified Lentz fraction uses
p51 with a `1e-42` successive-change criterion. The grouped Lanczos prefix and
continued fraction have the error bounds documented by the F and binomial
audits. The following MPFR values provide direct p39 discriminators:

```text
L(400; r=600, p=0.37) =
0.9766949451853648761648148333437772947005319583139383264479...

R(399.1; r=601, p=0.37) =
0.02711538294560956638941151209365400142996432273249884101178...
```

Forcing p39 leaves expected-minus-calculated residuals near `7.652368e-28`
and `-4.04925419e-27`, respectively. P51 gives both retained Real34 values.

When both shapes are at least `1e5`, the shared beta routine integrates the
logit density in a coordinate scaled by

```text
sqrt((a+b)/(a*b)).
```

The density is evaluated relative to its mode, avoiding cancellation in terms
proportional to `a+b`. This route uses p75. The F-distribution analysis gives
the finite-interval and double-exponential discretisation bounds and records
unchanged Real34 values when the node spacing is halved.

P51 is insufficient for concentrated negative-binomial probabilities. At
`r=x=1e40`, `p=1/2`, symmetry gives

```text
L(r-1) = I_(1/2)(r,r) = 1/2,
L(r)   = 1/2 + Pr[X=r],
R(r)   = 1/2.
```

Thus

```text
L(r) =
0.5000000000000000000028209479177387814347403972578038629...
```

The p51 route has a residual magnitude near `1.163e-31`, which changes
Real34 digits. P75 gives

```text
0.5000000000000000000028209479177388.
```

If a finite interior probability rounds to zero or one at its work width, a
one-unit direction marker preserves its mathematical side before public
conversion. Exact support and degenerate endpoints remain exact.

## Inverse and shared helpers

The shared discrete solver retains p39 state, as established by its separate
audit. Its negative-binomial CDF and mass callbacks now validate the complete
parameter pair and select p51 or p75 internally. The final integer is selected
from adjacent CDF values, so a wider search state would not add a digit to the
result.

The initial estimate uses

```text
mean = r*p/(1-p),
variance = r*p/(1-p)^2,
standard deviation = sqrt(variance).
```

The `p=0` case returns zero before these expressions. The internal inverse
also defines the extended target endpoints as zero and positive infinity;
the calculator entry retains its established strict `0<u<1` domain.

At `r=1000000`, `p=1/2`, explicit 4,096-bit MPFR recurrence gives

```text
L(982769) = 9.938468402023272223442460459495266e-35,
L(982770) = 1.002616374541630619125401507136277e-34.
```

The inverse at `u=1e-34` is therefore `982770`. This case exercises the p51
CDF dependency and the adjacent-value selection in the p39 solver.

The adjacent comparison keeps the p51 CDF rather than reducing it to the p39
search context. For `r=1`,

```text
p = 0.1730308614747440923815211764011360,
u = 0.9700603209773079206557417474640028,
```

independent decimal arithmetic gives

```text
L(1) =
0.9700603209773079206557417474640027999995913157804692669...
u-L(1) = 4.0868421953073307e-40...
```

The p39 image of `L(1)` equals `u`, while the p51 value is below it. Direct
comparison therefore returns 2; reducing the CDF to p39 returns 1.

For `r=1`, the CDF reduces to `1-p^(k+1)`. With
`p=0.9999999999999999999999999999999999` and `u=1/2`, 250-digit decimal
evaluation of `ceil(-log(2)/log(p))-1` gives the exactly representable integer
`6931471805599453094172321214581765`. The p39 search produces that result.

## Domains, matrices, and evidence

Forward entries accept values outside the finite support and return exact
support results. The mass is zero for negative values, positive infinity, and
nonintegers. Lower probability is zero at negative infinity and one at
positive infinity; upper probability has the opposite endpoints. Lower uses
`floor(x)` and upper uses `ceil(x)`.

The register checker rejects NaN arguments, `p<0`, `p>=1`, nonpositive `r`,
nonintegral `r`, and special parameters. Special-result mode now returns NaN
without retaining a diagnostic code. Real and complex matrices are rejected
by `getRegisterAsReal`; no elementwise negative-binomial route exists.

Independent values used 4,096-bit MPFR logarithmic Gamma for masses and
explicit probability recurrence for finite parameters through `r=1e6`. The
large symmetric case combines the MPFR central mass with the exact beta
symmetry above.

Before the source change, a 25-check audit addition succeeds in 13 cases and
fails in 12. The selected source succeeds in all 199 assertions retained in
the existing four negative-binomial files. Context mutations give these
additional results:

- p39 mass evaluation fails 19 of 173 focused assertions;
- p39 beta-tail evaluation fails 33 of 173 focused assertions;
- p51 for every beta tail fails the scaled concentrated case;
- the selected p51/p75 beta split succeeds in all 175 mutation assertions.

The clean repository suite succeeds in all 16,383 assertions, with zero
failures and no GMP allocation left.

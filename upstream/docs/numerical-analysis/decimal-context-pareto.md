# Pareto-distribution decimal contexts

## Scope and result

This audit covers the type-I and type-II Pareto density, lower probability,
upper probability, and inverse functions in `src/c47/distributions/pareto.c`.
Every public result is Real34. Distribution commands remain scalar, so real and
complex matrices produce the established type error.

The revised routines target faithful 34-digit results. They do not claim
universal correct rounding for transcendental calculations. Differences caused
only by conversion from a half-even work context to Real34 are outside this
audit.

| Calculation | Selected context | Reason |
| --- | ---: | --- |
| both densities and both tails | 51 | the logarithm error is amplified by the full finite Real34 exponential range |
| type-I inverse | 51 | no closing cancellation occurs, but a large exponent still amplifies logarithm error |
| ordinary type-II inverse | 51 | sufficient when the closing location-scale sum removes at most eight decimal places |
| type-II inverse after 9 to 30 removed places | 75 | the closing fused operation retains the smaller result |
| deeper type-II cancellation | 159 | local logarithm and exponential-minus-one series avoid 75-digit helper limits |
| final public conversion | Real34 | the selected calculator rounding mode is applied here |

## Stable common formula

For nonnegative distance `d` from the lower support endpoint, scale `sigma>0`,
and shape `alpha>0`, define

```text
r = d/sigma;
w = -alpha*log1p(r).
```

Both distribution types then use

```text
upper   = exp(w);
lower   = -expm1(w);
density = alpha*exp(w)/(sigma+d).
```

Type I has `d=x-sigma`; type II has `d=x-mu`. This common form avoids rounding
`sigma/x` to one beside the support, avoids subtracting an upper probability
from one, and removes the general power operation from the forward routes. It
also avoids the former type-II denominator association `x+sigma-mu`.

For `r>=0`, the relative condition factor of `log1p(r)` with respect to `r` is

```text
r / ((1+r)*log1p(r)) <= 1.
```

Division, the logarithm, and multiplication therefore form `w` without an
extra conditioning factor. The completed logarithm analysis gives a
conservative p51 relative arithmetic bound below `9.1e-49`. When a survival
probability is finite and nonzero in Real34, `abs(w)<14222`, so its absolute
formation error is below `1.4e-44`. The exponential contributes at most one p51
result unit. The density adds four correctly rounded positive operations, and
its arithmetic error remains below `1.5e-44` relatively for a finite nonzero
result.

For the lower probability, the relative condition factor from `w` to
`-expm1(w)` is at most one. Thus the small lower tail retains the same p51
relative scale instead of suffering cancellation against unity. A finite
strict probability that rounds to zero or one inside p51 is replaced by the
adjacent p51 value on the mathematical side. This marker affects directed
Real34 conversion while leaving nearest conversion unchanged.

P39 is insufficient for the composite forward calculation. Its logarithm
bound permits about `1.3e-32` absolute error in `w` near the Real34 lower
probability boundary. With

```text
sigma = 1
x     = 2
alpha = 20000.12345678901234567890123456789
```

the independently evaluated survival probability is

```text
2.306335711554963691812736089917255115089...e-6021.
```

The selected p51 result has the stated Real34 value. A deliberate p39 change is
one Real34 unit lower. P51 is therefore the narrowest established context for
the forward family.

## Type-I inverse

For lower probability `p`, the revised type-I inverse evaluates

```text
q     = -log1p(-p)/alpha;
delta = expm1(q);
x     = fma(sigma, delta, sigma).
```

The fused form retains an increase too small to survive a separately rounded
addition to `sigma`. A finite Real34 result constrains `q` to less than about
28,370 in magnitude across the possible scale range. Applying the p51
logarithm bound gives an absolute error below `2.7e-44` in `q`, and hence the
same first-order relative scale in the exponential result. P39 again has no
34-digit margin over the complete range.

The endpoints are direct: `p=0` returns `sigma`, while `p=1` returns positive
infinity. If a finite interior result exceeds the p51 exponent range, the
largest finite p51 value is used before conversion. This lets a directed
Real34 mode select its finite overflow boundary.

## Type-II inverse and cancellation

The type-II inverse uses

```text
q      = -log1p(-p)/alpha;
delta  = expm1(q);
scaled = sigma*delta;
x      = fma(sigma, delta, mu).
```

The former expression rearranged this value through
`((mu-sigma)*t+sigma)/t`. At `p=0`, a large `sigma` could erase `mu` before the
algebra returned to the endpoint. The direct endpoint now copies `mu`.

For an interior probability, p51 is used first. Before cancellation its
relative error is below `2.8e-44` over the finite Real34 output range. If the
adjusted exponents of `mu`, `scaled`, and their fused sum indicate more than
eight removed decimal places, the calculation is repeated at p75. The
corresponding pre-cancellation bound is below `2.8e-68`. Up to 30 removed
places therefore leaves more than three guard digits for Real34.

The following Pell convergent removes 23 places:

```text
p     = 0.5
alpha = 2
mu    = -107578520350
sigma = 259717522849
x     = 1.3612997179201883101525316451916831508...e-12.
```

A p51-only variant first differs at result digit 28, while the p75 retry gives
the displayed Real34 value.

## Extended cancellation route

More than 30 removed places selects a local p159 calculation. The shared
logarithm and exponential-minus-one helpers use fixed 75-digit temporary
storage and are therefore not called with p159. For `p<=1/2`, the local
logarithm uses

```text
a = -p/(2-p);
log(1-p) = 2*(a + a^3/3 + a^5/5 + ...),  abs(a)<=1/3.
```

For `p>1/2`, repeated square roots first move `1-p` above `sqrt(1/2)`, after
which the same atanh series has `abs(a)<0.172`; the result is rescaled by the
corresponding power of two. The 1,000-term limit has a truncation below
`1e-950` in the slower branch. Fewer than 5,100 rounded elementary operations
give an arithmetic accumulation below `2.6e-155` at p159.

For `q<0.1`, `expm1(q)` is accumulated as its positive Taylor series. The term
ratio is at most `0.1/n`, and the 1,000-term limit is far beyond the p159
rounding threshold. For `q>=0.1`, a direct p159 exponential followed by
subtraction has condition factor at most 10.51 at the branch boundary. The
combined pre-cancellation error remains below `4e-154` relatively.

The 34-digit Pell pair

```text
p     = 0.5
alpha = 2
mu    = -4125636888562548868221559797461449
sigma = 9960168529794442859224531878561050
```

has inverse

```text
-3.549672774468308801422504319938411217679...e-35.
```

P75 retains only six significant digits after the 68-place cancellation. The
p159 route retains more than eighty error-margin digits for this input and
gives the independently rounded result in all seven calculator modes. This is
a concrete wide-margin result, not a universal conditioning guarantee for
every possible parameter tuple.

## Domain, range, and special values

Scale and shape must be finite and positive. The type-II location must be
finite. NaN variates and inverse probabilities produce the domain response;
special-result mode converts that response to NaN without a stale error code.
Forward evaluation keeps positive infinity as a valid variate endpoint, giving
density zero and lower and upper probabilities one and zero. A variate below
the applicable lower support endpoint retains the established domain error.

Inverse probabilities use the closed interval from zero through one. Type I
returns its scale at zero; type II returns its location; both return positive
infinity at one. Values outside the interval are rejected. Finite density or
inverse results beyond the Real34 exponent range stay finite in the wider work
context long enough for the selected directed mode to choose the correct
Real34 range boundary.

## Verification

The cases reside in the existing `dist_cov.txt` file. They cover independent
34-digit values for all eight public functions, all seven result modes in the
deep cancellation case, both inverse endpoints, strict underflow and unity
sides, finite overflow, infinite variates, invalid parameters, NaN, support
errors, and matrix rejection.

A replay of the former source against the initial 90-check file succeeds for
86 checks. Its four failures are the deep type-II cancellation, the type-II
zero endpoint, a zero shape, and an infinite scale. With the final 163-check
file, a deliberate p39 forward and ordinary-inverse variant succeeds for 162
checks, a p51-only inverse variant succeeds for 140, and a p75-only variant
succeeds for 149. The selected implementation succeeds for all 163 focused
checks. The clean repository-wide result is 16,953 checks with zero failures
and zero GMP-owned bytes.

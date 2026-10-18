# Chi-square distribution decimal contexts

## Scope and result

This audit covers the chi-square density, lower probability, upper probability,
inverse, and calculator entry functions in `src/c47/distributions/chi2.c`. The
public result type is Real34. The calculator interface requires a positive
integral number of degrees of freedom. Matrix arguments have no elementwise
distribution route and produce the established type error.

The revised calculations target faithful 34-digit results. They do not claim
universal correct rounding. Differences caused only by conversion from p39 to
Real34 are outside this audit.

| Calculation | Selected context | Reason |
| --- | ---: | --- |
| density | 51 | the stable Lanczos expression needs more than the five p39 guard digits |
| public lower and upper probabilities | 39, with an adaptive p51 Gamma transition | direct regularised-gamma tails avoid complement cancellation |
| inverse state, density, and probability | 51 | the logarithmic state needs absolute resolution below `1e-34` at magnitude 28441 |
| final public result | caller context, then Real34 | calculator rounding is applied after the complete result is available |

## Density

Put `a=k/2` and `y=x/2`. The mathematical density is

```text
f(x;k) = exp((a-1) log(y) - y - log Gamma(a)) / 2.
```

The former expression evaluated `log Gamma(a)` independently and subtracted
terms of size `a log(a)` near the mode. P75 cannot recover digits removed by
that formulation when `k` is near the upper Real34 range. At `k=x=1e40` it
gave about `9.29e-166` instead of
`2.820947917738781434740397257803863e-21`.

The revised expression uses the 30-term Lanczos sum directly. Let

```text
h = gammaR - 1,  r = a+h,  delta = (y-r)/r,
S = LanczosSum(a-1).
```

Near the mode the logarithm becomes

```text
log f = a*(log1p(delta)-delta) - log1p(delta) - h*delta
        - log(r)/2 - log(S) - log(2).
```

The power series for `log1p(delta)-delta` begins with `-delta^2/2`, so no
linear term is removed by subtraction. Away from the mode the equivalent form

```text
log f = (a-1)*log(y/r) + r-y - log(r)/2 - log(S) - log(2)
```

has adequate separation. The incomplete-gamma audit bounds the Lanczos-sum
condition factor below `9.5e13`. A conservative allowance of 100 p51 rounded
operations gives less than `5e-35` relative error after this factor, leaving
more than two decimal guard places. A deliberate p39 mutation at `k=x=1e6`
gave only 27 correct significant digits. P51 is therefore the narrowest
established project context for this density formula.

The exact density endpoints are

```text
f(0;k) = +Infinity, k<2
f(0;2) = 1/2
f(0;k) = 0, k>2
f(+Infinity;k) = 0.
```

A positive result below the least Real34 subnormal is compared with its
halfway point before conversion. Values below halfway map to zero in all three
nearest modes; values above it map to the subnormal. At equality, ties-away
maps to the subnormal while ties-even and ties-to-zero map to zero.
Toward-positive and away-from-zero map every positive value to the subnormal;
toward-zero and toward-negative map it to zero. This explicit selection also
covers a work-context exponential that has already underflowed to zero.

## Lower and upper probabilities

The distribution identities are

```text
P(X <= x) = P(k/2,x/2),
P(X >  x) = Q(k/2,x/2).
```

Each requested tail is evaluated directly. A small upper tail is never formed
by subtracting a rounded lower result from one. Multiplication by one half is
exact in decimal arithmetic, so p39 input preparation introduces no error.
The shared calculation raises its outer large-shape transition to p51 where a
p39 error in the normalised displacement would be magnified by the shape.
The context and transition-region bounds for `WP34S_GammaP` are documented in
`decimal-context-incomplete-gamma.md`.

The endpoints are `(0,1)` at `x=0` and `(1,0)` at positive infinity for lower
and upper probabilities respectively. A finite positive argument has two
strictly interior probabilities. Marking an underflowed small tail before the
final conversion preserves directed rounding; marking a value rounded to one
preserves the corresponding downward modes. The three nearest modes,
away-from-zero, and toward-positive round that marker to one; toward-zero and
toward-negative produce the Real34 predecessor of one.

## Inverse

The inverse uses the smaller requested tail. It solves in `w=log(x)`, with

```text
dP/dw = x*f(x),       dQ/dw = -x*f(x).
```

For a lower-tail probability `p`,

```text
d log(x) / d log(p) = p/(x*f(x)) -> 1/a = 2/k
```

at zero. The positive-term series for the lower ratio bounds this condition by
`1+1/a<=3` before the median. The upper gamma-density ratio decreases from a
value below three on the smaller-tail half and tends to `2/x`. Around the centre
the condition decreases like `1/sqrt(k)`. Five accurate probability guard
digits are therefore sufficient for a faithful Real34 inverse.

The state itself requires p51. For the least positive Real34 probability and
`k=1`,

```text
x = (pi/2)*p^2*(1+O(p^2)),
log(x) = -28440.62790325187337926...
```

A p39 value at this logarithmic magnitude has an absolute unit near `1e-34`,
which has no error margin for a 34-digit relative result. P51 supplies about
twelve further state digits. The finite log interval `[-30000,16000]` includes
the complete Real34 result range and the `k=1` lower-tail minimum.

For `k>=1e80`, an interior Real34 probability cannot produce a Real34
displacement from `k`.
The chi-square concentration inequalities, with
`t=-log(1e-6176)<14221`, bound every finite Real34 quantile by

```text
k - 2*sqrt(k*t) <= x <= k + 2*sqrt(k*t) + 2*t.
```

The relative displacement is below `2.4e-38`, less than one thousandth of
half a Real34 unit. The median is below the mean `k`. For the next Real34
probability above one half, a Berry-Esseen bound applied to the sum of squared
normal variables gives `P(X<=k)-1/2 < 13/sqrt(k) < 1.3e-39`; its quantile is
therefore above `k`. A p39 adjacent value on the established side of `k`
preserves all seven directed Real34 conversions without trying to represent an
unresolvable displacement.

A sign-changing bracket surrounds the root. Newton proposals use the stable
log-density derivative and are accepted only inside that bracket. After 24
proposals, midpoint refinement is mandatory. An absolute bracket width below
`1e-40` bounds the relative uncertainty in a finite result. The 240-iteration
maximum exceeds the 149 midpoint reductions needed by the widest finite
interval. Exact endpoints return zero and positive infinity from the exported
kernel; the calculator function retains its open probability domain.

## Domains, matrices, and special values

The public calculator functions require finite positive integral `k`, finite
nonnegative `x` for the inverse-independent operations, and `0<p<1` for the
inverse. NaN and infinite degrees of freedom now produce the distribution
parameter error. NaN `x` and NaN `p` produce the argument-domain result.
Positive infinity is accepted only as a density or probability abscissa.
Both signs of zero select the exact lower support endpoint.

Real and complex matrices are rejected by `getRegisterAsReal`; no matrix
calculation calls a chi-square kernel. Existing file-driven cases assert that
interface behaviour.

## Regression evidence

Before this change:

- `k=1, x=0` gave density zero instead of positive infinity;
- `k=2, x=0` gave density zero instead of one half;
- the density at positive infinity was NaN instead of zero;
- `k=x=1e40` lost more than 140 decimal orders in the density;
- finite positive densities and tails below the wide exponential range became
  zero in upward rounding modes;
- `k=x=1e30` produced a negative lower probability and an upper probability
  greater than one;
- inverse cases at `k=1e6` and `k=1e30` reported no root;
- fractional, infinite, and NaN degrees could enter the numerical kernels.

Independent values use 120-decimal-digit gamma evaluation, closed forms for
one and two degrees of freedom, and large-shape asymptotic checks. For the
`k=1e30, p=1e-34` inverse discriminator, the normal quantile and constant
Cornish-Fisher term determine the value through the Real34 place; the first
discarded term is below `1e-12` in the result. At `p=1e-6176` that term remains
below `4e-10`, while the Real34 unit is `1e-4`. The retained file-driven cases
are in `chi2_p.txt`, `chi2_l.txt`, `chi2_r.txt`, and `chi2_i.txt`. They cover
density cancellation and range, direct central tails, inverse tail
conditioning, exact endpoints, representative result modes for every distinct
underflow direction, invalid values, and matrix rejection.

After rebasing onto the incomplete-gamma transition change `35431d2`, the
four-file focused run completed 199 of 199 checks and a clean `make test`
completed 15991 of 15991 checks. The sole build diagnostic was the existing
macOS linker alignment warning.

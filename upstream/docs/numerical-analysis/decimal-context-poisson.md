# Poisson distribution decimal contexts

## Scope and result

This audit covers the Poisson probability mass, lower probability, inclusive
upper probability, inverse, and calculator entry functions in
`src/c47/distributions/poisson.c`. The public result type is Real34. Matrix
arguments have no elementwise distribution route and produce the established
type error.

The revised calculations target faithful 34-digit results. They do not claim
universal correct rounding or universal discrete classification when an exact
CDF step is arbitrarily close to a Real34 probability. Differences caused only
by conversion from p39 to Real34 are outside this audit.

| Calculation | Selected context | Reason |
| --- | ---: | --- |
| mass, integral `x<205` | 39 | bounded factorial and logarithm evaluation leaves more than two guard digits |
| mass, integral `x>=205` | 51 | the stable Lanczos expression loses visible digits at p39 |
| public lower and upper probabilities | 39, with the Gamma dependency's adaptive p51 route | direct tails and a recurrence avoid complement and successor loss |
| inverse bracket state | 39 | a relative width below `1e-37` leaves at least three Real34 guard digits |
| inverse CDF classification | 51 | a discrete threshold needs more protection than a rounded public probability |
| final public result | caller context, then Real34 | calculator rounding is applied after the complete result is available |

## Probability mass

For a nonnegative integer `n`,

```text
Pr(X=n) = exp(n log(lambda) - lambda - log Gamma(n+1)).
```

The former calculation evaluated all three large terms independently. At
`n=lambda=1e40` it returned one instead of approximately `3.989e-21`; the
terms of order `lambda log(lambda)` had removed the whole result.

For `n>=205`, let

```text
r = n + gammaR,
delta = (lambda-r)/r,
S(n) = c0 + sum(c[k]/(n+k), k=1..29).
```

The Lanczos formula gives the equivalent log mass

```text
n*log(lambda/r) + r-lambda - log(r)/2 - log(S(n)).
```

When `abs(delta)<1e-6`, this becomes

```text
n*(log1p(delta)-delta) - gammaR*delta
  - log(r)/2 - log(S(n)).
```

The series for `log1p(delta)-delta` starts with `-delta^2/2`, so no linear
term disappears in a subtraction. The 30-term Lanczos sum uses its 75-digit
coefficient source but p51 arithmetic. The incomplete-gamma audit bounds the
sum condition factor below `9.5e13`; allowing 100 p51 rounded operations gives
a conservative relative contribution below `5e-35`. The exponential adds one
further p51 rounding.

An independent 768-bit MPFR calculation gives

```text
Pr(X=1000000), lambda=1000000
= 0.00039894224715624402970454398681603854910614636243055968...
```

The p51 route gives the displayed Real34 value ending in `...60385`. A
deliberate p39 substitution gives `...8203937`, with the first disagreement
before digit 34. P51 is therefore the narrowest established context for the
large-integer formula.

For `n<205`, the existing exact factorial product contains at most 204
multiplications. Its p39 product bound is

```text
204*u39/(1-204*u39) < 1.03e-36.
```

The remaining logarithmic expression can lose fewer than four decimal places
near its mode, so p39 is sufficient there.

A positive mass can be smaller than the Real34 subnormal range. The result is
compared with the half-minimum boundary before conversion. The three nearest
modes select zero below that boundary; ties-away selects the minimum at the
boundary. Toward-positive and away-from-zero select the minimum for every
positive exact mass, while toward-zero and toward-negative select zero.

## Lower and inclusive upper probabilities

For integral `n>=0`, the lower probability is

```text
Pr(X<=n) = Q(n+1,lambda).
```

For an inclusive upper threshold `n>=1`,

```text
Pr(X>=n) = P(n,lambda).
```

Each requested tail is evaluated directly through the audited regularised
incomplete-gamma dependency. No small tail is obtained by subtracting a
rounded result from one.

P39 cannot form `n+1` once the adjusted exponent of `n` reaches 39. The former
lower probability therefore evaluated `Q(n,lambda)` in that range. At
`n=lambda=1e40` it returned

```text
0.4999999999999999999986701923986619
```

instead of

```text
0.5000000000000000000026596152026762.
```

The new route tests whether `n+1` survived at p39. If it did not, the exact
recurrence

```text
Q(n+1,lambda) = Q(n,lambda) + Pr(X=n)
```

uses the stable p51 mass. Both terms are nonnegative, so the addition cannot
cancel. The p39 Gamma error remains the limiting contribution and leaves five
working digits beyond Real34.

For finite input and positive finite `lambda`, every non-endpoint probability
is strictly between zero and one. Explicit interior markers preserve the side
of zero or one after working-range underflow. If `n=lambda` is integral, both
`Pr(X<=n)` and `Pr(X>=n)` exceed one half. A p39 marker toward one preserves
that fact when a very large shape rounds either result to exactly one half.

## Inverse

The quantile is the least integer `n` for which

```text
Pr(X<=n) >= p.
```

The former shared Newton route treated the distribution as locally smooth and
stopped when its estimate moved by less than one tenth. Its final check only
examined that estimate and its next integer. It returned 998724 and 1001277 at
`lambda=1e6`, `p=.1` and `.9`; independent CDF classification gives 998719
and 1001282. At `lambda=1e40`, `p=.1`, the same route returned about
`2.5e39`, far outside the quantile region.

The revised inverse uses a monotone integer bracket. Zero is tested first.
The opening upper endpoint is `ceil(lambda)` and doubles until its lower CDF
is at least `p`. For `lambda>=1`, the Poisson Chernoff bound puts every Real34
upper-tail target below a small multiple of `lambda`; for `lambda<1`, 32
doublings from one are far beyond the largest quantile permitted by the
closest Real34 probability to one.

At each bisection, the lower endpoint has CDF below `p` and the upper endpoint
has CDF at least `p`. When p39 represents unit increments, width at most one
therefore identifies the exact integer. At larger magnitudes, a relative width
below `1e-37` gives more than three decimal guard digits for the final Real34
value. A p39 midpoint adds less than `1.01e-38` relative error. Two hundred
iterations exceed the 124 midpoint reductions needed for the relative-width
criterion. CDF classification uses p51; the shared Gamma transition can still
select its narrower proved route internally.

For `lambda>=1e74`, every Real34 input value for `lambda` is integral. With
`t=-log(1e-6176)<14221`, Poisson concentration bounds every finite Real34
quantile displacement by terms no larger than

```text
sqrt(2*lambda*t) + 2*t.
```

The relative displacement is below `1.7e-35`, less than one twentieth of half
a Real34 unit. The Poisson median bound
`lambda-log(2) <= median <= lambda+1/3` makes the median exactly `lambda` for
integral `lambda`. A Berry-Esseen bound of order `1/sqrt(lambda)` shows that
the next distinct Real34 probability below or above one half has a quantile on
the corresponding side of `lambda`. P39 adjacent values encode that side for
all directed Real34 conversions, while `p=.5` returns exact `lambda`.

## Domains, endpoints, and matrices

The calculator functions require finite positive `lambda`, nonnegative `x`
for the inverse-independent operations, and `0<p<1` for the inverse. NaN and
infinite parameters produce the distribution-parameter error. NaN `x` and NaN
`p` produce the argument-domain result. Positive infinity has zero mass, lower
probability one, and inclusive upper probability zero. Both signs of zero
select the support endpoint. The exported inverse kernel also defines `p=0`
as zero and `p=1` as positive infinity; the calculator interface retains its
open probability domain.

Real and complex matrices are rejected by `getRegisterAsReal`; no matrix
calculation calls a Poisson kernel. Existing file-driven cases assert that
interface behaviour.

## Regression evidence

The retained cases in `poisson_p.txt`, `poisson_l.txt`, `poisson_r.txt`, and
`poisson_i.txt` cover mode cancellation, the lost lower-CDF successor,
inclusive upper-tail semantics, inverse integer classification, extreme
exponents, representative result modes for every distinct underflow direction,
central half-side markers, invalid values, and matrix rejection. The large
`lambda=1e40` mass and central probabilities also agree with the Stirling and
Temme expansions; their first omitted displayed contributions are below
`1e-40` in relative mass and below `1e-40` in absolute probability.

The focused Poisson run completed 150 of 150 cases successfully. A clean full
test run completed 16,062 of 16,062 cases successfully.

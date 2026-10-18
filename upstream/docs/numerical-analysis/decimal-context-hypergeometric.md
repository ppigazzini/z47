# Hypergeometric distribution decimal contexts

## Scope and result

This audit covers the probability mass, lower probability, inclusive upper
probability, inverse, and calculator entry functions in
`src/c47/distributions/hyper.c`. The public result type is Real34. Matrix
arguments have no elementwise distribution route and produce the established
type error.

The revised calculations target faithful 34-digit results. They do not claim
universal correct rounding or discrete classification when an exact CDF step
is arbitrarily close to a Real34 probability. Differences caused only by
conversion from p39 to Real34 are outside this audit.

| Calculation | Selected context | Reason |
| --- | ---: | --- |
| support and final conversion | 39 | additions, comparisons, and one final rounded move |
| mass and probability sums, `N<=1e6` | 51 | cancellation in three log-combinations excludes p39 |
| mass and probability sums, `N>1e6` | 75 | the number of significant recurrence terms can grow as the standard deviation |
| large balanced mass, `N>=1e12` | 75 | a deviance and Stirling expression removes factorial-scale cancellation |
| inverse bracket | 39 | relative width below `1e-37` gives three or more Real34 guard places |
| inverse CDF classification | 75 | classification uses the direct-tail calculation before final conversion |

## Parameter transformations and support

For population size `N`, marked population count `K`, and sample size `n`, the
support is

```text
max(0,n+K-N) <= X <= min(n,K).
```

The distribution is unchanged by exchanging `n` and `K`. Marked-population
complementation maps `X` to `n-X`, and sample complementation maps `X` to
`K-X`. Applying these identities makes both `n` and `K` no greater than
`N/2`. Mass is unchanged; lower and inclusive upper probabilities exchange
after an odd number of reflections. This also turns a support with a large
lower endpoint into one beginning at zero, so recurrence factors retain their
small differences.

The former calculator check rejected every variate outside the support. That
made lower and upper endpoints unavailable and also interpreted the inverse
probability as a variate. For `N=100`, `n=K=90`, the valid inverse input
`p=.5` produced a domain error even though the quantile is 81. The new kernels
define mass as zero outside the support, lower probability as zero or one
beyond its endpoints, inclusive upper probability in the opposite order, and
inverse endpoints as the two support endpoints.

## Probability mass

The defining formula is

```text
Pr(X=x) = C(K,x) C(N-K,n-x) / C(N,n).
```

Three independent log-Gamma differences remove most working digits near the
mode. At `N=1e6`, `n=K=5e5`, and `x=250000`, the former p39 route returned

```text
0.001595767924779338318412354489319103
```

while a 1024-bit MPFR calculation gives

```text
0.00159576792477933831841235448931915561148662356043639156...
```

The p51 route gives the correctly rounded displayed value ending in `...9156`.
For arguments no greater than `1e6`, subtraction of log-combinations loses at
most six decimal places. The p51 log-Gamma dependency supplies at least 45
useful places on this positive-integer range. Up to one million positive terms
can contribute to a tail, so the standard summation bound is below `5.1e-45`.
P51 is the narrowest established context for this range.

For larger arguments, a log-combination is associated as

```text
log C(y,k) = -log(y+1) - log Beta(k+1,y-k+1).
```

The audited positive log-Beta formula retains roughly 58 significant places
at p75. The direct combination is used below `N=1e12`; even a balanced result
then has at least 46 useful absolute log places. If any contingency-table cell
is below 1000, this association also avoids subtracting two nearly equal
large log-Gamma values.

Balanced larger cases use the four cells

```text
a=x, b=K-x, c=n-x, d=N-K-n+x
```

and their independence values `e_i`. With `delta=a-e_a`, the log mass is

```text
-D + 1/2 log(K(N-K)n(N-n)/(2 pi N a b c d)) + R,
D = sum e_i ((1+t_i) log(1+t_i)-t_i),
t_i = (+delta,-delta,-delta,+delta)/e_i.
```

Every contribution to `D` is nonnegative. For small `t`, the calculation uses

```text
(1+t) log(1+t)-t = t^2/2-t^3/6+t^4/12-...
```

so the linear term is absent before decimal evaluation. `R` combines the nine
Stirling corrections. Terms through `43867/(244188 z^17)` are included. At
the cell threshold `z=1000`, the first omitted magnitude is less than
`1.4e-57`; it decreases as `z^-19`. The deviance, half-logarithm, and correction
terms contain no factorial-scale cancellation.

For the symmetric `N=1e40` case, a 1024-bit limiting calculation gives

```text
Pr(X=N/4) = 1.5957691216057307117597842397375274739...e-20.
```

The former p39 formula returned one. A deliberate all-p39 mutation made ten of
the retained large-population cases fail, including this mass and both central
probabilities.

## Lower and inclusive upper probabilities

The probability ratios are

```text
p(k-1)/p(k) = k (N-K-n+k) / ((K-k+1)(n-k+1)),
p(k+1)/p(k) = (K-k)(n-k) / ((k+1)(N-K-n+k+1)).
```

The lower probability is summed downward when its threshold is below the
mode. Above the mode, the upper probability beginning at the next integer is
summed upward and subtracted from one. The inclusive upper function uses the
mirror choice. Every direct sum therefore contains nonnegative, decreasing
terms, and neither small tail comes from subtraction. Hypergeometric
log-concavity makes the ratio decrease away from the mode. Once a term no
longer changes the p51 or p75 sum, the geometric remainder is bounded by the
working unit times the effective distribution width. P51 covers the complete
`N<=1e6` range; p75 covers a standard deviation below `1e37` with more than
three decimal guard places.

At a symmetric integral centre,

```text
Pr(X<=mean) = Pr(X>=mean) = (1+Pr(X=mean))/2.
```

This identity avoids a long central sum and preserves the positive side of one
half. At `N=1e6`, `n=K=5e5`, the revised central result is
`0.5007978839623896691592061772446596`, obtained in a fraction of a second
rather than about twenty seconds.

When the standard deviation reaches `1e37`, only the asymptotic central region
can remain distinct after Real34 input spacing and p75 recurrence spacing are
both considered. The selected normal limit has first correction of order
`1/sigma`, below `1e-37`; representable points outside that region have a tail
below the Real34 range. Exact symmetry is evaluated before this limit. Explicit
interior markers preserve positive underflow, values below one, and the side
of one half through every result mode.

## Inverse

The inverse is the least support integer whose lower probability is at least
`p`. The revised solver first classifies the lower endpoint, starts its upper
endpoint at `ceil(nK/N)`, and expands toward the upper support endpoint when
needed. Integer bisection then preserves

```text
CDF(low) < p <= CDF(high).
```

P75 evaluates each classification. P39 stores the bracket. Unit width gives
the exact integer while p39 still represents adjacent integers. At larger
magnitudes, a relative width below `1e-37` gives three decimal guard places for
the Real34 conversion. Two hundred midpoint reductions exceed the 124 needed
for that relative-width target. A symmetric `p=.5` value uses the exact centre
identity and returns `ceil(nK/N)`.

For `N=1e6`, `n=400000`, and `K=300000`, independently classified quantiles
at `.1`, `.5`, and `.9` are 119712, 120000, and 120288. The file-driven cases
assert all three integers.

## Domains, endpoints, and matrices

The three distribution parameters must be finite nonnegative integers with
`K<=N` and `n<=N`. `N=K=n=0` is the degenerate distribution at zero. NaN
variates and probabilities produce the argument-domain result. Infinite
variates produce mass zero and the appropriate exact probability endpoint.
The exported inverse kernel defines `p=0` and `p=1` as the lower and upper
support endpoints.

Real and complex matrices are rejected by `getRegisterAsReal`; no matrix
calculation invokes a hypergeometric kernel. File-driven cases assert this
interface behaviour for all four public functions.

## Regression evidence

The retained cases in `hypergeometric_p.txt`, `hypergeometric_l.txt`,
`hypergeometric_r.txt`, and `hypergeometric_i.txt` cover shifted support,
parameter reflections, p51 and p75 mass routes, the saddle formula, central
symmetry, exact inverse classification, every result mode at one half,
underflow directions, infinities, NaNs, degenerate populations, and matrix
rejection. Independent references use exact rational arithmetic for the
shifted-support cases and 1024-bit MPFR log-Gamma and recurrence calculations
for the million-element and asymptotic mass cases.

The focused hypergeometric run completed all 114 cases successfully. The clean
full test run on integration base `6923726` completed all 16533 cases
successfully.

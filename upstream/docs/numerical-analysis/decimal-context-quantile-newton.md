# Decimal context analysis for the shared quantile solver

## Result

`WP34S_Qf_Newton` retains its caller-selected context.  The continuous F
inverse and the Poisson, binomial, and negative-binomial inverse entries call
it at p39.  Hypergeometric inversion continues to call it at p75 because its
CDF has a separate wide-intermediate requirement.

P39 is the narrowest established context for the continuous F inverse.  A
deliberate p34 substitution fails 14 of the 22 focused checks, including basic
central probabilities.  P51 and p75 have no demonstrated benefit for the F
solver once its p39 CDF and density dependencies are used.

The audit also corrects the finite-bracket fallback.  It formerly evaluated

```text
2 * (low + high)
```

instead of

```text
(low + high) / 2.
```

The earlier expression is greater than `high` for every positive finite
bracket.  It therefore cannot be a bisection point and can prevent convergence
after a Newton step leaves the bracket.

## Bracket error

Let the exact quantile `q` lie in the current finite bracket `[l,h]`, with
`0 <= l <= q <= h`.  The revised calculation is

```text
m = fl_p(fl_p(l+h) * 0.5).
```

There is no cancellation in `l+h`.  With p39 half-even unit roundoff
`u=5E-39`, the two-operation relative error is bounded by

```text
|m-(l+h)/2| / ((l+h)/2) <= 2u+u^2 < 1.01E-38
```

when the midpoint is nonzero and no range limit is met.  The p39 exponent
range contains sums for all finite Real34 F-quantile results.  Apart from an
endpoint coincidence caused by final working rounding, the revised value is
inside the bracket and reduces its width by approximately one half.

The solver accepts a finite bracket when

```text
|h-l|/|l| < 1E-37.
```

Any exact root inside that bracket is therefore within about `1E-37`
relative error of the returned midpoint, plus the midpoint error above.  This
is more than three decimal guard digits below the Real34 result scale.  The
Newton estimate has the same `1E-37` relative-change threshold.  As with any
inverse CDF, a small estimate change is not an unconditional forward-error
proof in an arbitrarily ill-conditioned tail; the CDF, density, and target
conditioning remain part of the function error.

For discrete distributions the estimate is reduced to an integer and
`WP34S_qf_discrete_final` checks the adjacent CDF values. The CDF stays at its
selected p51 or p75 width for comparison with the Real34 target. Its integer
output does not require 34 fractional digits, but p39 remains the shared search
context used by the binomial and negative-binomial callers.

## Why p34 is unsuitable

The fixed convergence tolerance `1E-37` is far below p34 unit roundoff
`5E-34`.  Distinct p34 Newton estimates normally cannot approach one another
at that scale, and rounded CDF or density evaluations have no guard digits for
a 34-digit continuous result.  With the midpoint correction present, changing
only `fnF_I` from p39 to p34 makes 14 of 22 focused checks fail, usually by
exhausting the 100 iterations and reporting that no root was found.

At p39 the tolerance is 20 unit roundoffs and the public result conversion
still has five work digits available.  Wider contexts do not improve the
final format unless a distribution-specific CDF needs them, as the
hypergeometric implementation does.

## Reproducible failure

For an F distribution with one degree of freedom in both parameters,

```text
F(x) = (2/pi) atan(sqrt(x)),
F^-1(p) = tan(pi*p/2)^2.
```

At `p=1E-20`, independent high-precision evaluation gives

```text
F^-1(p) =
2.4674011002723396547086227499690377838288307230228393...E-40.
```

The p39 search obtains the adjacent bracket

```text
low  = 2.46740110027233965470862274996903778314E-40,
high = 2.46740110027233965470862274996903778363E-40.
```

The former expression sends the estimate far above `high` each time this
fallback is selected and ends with `ERROR_NO_ROOT_FOUND`.  The corrected
midpoint converges to the Real34 result

```text
2.467401100272339654708622749969038E-40.
```

The regression is in the existing file-driven `f_i.txt` suite.  It subtracts
the exact 34-digit expectation and scales the residual, so the ordinary
30-digit comparison tolerance cannot mask a last-place error.  The former
source succeeds in 20 of 22 focused checks; the revised source succeeds in
all 22.  The combined inverse-distribution focus succeeds in all 113 checks.
A clean `make test` run succeeds in all 15,276 repository checks with no GMP
allocation left.

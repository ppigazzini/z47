# Decimal context analysis for the GEV distribution

## Result

The four generalised extreme-value entry functions retain `ctxtReal39`:

| Entry | Calculation | Selected context |
| --- | --- | ---: |
| `fnGEVP` | density | 39 |
| `fnGEVL` | lower cumulative probability | 39 |
| `fnGEVR` | upper cumulative probability | 39 |
| `fnGEVI` | inverse lower cumulative probability | 39 |

P39 is the narrowest established project context for these composite
calculations.  A deliberate p34 substitution fails full-Real34 density checks
in every rounding setting.  P51 and p75 do not provide a demonstrated output
benefit for finite, well-conditioned cases.

The audit also corrects four formula and domain defects: the density exponent,
the finite-support boundary, the rejection of all negative observations, and
the inverse-probability predicate.  Values outside a finite support now receive
the mathematical limiting density and tail probabilities.

## Formulae

For location `mu`, positive scale `sigma`, shape `xi`, and

```text
z = (x-mu)/sigma,
```

define

```text
t = exp(-log1p(xi*z)/xi),  xi != 0,
t = exp(-z),               xi == 0.
```

The density and two tails are

```text
f(x) = t^(xi+1) exp(-t) / sigma,
F(x) = exp(-t),
S(x) = -expm1(-t).
```

The former density used `t^(t+1)`.  At `mu=0`, `sigma=1`, `xi=0.1`, and
`x=1`, independent high-precision evaluation gives

```text
t    = 0.3855432894295317473644036444788584120...
f(x) = 0.2383642609200294496036659953523691359...
```

The earlier value was

```text
0.1815712591647148349898921639598652,
```

which results from the incorrect exponent.  The implementation now forms
`xi+1` and evaluates the specified power.

At a lower endpoint with `xi>0`, `t` is positive infinity and the density
limit is zero.  At an upper endpoint with `xi<0`, `t` is zero.  The special
case `xi=-1` has exponent zero and density `1/sigma`; this is resolved as a
limit instead of sending `0^0` to the generic power operation.

## Support

For nonzero `xi`, the support condition is

```text
1 + xi*(x-mu)/sigma >= 0.
```

Its finite boundary is therefore

```text
mu - sigma/xi,
```

not `(mu-sigma)/xi`.  The selected code divides before subtracting.  It
classifies a value as below, inside, or above the support.  The public results
outside support are

| Position | Density | Lower tail | Upper tail |
| --- | ---: | ---: | ---: |
| below a lower endpoint (`xi>0`) | 0 | 0 | 1 |
| above an upper endpoint (`xi<0`) | 0 | 1 | 0 |

When `xi=0`, the Gumbel distribution has the full real line.  Removing the
unconditional `x<0` rejection restores negative observations for this case and
for every shifted finite support that includes them.

The support division can span the full exponent difference of two Real34
parameters.  P39 has exponent limits of plus or minus 999999 and contains this
calculation.  P34 can overflow `sigma/xi` before the comparison when the two
parameters occupy opposite decimal128 exponent limits.

## Inverse domain and endpoints

For `0<p<1`, the inverse is

```text
x = mu + sigma*((-ln(p))^(-xi)-1)/xi,  xi != 0,
x = mu - sigma*ln(-ln(p)),             xi == 0.
```

The earlier predicate used `p>0 || p<1`, which accepts every finite value.
The corrected predicate uses `p>0 && p<1`.  Two finite endpoints are also
defined:

```text
p=0, xi>0: x = mu-sigma/xi,
p=1, xi<0: x = mu-sigma/xi.
```

They now take the direct boundary calculation.  This avoids a signed-zero
power at `p=1`.  The Gumbel endpoints and the opposite infinite endpoints for
nonzero shape remain outside this calculator entry's finite-result domain.

## Error scale

At p39, half-even unit roundoff is `u=5E-39`.  The elementary operations in
`z` and `xi*z` contribute a small multiple of `u` when the corresponding exact
quantities are nonzero.  Writing `a=xi*z`, the sensitivity of
`log1p(a)/a` tends to one as `a` tends to zero, so the chosen `log1p` form does
not lose accuracy as the GEV family approaches the Gumbel case.  Sensitivity
does grow near `a=-1`, which is the distribution's finite-support endpoint.

The calculation uses the audited p39 `ln`, `ln1p`, `exp`, and `expm1` helpers.
Their conservative working errors are below the p34 result scale with multiple
guard digits.  The nonintegral `PowerReal` dependency in the density retains
p39 and is tracked by its separate general-power audit.  Correctly rounded
addition, subtraction, multiplication, division, fused multiply-add, and
square root are assumed as specified for this project.

No fixed precision can provide a uniform relative result guarantee in an
arbitrarily remote tail: exponentiation can magnify a small error in `t`, and
an inverse distribution is inherently ill-conditioned at an open probability
endpoint.  The context claim is therefore faithful 34-digit working accuracy
for finite, well-conditioned results, excluding the accepted p39-to-p34
boundary discrepancy.  Exact support limits are resolved without a tail
calculation.

P34 is demonstrably too narrow.  For the density example above, the exact
34-digit results under modes 0 through 6 end in `3691` or `3692` according to
the requested direction.  Replacing every p39 GEV operation by p34 makes all
seven scaled-residual checks nonzero, with errors from one through 23 Real34
units.  Restoring p39 makes all seven residuals zero.  The wider p51 and p75
contexts add cost without a corresponding need in this kernel.

## Verification

All durable cases use the existing file-driven suite.  `dist_cov.txt` now
includes:

- the corrected density and all seven output rounding settings;
- negative Gumbel observations;
- both finite-support directions and values outside support;
- both finite inverse endpoints;
- the `xi=-1` endpoint density.

`disterr_cov.txt` adds probabilities below zero, above one, and a forbidden
Gumbel endpoint.  With the initial new correctness cases, the former source
succeeds in 35 of 55 checks.  The corrected p39 source succeeds in all 76
final focused checks.  The deliberate p34 build succeeds in 69 of 76, with
exactly the seven full-digit density checks failing.  A clean `make test`
run succeeds in all 15,273 repository checks with no GMP allocation left.

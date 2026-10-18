# Exponential distribution decimal contexts

## Scope and result

This audit covers the exponential density, lower probability, upper
probability, inverse, and calculator entries in
`src/c47/distributions/exponential.c`. The rate parameterisation is

```text
f(x) = lambda exp(-lambda*x),  x>=0.
```

The public result type is Real34. Differences caused only by conversion from
p39 to Real34 are outside this audit.

| Calculation | Selected context | Reason |
| --- | ---: | --- |
| density | 39 | the scaled argument and logarithmic density need five guard digits |
| lower probability | 39 | `expm1` prevents endpoint cancellation; p34 changes retained Real34 digits |
| upper probability | 39 | the exponential magnifies absolute error in a large scaled argument |
| inverse | 39 | the compensated logarithm and division need guard digits |
| exact support values | caller p39 | zero, one, the rate, and infinities need no wider work |
| final result | caller context, then Real34 | calculator rounding is applied after the complete result is available |

The revised calculations target faithful 34-digit results. They do not claim
universal correct rounding. P51 and p75 provide no useful accuracy gain for
these conditioned formulae.

## Scaled argument and tail conditioning

For finite `x>0` and finite `lambda>0`, write

```text
z = lambda*x,
R(x) = exp(-z),
L(x) = -expm1(-z).
```

The lower probability uses `expm1`, so it does not subtract an upper
probability close to one. Its relative condition factor with respect to `z`
is

```text
z exp(-z) / (1-exp(-z)) <= 1.
```

The upper probability has relative condition factor `z`. If an upper result
can affect a Real34 digit, its exponent is inside the Real34 range and

```text
z < log(10^6177) < 14223.
```

A p39 multiplication at this magnitude has absolute rounding error below
about `8e-36`. The correctly rounded p39 exponential adds a relative error
below half a p39 unit. Five guard digits therefore cover the amplification by
`z`. At p34 the product error can reach about `8e-31`, leaving only about 29
accurate digits in the smallest relevant tails.

The retained upper discriminator is

```text
lambda = 1.234567890123456789012345678901234
x      = 8000.123456789012345678901234567890

R(x) = 4.033006668079199684250167181730929e-4290...
```

A p34 substitution leaves a scaled residual with magnitude `1.959e30` after
multiplication by `1e4350`. P39 gives a zero residual at Real34.

For the lower route,

```text
lambda = 1.234567890123456789012345678901234
x      = 0.08100012345678901234567890123456789

L(x) = 0.09516271906118402305453796315899107...
```

P34 leaves a scaled residual with magnitude `3e5`; p39 gives the retained
Real34 value. These cases establish p39 as the narrowest tested context for
both probability routes.

## Density

The direct density formula first evaluates `exp(-z)` and then multiplies by
`lambda`. That ordering can discard a result which the multiplication would
move back into the representable range. For example,

```text
lambda = 1e6144
x      = 2e-6140
z      = 20000
```

Here `exp(-z)` is outside the working exponent range, but the density is

```text
f(x) = 1.289323608390093748351631080902723e-2542...
```

The former calculation returned zero. The revised calculation uses two
conditioned regions:

```text
z <= 10000: f(x) = lambda * exp(-z)
z >  10000: log(f(x)) = log(lambda) - z;  f(x) = exp(log(f(x))).
```

At the selected boundary, `exp(-z)` is above `1e-4343`, far from the p39
subnormal region, and retains all 39 digits. The first form avoids a logarithm
and exponential round trip for ordinary arguments and for a scaled argument
too small to alter one. The second form prevents premature underflow.

For a finite density that can affect Real34, both `log(lambda)` and
`log(f(x))` have magnitude below about 14223. Hence `z` is below about 28446
on the logarithmic route. P39 gives absolute errors of order `1e-35` in the
product and subtraction, which become relative errors of the same order in
the final exponential. P34 gives errors of order `1e-30` near cancellation
and near the lower exponent boundary.

In the underflow-recovery case above, p34 returns

```text
1.289323608390093748351631080910857e-2542,
```

which has only 29 correct digits. A second density discriminator,

```text
lambda = 1.234567890123456789012345678901234
x      = 8000.123456789012345678901234567890

f(x) = 4.979020533064369960379832125734781e-4290...,
```

leaves a p34 scaled residual with magnitude `2.419e30`. P39 gives the retained
Real34 result. P51 is unnecessary because the p39 bounds already leave guard
digits after the largest possible argument amplification.

At `x=0`, the density is exactly `lambda`; the separate endpoint avoids the
former zero result. Negative and infinite arguments have density zero.

## Inverse

For `0<u<1`, the inverse is

```text
Q(u) = -log1p(-u) / lambda.
```

The compensated logarithm preserves small `u`. For a Real34 probability below
one, `1-u` is at least one Real34 unit at one, so

```text
-log(1-u) <= 34 log(10) < 79.
```

The logarithm and division are well-conditioned. Their two p39 roundings
leave five guard digits. P34 has no guard digit across the composition. The
retained discriminator is

```text
u      = 0.2017855955094534401652622449896090
lambda = 7.875276942602781230065233775e37

Q(u) = 2.861842725732451681861284926102739e-39...
```

A p34 substitution leaves a scaled residual with magnitude `2e8` after
multiplication by `1e80`. P39 gives the retained Real34 result and is the
narrowest established inverse context.

The exported kernel defines `u=0` as zero and `u=1` as positive infinity.
The calculator entry retains the established strict `0<u<1` domain so that a
special result is not introduced when special-result mode is clear.

## Directed rounding and exponent endpoints

For finite positive `x` and `lambda`, both tail probabilities are strictly
between zero and one. The density and every interior inverse are strictly
positive. A p39 exponential or division can nevertheless round one of these
values to zero or one at its own exponent or precision boundary.

The revised kernels move such an endpoint by one p39 unit toward the interior
before Real34 conversion. The p39 minimum is below the Real34 minimum because
the two formats use the same adjusted exponent range with five different
precision digits. Under nearest conversion that marker can still become the
exact Real34 endpoint. Under upward or toward-positive conversion, a positive
underflow becomes `1e-6176`; under downward or toward-negative conversion, a
finite probability below one becomes the Real34 predecessor of one.

Exact values at `x<=0`, `x=+infinity`, and inverse kernel endpoints are not
adjusted. The density also marks an exponential factor which rounds to one
when `x>0`; this preserves the strict side of `lambda` under downward
conversion.

## Domains, special values, and matrices

The rate must be finite and positive. Zero, negative, infinite, and NaN rates
are distribution-parameter errors. NaN arguments are argument-domain errors.
With special-result mode set, either condition returns NaN without a retained
diagnostic code.

The three forward functions extend across the whole real line by their
distribution values:

| Argument | density | lower | upper |
| --- | ---: | ---: | ---: |
| `x<0`, including negative infinity | 0 | 0 | 1 |
| `x=0` | `lambda` | 0 | 1 |
| positive infinity | 0 | 1 | 0 |

Real and complex matrices are rejected by `getRegisterAsReal`; no elementwise
exponential-distribution operation is defined. File-driven cases assert this
interface behaviour for all four public functions.

## Regression evidence

Independent decimal calculations use 180 to 220 digits for the retained
numeric values. With the first domain, endpoint, extreme-range, directed, and
matrix additions, the former source completed 182 of 211 checks and failed
29. The revised source completes all 221 checks. A deliberate p34 substitution
fails five checks: two density checks and one check in each other route.

The clean complete file-driven suite completes all 16,873 checks.

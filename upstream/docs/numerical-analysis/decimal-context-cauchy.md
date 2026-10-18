# Cauchy-distribution decimal contexts

## Scope and result

This audit covers the Cauchy density, lower probability, upper probability, and
inverse functions in `src/c47/distributions/cauchy.c`. The public result type is
Real34. Real and complex matrices have no elementwise distribution route and
produce the established type error.

The revised routines target faithful 34-digit results. They do not claim
universal correct rounding for the transcendental approximations. Differences
caused only by conversion from p39 to Real34 are outside this audit.

| Calculation | Selected context | Reason |
| --- | ---: | --- |
| density | 39 | a scaled positive formula avoids overflow and cancellation |
| lower and upper probabilities | 39 | the smaller side is evaluated directly with the audited arctangent |
| ordinary inverse | 51 | reduced sine and cosine give more than four decimal guard digits |
| inverse after 9 to 34 lost places | 75 | the location-scale sum has a wider cancellation margin |
| inverse after more than 34 lost places | 159 | a local series and fused closing sum protect deep cancellation |
| final public result | Real34 | calculator rounding follows the complete scalar calculation |

## Density

With `d=abs(x-x0)`, the mathematical density is

```text
gamma / (pi*(d^2+gamma^2)).
```

The former implementation squared `d/gamma`. This can overflow even though the
density is finite, after which it incorrectly produces zero. The revised route
selects one of two equivalent forms:

```text
d <= gamma: r=d/gamma, f=1/(pi*gamma*(1+r^2));
d >  gamma: r=gamma/d, f=r/(pi*d*(1+r^2)).
```

Every product added to one is nonnegative and each ratio is at most one. The
second form never squares the large distance. Subtraction of nearby Real34
operands is exact at p39 by Sterbenz's lemma; when the operands are not nearby,
the subtraction has ordinary relative conditioning.

Using directed-rounding unit `u39=1e-38`, fewer than seven rounded operations,
plus the p39 pi error, give a conservative relative error below `1e-37` for a
finite nonzero result. P34 has no work-digit margin, while p51 does not improve
the final Real34 value enough to justify its cost. P39 is therefore the
narrowest established context for density.

## Direct probabilities

For `z=(x-x0)/gamma`, symmetry gives the smaller probability without subtracting
it from one:

```text
abs(z) <= 1: small = 1/2 - atan(abs(z))/pi;
abs(z) >  1: small = atan(1/abs(z))/pi.
```

The sign of `z` and the requested tail select either `small` or `1-small`.
This retains probabilities such as `3.1830988618379067e-101`, for which the
former expression `1/2-atan(z)/pi` rounded to zero.

The p39 arctangent audit gives an absolute error below `3e-37` radians outside
the cell centred on zero, a relative error below `2.1e-37` inside that cell,
and a conservative relative error below `7e-36` globally. Division by pi and
the fixed arithmetic raise the conservative small-tail relative bound to less
than `8e-36`. For `abs(z)<=1`, the smaller result is at least one quarter, so
the absolute arctangent bound gives the same 34-digit margin. P39 is the
narrowest context supported by that dependency and also supplies the wide work
exponent range needed by extreme Real34 ratios.

When a finite probability is too close to one or one half to survive p39
addition, one p39 neighbour records the strict mathematical side. Half-even
conversion still rounds that marker to the nearest Real34 value. A directed
conversion can consequently select the correct adjacent Real34 value. Exact
infinite endpoints do not receive a marker.

## Inverse and endpoint reduction

The direct inverse identity is

```text
q(p) = x0 + gamma*tan(pi*(p-1/2)).
```

Subtracting one half destroys the relative accuracy of `p` near zero or one.
The revised route uses

```text
p < 1/4:  tangent = -cot(pi*p);
p > 3/4:  tangent =  cot(pi*(1-p));
otherwise tangent = tan(pi*(p-1/2)).
```

Every trigonometric angle is no greater than `pi/4` in magnitude. On that
interval, the relative condition factor for tangent or cotangent is

```text
2*abs(theta)/abs(sin(2*theta)) <= pi/2.
```

Thus the endpoint transformation does not amplify the angle error by more
than a small constant. In particular, `p=1e-34` now gives a finite magnitude
whose first 34 digits agree with an independent 512-bit MPFR calculation.

The reduced sine/cosine series has relative error below `1.6e-46` at
p51, including its conservative 1,000-iteration arithmetic bound. Angle
multiplication, division, scaling, and fused addition raise this to less than
`2e-46` before cancellation. If the adjusted exponents of `x0`,
`gamma*tangent`, and their fused sum indicate no more than eight lost places,
the relative error is below `2e-38`. This leaves over four decimal guard digits
before Real34 conversion. P39 cannot support cancellation near an endpoint or
quartile, so p51 is the narrowest ordinary inverse context.

For nine through 34 lost places, the calculation is repeated at p75. Scaling
the sine/cosine analysis to directed p75 arithmetic gives a bound below
`2e-70` before cancellation and below `2e-36` at the selection boundary. Exact
quartiles use `x0-gamma` and `x0+gamma` directly.

## Deep location-scale cancellation

No single ordinary width can absorb every severe cancellation in
`x0+gamma*tangent`. The following Real34 values use
`tan(-3*pi/8)=-(1+sqrt(2))` and a Pell convergent to consume about 68 decimal
places:

```text
p     = 0.125
x0    = 9960168529794442859224531878561050
gamma = 4125636888562548868221559797461449
q     = -8.569668154107923784618454305869848905...e-35.
```

P75 supplies only six correct digits in this result. The conditional p159 route
recomputes sine and cosine from their alternating Taylor series, uses the
1,071-digit pi constant, and evaluates the closing expression with one fused
operation. On `abs(theta)<=pi/4`, both series have decreasing terms and bounded
cancellation. Even the implementation limit of 1,000 iterations uses fewer
than 6,100 rounded elementary operations, giving an arithmetic bound below
`6.2e-155` under directed p159 arithmetic. The exhibited 68-place cancellation
therefore leaves over eighty decimal places. All seven result modes agree with
the independently evaluated value through their selected Real34 endpoint.

P159 is an established project cancellation context and is entered only when
the p75 fused result loses more than 34 places. This establishes a wide margin
for the exhibited Real34 adversary without imposing that cost on ordinary
inverse calls. As with the other transcendental routes, this is a faithful
accuracy argument rather than a proof of universal correct rounding for every
possible input triple.

## Domains, special values, and dispatch

Location and scale must be finite, and scale must be positive. A NaN variate
propagates through the public kernels. Density at either variate infinity is
zero. The lower probabilities at negative and positive infinity are zero and
one respectively; the upper probabilities use the opposite endpoints. The
inverse kernel has mathematical limits of negative and positive infinity at
probabilities zero and one, while the calculator command retains its strict
open probability domain. NaN probability is rejected.

Finite results below the Real34 exponent range remain nonzero at p39, so a
directed final conversion can select the minimum positive subnormal value.
Parameter and inverse-domain errors honour special-result mode without leaving
a stale error code.
The file-driven cases also confirm that real matrices are rejected by the
scalar register conversion.

## Regression evidence

On the integration base, the old upper probability at `x=1e100` was zero and
the old lower probability at positive infinity was positive infinity. The old
inverse at `p=1e-34` was
`-3183105758373358720372181807416020`, versus the independent value beginning
`-3183098861837906715377675267450287`. Near the lower quartile, only five
correct digits remained after location-scale cancellation.

With the adaptive code, a deliberate p51-only mutation succeeded in 123 of 131
focused checks. Its eight failures were the seven output modes of the
quartile-adjacent cancellation and the corresponding extreme-scale value; only
18 digits remained. Disabling the p159 selection produced the Pell-case value
`-8.569671410457091667843618720558205e-35`, with only six correct digits. The
selected implementation succeeds in all 131 focused checks. The cases reside
in the four existing Cauchy file-driven test files; no extra executable test is
required. A clean repository run succeeds in all 16,766 checks with no failure.

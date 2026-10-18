# Decimal context analysis for exponential minus one

## Scope and result

This analysis covers `WP34S_ExpM1`, `realExpM1`, the public scalar and complex
`ExpM1` routes, and elementwise real and complex matrix evaluation. Calls from
distributions, hyperbolic functions, Lambert W, zeta, and the time-value-of-money
solver are identified below. Accuracy of each enclosing formula remains a
property of that formula.

| Calculation | Selected context | Reason |
| --- | ---: | --- |
| public scalar `expm1(x)` | 39 | the small-argument formula and direct subtraction retain at least two conservative guard digits |
| complex with finite `Re(z) <= -0.1` | 39 | direct `exp(z)-1` has condition factor below 10.51 and avoids unstable split factors |
| complex with infinite real component | 39 | the direct formula gives the correct infinite or signed-zero direction |
| remaining finite complex inputs | 75 | a decimal128 pair can cancel 35 component digits; a p51 substitution fails the exact regression |
| real and complex matrices | same as scalar elements | matrix dispatch invokes the scalar entry for each element |

The established contexts of 34, 39, 51, and 75 digits were considered. P39 is
the narrowest supported choice for a decimal128 scalar result. The complex route
now selects p39 for its well-conditioned direct region and retains p75 only for
the cancellation-capable split identity.

The p39 and p75 work contexts use round-to-nearest, ties-to-even. Conversion to
decimal128 applies the selected user mode. Differences caused solely by the
accepted p39-to-p34 boundary effect are outside this context choice.

## Scalar helper

Write `p` for the supplied context digits and

```text
u = RN_p(exp(x)),
v = RN_p(u-1).
```

The completed exponential audit uses the conservative library bound

```text
|u/exp(x)-1| <= 10^(1-p).
```

For `|x| >= 0.1`, the helper returns `v`. The sensitivity of the subtraction to
the exponential value is

```text
kappa = exp(x)/|exp(x)-1|.
```

It is at most `10.5084` for `x >= 0.1` and at most `9.5084` for `x <= -0.1`.
Including one correctly rounded subtraction gives a p39 relative error below
`1.11e-37`, apart from a final rounding boundary. This is more than three
decimal orders below a normal decimal128 unit.

For `|x| < 0.1`, `u` lies between approximately 0.9048 and 1.1052. Sterbenz's
lemma makes `u-1` exact in the p-digit format. The helper computes

```text
x * (u-1) / log(u).
```

Set `t=log(u)` and `phi(t)=expm1(t)/t`. Ignoring rounded arithmetic for the
moment, the expression is `x*phi(t)`, while the target is `x*phi(x)`. On this
interval,

```text
|d(log(phi(t)))/dt|
  = |exp(t)/(exp(t)-1) - 1/t|
  < 0.51.
```

Consequently the error in `u` is not divided by the small input. Its contribution
to the relative result error is below approximately `5.2e-39` at p39. The two
closing rounded operations add less than `1e-38`. The audited p39 `WP34S_Ln`
bound is below `9.1e-37`, which dominates the conservative total and still
leaves over two decimal guard digits for a 34-digit result.

If `v` is zero, p39 rounding implies that `expm1(x)/x` differs from one by less
than approximately `2.6e-39`; copying `x` is accurate. If `v` is negative one,
the omitted positive exponential is below the p39 subtraction unit. Copying
negative one has the same p39 error scale.

P34 is insufficient. It has no guard margin for the exponential library error,
and the logarithm arithmetic bound is already much larger than one result unit.
It also imposes the decimal128 exponent limits during the exponential. With a
deliberate p34 substitution,

```text
x = 14149.38539644841072829055748903542
```

reports overflow in mode 4 instead of returning the largest finite decimal128
number. The p39 intermediate retains the finite value until output conversion.

## Complex formulas

For `z=a+ib`, direct evaluation is

```text
expm1(z) = exp(a) cos(b) - 1 + i exp(a) sin(b).
```

The real subtraction can lose all useful digits when the result is close to
zero. The original implementation therefore used

```text
expm1(z) = -2 i exp(z/2) sin(i z/2).
```

This identity is retained for finite `a > -0.1`. Near zero and near the zeros
`2*pi*i*k`, the small sine factor is formed directly instead of subtracting one
from a rounded complex exponential. The p75 trigonometric request uses the
audited wide phase reduction and a p75 reduced-angle series. Hyperbolic sine for
a small argument uses `WP34S_ExpM1` at the same p75 context. The compensated
complex multiplication audit applies to the closing product; approximation
errors in the exponential, trigonometric, and hyperbolic factors remain part of
this formula's p75 allowance.

For `a <= -0.1`, direct subtraction is well-conditioned because

```text
|exp(a) cos(b) - 1| >= 1-exp(-0.1).
```

The condition factor is below 10.51, so p39 is sufficient. This region formerly
used one factor tending to zero and another tending to infinity as `a` became
large and negative. At `z=-5e6-i`, the product was zero times infinity and both
components became NaN. Direct evaluation gives `-1-i0`, as required. It also
gives `-1` with the appropriate signed imaginary zero for negative-infinite real
input. Positive-infinite real input produces component signs from cosine and
sine instead of two NaNs.

## Why the remaining complex region needs p75

Component accuracy has unbounded relative condition at a zero. Decimal128
inputs can also place one component close enough to zero that p51 cannot retain
34 result digits. An independent 220-digit decimal calculation gives

```text
-log(cos(0.7))
  = 0.2680857575679311005294132926142306950043618152630...
```

Using its nearest decimal128 value as the real component,

```text
z = 0.2680857575679311005294132926142307 + 0.7 i,

Re(expm1(z))
  = 4.99563818473698187097551845614511995774637579872...e-36.
```

The order-one terms have cancelled through 35 decimal places. A deliberate p51
complex context changes the result by `3.776286414009491620e-51`, leaving only
about 15 accurate relative digits in this component. P75 succeeds through digit
34 in all seven output modes and is the narrowest established context that does
so.

The conditioning is unbounded on the exact component-zero curves, so no fixed
precision can prove 34 relative digits for every nonzero component without an
exact symbolic zero test. P75 gives roughly 40 work digits beyond order-one
terms and is the narrowest defensible established width for decimal128 inputs.
Absolute error, final underflow, and exact zeros remain the meaningful criteria
arbitrarily close to a component zero.

## Matrices and shared callers

`processRealComplexMonadicFunction` sends a real matrix through `elementwiseRema`
and a complex matrix through `elementwiseCxma`. Every element therefore uses the
same p39 scalar route or the same conditional p39/p75 complex route. There is no
additional matrix arithmetic in `ExpM1`; the existing real and complex matrix
cases exercise this dispatch.

`realExpM1` is used at p39 by the GEV and Pareto distribution code. Direct
`WP34S_ExpM1` callers include the exponential, geometric, hypergeometric, and
Weibull distributions; small-argument hyperbolic sine; hyperbolic tangent;
Lambert W; real and complex zeta; and the time-value-of-money solver. Those
callers supply p39, p42, p51, or p75 according to their enclosing calculation.
The helper must therefore continue to honour its supplied context rather than
force the public p39 choice. Its small-argument sensitivity bound scales with
that supplied precision.

The time-value-of-money module also contains `doubleExp`, which duplicates the
same small-argument formula while returning both `exp(x)` and `expm1(x)`. It was
not merged into the helper because that module needs both outputs and has its own
p39, p42, and p51 context policy.

## Zero, NaN, infinity, and range limits

Scalar positive and negative zero are copied when the rounded exponential is
one, which preserves the zero sign. NaN maps to NaN, positive infinity maps to
positive infinity, and negative infinity maps to negative one. The shared
`realExpLimitCheck` also maps finite inputs outside plus or minus two million to
the corresponding limiting result. That explicit cap is relevant to composite
callers requesting values wider than decimal128.

An exact zero complex imaginary component uses the scalar route and sets a
positive imaginary zero. For nonzero imaginary input, a NaN real component or a
special imaginary component produces two NaNs. Finite imaginary input with an
infinite real component uses the direct formula described above.

## Regression evidence

The focused file has 126 checks. Before the stable negative-real branch was
added, five new checks failed: `-5e6-i`, negative infinity with finite phase,
and both positive-infinity phase signs. The revised formula succeeds in all five.

Reducing the scalar entry from p39 to p34 makes the directed upper-range case
fail with overflow. Reducing the cancellation-capable complex entry from p75 to
p51 makes the scaled 35-digit-cancellation check fail by
`3.776286414009491620e24`; the scale factor is `1e75`. The final tests include
all seven rounding modes for scalar `expm1(1)` and for the complex cancellation
value, the minimum decimal128 subnormal, signed zero, the p34 upper range
transition, the p39 direct-formula boundary, and complex special values.

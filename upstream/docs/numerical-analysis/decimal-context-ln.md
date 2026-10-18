# Decimal context analysis for natural logarithm

## Result

The user-visible real and complex routes use the following working contexts:

| Calculation | Selected context | Reason |
| --- | ---: | --- |
| finite positive scalar and the magnitude away from one | 39 | range reduction and the logarithm series retain a sufficient margin beyond decimal128 |
| complex magnitude and angle | 39 | the magnitude has an existing error bound; the angle remains conditional on the separate `atan2` audit |
| complex real component for `1/2 < |z| < 2` | 75 | decimal128 component squares can cancel through 68 coefficient digits near the unit circle |

The scalar context and the ordinary complex context remain at 39 digits. The complex real component now avoids taking a logarithm of a rounded magnitude near one. It
forms `delta = a^2+b^2-1` from the original rectangular components and evaluates `log1p(delta)/2` at 75 digits. A 51-digit mutation fails the new exact regression.

This revised calculation is confined to the user-visible `lnCplx` entry, whose rectangular components are exact decimal128 inputs. The reusable `lnComplex` helper stays
unchanged because composite callers can supply correlated approximations; exposing cancellation in those inputs can amplify an earlier approximation error. Their
conditioning belongs to the audits of the enclosing functions.

The fixed working contexts use round-to-nearest, ties-to-even. The selected user mode is applied during conversion to decimal128. Differences caused only by rounding a
39-digit half-even intermediate to decimal128 in a directed mode are outside this decision, as required by the audit scope.

## `WP34S_Ln` range reduction

For an input outside `[0.5, 1.5]`, changing the stored exponent writes the value as `z * 10^e` with `0.1 <= z < 1`. This step changes no coefficient digit. Repeated
correctly rounded square roots then put `z` above `1/sqrt(2)`. An unreduced input can be as large as 1.5, so the series variable

```text
a = (z-1)/(z+1)
```

satisfies `|a| <= 0.2` and `q = a^2 <= 0.04`. At most three square roots are required from the lower endpoint 0.1. The factor accumulated with those roots is exact.

The helper evaluates

```text
log(z) = 2 * (a + a^3/3 + a^5/5 + ...).
```

All terms have the same sign. If an included term `e` changes the partial sum by less than `tau = 10^(1-p)` relatively, the omitted terms satisfy

```text
|tail/e| <= q/(1-q) <= 1/24,
|tail/log(z)| < tau/24.
```

For `p=39`, the largest `q` reaches the stopping test at the term with denominator 53. Fewer than 180 rounded elementary operations include range reduction, term
formation and the error checks. With unit roundoff `u = 5e-39`, the corresponding conservative `gamma(180)` bound is below `9.1e-37`. The same-sign summation does not
amplify its term errors. Square-root propagation and the final exponent addition remain within a small multiple of this bound.

Cancellation in `z-1` does not invalidate the estimate for a decimal128 input near one. Such an input is subtracted from one exactly at 39 digits, no square-root or
exponent reduction is then used, and division by `z+1` is well-conditioned. When an exponent contribution is present, an input outside `[0.5,1.5]` keeps the final
logarithm away from zero. The largest cancellation factor between the reduced logarithm and one `log(10)` contribution is below 12 at the interval boundary.

The 39-digit `log(10)` and `1/sqrt(2)` constants match this calculation. The `log(10)` constant limits the effective accuracy of calls requesting more than 39 digits
when exponent decomposition occurs. This does not limit a 34-digit scalar result. It also does not limit the high-precision unit-circle calculation below: when a tiny
`delta` needs more than 39 digits, `1+delta` remains in `[0.5,1.5]` and `WP34S_Ln` does not use the exponent constant.

At 34 digits, `gamma(180)` approaches `9.1e-32`, leaving no 34-digit error margin. Among the established project contexts, 39 digits are therefore the narrowest
supported choice for a scalar decimal128 logarithm. Calls from wider composite algorithms have separate conditioning and are not narrowed by this result.

## Complex real component

For `z=a+ib`,

```text
Re(log(z)) = log(sqrt(a^2+b^2)) = log(a^2+b^2)/2.
```

The former route rounded the magnitude before applying the logarithm. Its absolute magnitude error is harmless away from one but is divided by `|log(|z|)|` in the
relative error of the final real component. The condition number is therefore unbounded on the unit circle.

Within the annulus selected by the 39-digit magnitude, the revised route forms

```text
delta = (d-1)(d+1) + s^2,
```

where `d` is the component with greater absolute value and `s` is the other component. Selecting the greater component matters for points such as `a` tiny and `b=1`:
the product involving `b` is then exactly zero and the small `a^2` term is not lost by subtracting two numbers near one.

For decimal128 inputs in the annulus, `d` is comparable with one. The additions `d-1` and `d+1` are exact at 75 digits, their product requires at most 70 coefficient
digits, and `s^2` requires at most 68. When cancellation is possible the exponents are close, so the fused addition has at least five further digits. When one term is
too small to affect the other at 75 digits, it is also too small to affect the 34-digit logarithm unless the larger product is zero, in which case the fused operation
retains the small square.

A 51-digit context cannot provide this property. For

```text
a = 0.7
b = 0.7141428428542849997999399811367265
```

the exact squared-radius offset is

```text
delta = -3.981577319274742665135691286419775e-35
```

and an independent 220-digit decimal calculation gives

```text
Re(log(a+ib)) = -1.9907886596373713325678456432098875396...e-35.
```

At 51 digits the order-one products lose information before their cancellation is exposed. The exact regression reports an error in digit 18 of the decimal128
answer. The 75-digit context retains the required result and is the narrowest established context supported for every decimal128 point in the annulus.

Outside the annulus, `|log(|z|)| >= log(2)`, apart from a harmless boundary displacement caused by the magnitude rounding. The direct precision-39 magnitude and
logarithm route is well-conditioned there. Either formula is accurate near the selection boundaries, so the magnitude is used only to select the route, not to supply
the sensitive real component.

## Angle and branch cuts

The imaginary component remains the precision-39 `atan2(b,a)` result in the principal interval `(-pi,pi]`. The negative-real cut approaches `+pi` for positive
imaginary input and `-pi` for negative imaginary input. An exactly zero imaginary component, including negative zero, follows the existing `+pi` endpoint convention
when the real component is negative.

This conclusion is conditional on the pending independent `atan2` audit. The complex magnitude calculation already has a precision-39 error analysis and is used only
for the angle and route selection here. The revised real-component calculation uses real multiplication and fused addition; it invokes no complex multiplication or
division, whose audits remain separate.

## Range and special values

A finite decimal128 component has an adjusted exponent from -6176 through 6144. Squaring it stays inside the wide context exponent range of plus or minus 999999. The
normalisation in `WP34S_Ln` changes only the stored exponent, whose magnitude also fits `int32_t`. Tests at `1e-6176` and the largest finite decimal128 value assert digit
34 of the exponent-decomposition result.

Positive and negative zero use the existing scalar domain handling: with special results enabled they produce negative infinity; otherwise they report a domain error.
Positive infinity produces positive infinity when special results are enabled. Negative infinity produces the principal complex result when complex results are
enabled, and NaN under the scalar special-result route. Finite negative scalars use the same positive magnitude calculation with imaginary component `+pi` when complex
results are enabled.

For complex input, a zero pair produces `-infinity+0i` when special results are enabled and otherwise reports a domain error. NaN components produce NaN components.
Infinite components produce an infinite real component and the existing quadrant angle. The new finite annulus branch is not selected for NaN or infinity.

## Regression values

The lost-component case uses

```text
z = -1 + 1.234567890123456789012345678901234e-34 i
Re(log(z)) = 7.6207893766194183752476757812833339615150760567139...e-69.
```

Exact subtraction and scaling assert digit 34 in all seven output rounding modes. The old magnitude-first route returns zero and fails all seven cases. A negative
imaginary component asserts `-3.141592653589793238462643383279503` on the lower side of the cut. Additional exact cases exercise a scalar next to one, the decimal128
exponent limits, and the cancellation example that distinguishes 75 digits from 51.

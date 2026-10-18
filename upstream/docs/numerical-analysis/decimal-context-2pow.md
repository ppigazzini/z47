# Decimal context analysis for `2^x`

## Scope and result

This analysis covers `realPower2`, the scalar and complex Real34 entries in
`src/c47/mathematics/2pow.c`, their shared entry helpers in `10pow.c`, and
elementwise real and complex matrix application. Short and long integer
arithmetic is outside this audit.

| Route | Selected work | Reason |
| --- | ---: | --- |
| scalar fractional exponent | p39 | five guard digits protect the reduced logarithm, exponential, integer factor and closing product |
| scalar integral exponent | p39 integer power | the library uses extra internal digits and p39 protects conversion to Real34 |
| complex magnitude | scalar p39 route | the scalar bound applies to the real component of the exponent |
| complex phase | p75 product and p75 trigonometric request | p51 loses result digits for an ordinary Real34 phase input |
| closing complex products | p39 | neither component contains subtraction |
| real and complex matrices | element contexts above | matrix dispatch applies the scalar entry to each element independently |

P39 is the narrowest established context among 34, 39, 51 and 75 digits for
the scalar route. P75 is the narrowest member of that set established for the
complex phase route. The selected complex width is a material accuracy range
extension, not a guarantee for every possible finite Real34 imaginary input.

Only `ctxtReal34` takes the selected user rounding mode. The wider contexts
use round-to-nearest, ties-to-even; conversion of the work result applies the
selected mode. Differences confined to a p39-to-p34 boundary are excluded as
requested. The errors below occur before that conversion boundary.

## Arithmetic model

For a normal p-digit result, write

```text
u_p = 0.5 * 10^(1-p).
```

The basic arithmetic has relative error at most `u_p`. The audited
`realExp` dependency can err by at most one work-precision unit. Integer
`decNumberPower` increases its accumulator width by the decimal digit count
of the exponent plus two and documents at most one unit of error in the final
requested precision.

## Scalar route

The former calculation was

```text
exp(x ln(2)).
```

Its argument error grows with `abs(x)`. A Real34 result can remain finite for
`abs(x)` slightly above 20,000, so the p39 constant and multiplication can
contribute about `1.4e-34` absolute error to the exponential argument. That
is large enough to change result digit 34.

The revised calculation writes

```text
x = n + f,  n = trunc(x),  abs(f) < 1,
2^x = 2^n exp(f ln(2)).
```

The subtraction that forms `f` is exact at p39 for a Real34 input and an
integer `n`. The p39 constant error and correctly rounded multiplication now
give an absolute argument error below `1e-39`, independent of `n`. The p39
exponential, integer power, and closing multiplication each contribute at
most a small multiple of `1e-38` relative error. Their combined conservative
bound remains below `4e-38`, leaving more than four decimal guard digits for
a Real34 result away from an accepted conversion boundary.

An integral exponent skips the logarithm, exponential, and closing product.
For exponents in the finite Real34 result region, the integer-power dependency
uses at least 46 accumulator digits at the largest magnitude. Exact powers
whose coefficients fit at p39 remain exact. Larger powers receive the same
one-unit p39 library bound before final conversion.

Real34 inputs whose integer part does not fit an `int32_t` use the former
formula. Their magnitude is far beyond both finite Real34 result transitions,
so this route supplies only the established zero, infinity, or NaN result.

### Scalar evidence and p34 exclusion

Independent 150-digit evaluation gives

```text
2^-17705.70203707282800997059791824504
  = 1.12873645621389164555359433872370549638435518197826...e-5330.
```

The direct p39 argument produced a result ending in `706` under the three
nearest modes rather than `705`. The reduced p39 formulation returns the
34-digit reference under all seven modes. A deterministic comparison of 600
additional 34-digit inputs between -20,000 and 20,000 found 25 last-digit
differences in the former formula and none in the revised formula. This
search is regression evidence rather than a proof of correct rounding.

P34 provides no error margin for `realExp`, integer power, or their closing
product. Deliberately selecting p34 made five exact all-digit scalar checks
fail. It also overflowed inside the work calculation for `2^20414` in modes
that require the largest finite Real34 value, so the required directed result
could not be recovered. P51 and p75 add no needed scalar margin after range
reduction.

## Complex route

For `z = a + ib`,

```text
2^z = 2^a (cos(b ln(2)) + i sin(b ln(2))).
```

The magnitude uses the revised scalar p39 route. Phase formation uses a new
p75 `ln(2)` constant and one p75 multiplication. The integrated
trigonometric dependency reduces a radian input at p12321, shortens the
reduced angle at p75, and evaluates its guarded series at p51. The two final
products use p39. Each product multiplies a magnitude by one trigonometric
component and contains no cancellation.

The phase-formation error satisfies

```text
abs(delta theta) <= abs(b) ln(2) (2 u_p + u_p^2).
```

At `b = 1e20`, this is approximately `6.94e-31` at p51 and `6.94e-55`
at p75. P51 therefore cannot protect 34 component digits. Independent
220-digit evaluation gives

```text
2^(i 1e20) =
   0.4417529232488208010413068983416738988872148...
 - 0.8971367536786804938483461417581288009474873... i.
```

The former p39 route returned

```text
0.4417529232488208010861516820732857
  - 0.8971367536786804938262644309992405 i.
```

A deliberate p51 substitution still failed all eight exact complex checks;
p75 returns both reference components under every user mode. The checks
subtract the complete 34-digit complex result and scale the difference by
`1e40`, so the ordinary 30-digit comparison threshold cannot hide a final
digit error.

No selected fixed context protects the phase across the complete Real34
range. The p75 formation bound reaches one Real34 component unit near
`abs(b) = 1e40`, while Real34 permits exponents through 6144. Reducing the
already rounded phase at p12321 cannot recover digits lost in `b ln(2)`.
Full-range support needs a verified high-precision period `2 pi / ln(2)` and
reduction before phase multiplication, with the existing DM42 p2139 memory
limit considered separately.

## Zeros, special values, and range transitions

Both signs of scalar zero return positive one. With special results enabled,
positive infinity returns positive infinity, negative infinity returns
positive zero, and NaN propagates. The existing domain error remains when a
special scalar input is used with special results disabled.

An exact zero complex imaginary component now takes the scalar magnitude
route and writes a positive imaginary zero. This avoids the invalid product
between an infinite or NaN magnitude and a computed zero sine. Consequently,
`+infinity + i0`, `-infinity + i0`, and `NaN + i0` return
`+infinity + i0`, `0 + i0`, and `NaN + i0`. A nonzero special imaginary
component still produces two NaNs through phase arithmetic.

The integer cases `20413`, `20414`, `-20517`, and `-20518` exercise both
Real34 range edges. `2^20413` is finite. At `2^20414`, nearest, away, and
ceiling modes request infinity, while toward-zero and floor return the
largest finite positive Real34 value. At the lower edge, the selected mode
chooses between positive zero and `1e-6176`.

## Matrix route

`processIntRealComplexMonadicFunction` sends real and complex matrices to
`elementwiseRema` and `elementwiseCxma`. Each element is copied to register X,
processed by `twoPowReal` or `twoPowCplx`, converted once to Real34, and stored
back in the matrix. No matrix-level arithmetic adds error. Focused real and
complex matrix cases exercise the reduced scalar input, an integral power,
underflow, and the large complex phase.

## Regression evidence

The focused file contains 86 checks. With the earlier implementation, 72
succeeded and 14 failed: three scalar all-digit checks, eight complex phase
checks, two pure-real complex special checks, and one complex matrix check.
A deliberate p51 complex substitution left eight failures. A deliberate p34
scalar substitution left seven failures, including two directed-overflow
cases. The selected implementation succeeds in all 86 focused checks. A clean
simulator build followed by the complete suite succeeds in all 14,738 checks.

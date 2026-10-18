# Decimal context analysis for general power

## Scope and result

This analysis covers the public nonintegral real and finite complex routes in `power.c`. The guarded integer calculation for an exponent whose magnitude is at most
`10^9-1` remains unchanged at 39 digits. Larger integral real exponents retain their existing logarithmic route, with exact source parity used for negative bases.
Short integers and long integers otherwise remain outside scope except for
the exact scalar identities described below. Matrix application reuses the
same public real and complex entry functions element by element.

| Calculation | Selected context | Reason |
| --- | ---: | --- |
| nonintegral positive real base | 51 | logarithm error is amplified by at most the finite decimal128 exponential range; 39 digits have no adequate margin |
| finite complex base and exponent | 75 | rectangular products can cancel through about 68 input digits, and a squared-radius offset near one can require 68 digits |
| exact-axis phase reduction for decimal128 exponents | exact 68-digit modular arithmetic | a direct p75 remainder fails when its integer quotient needs more than 75 digits |

The p51 real route requires one dependency correction in `WP34S_Ln`: contexts wider than 39 digits now select the 75-digit `ln(10)` constant. The previous selection
gave a p51 series only a p39 exponent-reconstruction constant. No p39 caller changes its constant or context.

All fixed contexts use round-to-nearest, ties-to-even. The selected user mode is applied when the wide result is converted to decimal128. Differences caused only by
rounding a p39 half-even intermediate to decimal128 are outside this decision.

## Nonintegral real power

For positive finite `y`, write

```text
y^x = exp(w),  w = x log(y).
```

The completed logarithm analysis bounds the reduced p-digit series by fewer than 180 rounded elementary calculations. At p51, with unit roundoff `u51=5e-51`, its
conservative accumulated arithmetic bound is

```text
gamma(180) < 9.1e-49.
```

The p75 `ln(10)` constant contributes less than `5e-75` relatively before its product is rounded to p51. The input conversion is exact, and the following p51
multiplication contributes at most `u51` relatively.

A nonzero finite decimal128 result constrains `w` to the public exponential interval, whose magnitude is below 14,222. The first-order absolute error in `w` is
therefore below about

```text
14222 * (9.1e-49 + 5e-51) < 1.4e-44.
```

The exponential dependency can err by at most one p51 result unit, below `1e-50` relatively. Thus p51 leaves about ten decimal digits between the conservative
formation error and a decimal128 unit. Values close to overflow or underflow remain finite inside the p51 context until the selected output mode is applied.

This bound also covers a base close to one. The p51 logarithm subtracts the decimal128 base from one exactly, does not use exponent reconstruction in that interval,
and has relative error controlled by the same series estimate. A large `x` then multiplies both the exact logarithm and its error; the finite-result restriction still
bounds the error through `|w|` rather than through `|x|` alone.

P39 is too narrow for the composite calculation. Applying the p39 logarithm bound at the largest finite-result exponent gives an error scale above `1e-32` in `w`.
An independent p90 decimal search of 20,000 finite nonintegral decimal128 pairs found 1,493 wrong last digits with the p39 route. One stored case is

```text
y = 7.623068583195218190252761444302672
x = 751.0524713127250282194363444318017
y^x = 3.3557269982788782887749571044412704956...e662.
```

The p39 result ends in `271` rather than `270`.

Before the constant correction, p51 failed 213 of the same 20,000 results. For

```text
y = 8.297010262456967857043679519245368
x = 5972.146804679021755073184110003969
y^x = 8.6071628115862469538944115533074275415...e5487,
```

the p51 result was one decimal128 unit low because exponent reconstruction still used the p39 `ln(10)`. Selecting the p75 constant for p51 makes all 20,000 results
agree with the independently rounded values. P51 is the narrowest established context supported by the bound and these distinguishing cases.

Seven exact cases for a moderate nonintegral power assert result digit 34 under every output rounding mode. They separate the half-even, half-up, half-down,
away-from-zero, toward-zero, ceiling, and floor conversions from the fixed half-even p51 work.

## Integral exponent parity

A negative real base needs the exact parity of an integral exponent. Decimal
remainder at p39 cannot supply it when the quotient by two needs more than 39
digits: `(-1)^(1E40)` previously acquired the wrong negative sign. The shared
register classifier now determines Real34, short-integer, and long-integer
parity with exact integer arithmetic before exponent conversion. The existing
p39 or logarithmic magnitude calculation is unchanged.

## Exact scalar identities

An exponent of one requires no arithmetic. A long-integer base is now
converted directly to Real34, so digits beyond the p75 input width cannot
move the final rounding boundary. An exponent of minus one is a single
reciprocal operation. Real34 bases divide directly at p34, while long-integer
bases use exact integer coefficients to generate digit 35 and a sticky
indicator before one Real34 conversion.

The same reciprocal path is used when both operands are long integers. This
avoids rounding a wide denominator before division and also avoids a p39
quotient followed by the selected Real34 conversion. Zero, infinity, and NaN
continue through the existing special-value branches.

Exponents from `2` through `4` and from `-2` through `-4` use a bounded
extension of this exact path when the base is a LongInteger. GMP forms the
exact bounded power without first shortening the base. Positive exponents
convert that exact integer to Real34 once; negative exponents use it as the
denominator of the exact scaled-integer quotient. This covers the common small
powers without an unbounded temporary or a chained p34 calculation. Other
integral powers retain their established integer or p39 route.

Exact integer identities and small powers round their coefficient or quotient
directly to `SDIGS` when it is active. This avoids a 34-digit intermediate
midpoint followed by a second rounding to the configured result precision.

## Finite complex power

For `z=a+ib` and `q=c+id`, the principal value is

```text
z^q = exp(u+iv),
u = c*L - d*theta,
v = d*L + c*theta,
L = log(|z|),  theta = atan2(b,a).
```

The public route now forms this calculation at p75. The logarithm dependency uses its p75 series and constant; `atan2` uses its p75 Taylor route and p75 pi-family
constants. One multiplication and one fused multiply-add form each of `u` and `v`. The audited exponential and sine/cosine dependencies then compute the rectangular
result at the same caller width, with the trigonometric helper retaining its wider phase-reduction work internally.

P51 cannot cover cancellation in these exponent products. The stored case

```text
z = 2+i
q = 1e34 + 1.735626239831749182700007666635856e34 i
```

has order-`1e34` products in both `u` and `v`. An independent p220 decimal calculation gives

```text
z^q = -10.31318239437543923917468910327816
      -3.874188494103769723103215819042336 i.
```

The p51 route differs by `-3.9534933...e-5 - 2.398366...e-4 i`; p75 gives the asserted decimal128 result. P75 is the narrowest established context for this public
formation.

## Magnitude close to one

Taking `log(sqrt(a^2+b^2))` after rounding the magnitude is ill-conditioned near the unit circle. The revised p75 route instead forms

```text
delta = (d-1)(d+1) + s^2,
L = log1p(delta)/2,
```

where `d` is the rectangular component with greater magnitude and `s` is the other component. For decimal128 input inside the selected annulus, `d-1` and `d+1` are
exact at p75, their product needs at most 69 coefficient digits, and `s^2` needs at most 68. The fused addition is exact whenever the terms can cancel enough to affect
a decimal128 result. If the product is zero, the small square is retained directly. Outside the annulus, the magnitude-first logarithm stays well-conditioned.

For

```text
z = 1 + 1.234567890123456789012345678901234e-34 i,
q = i,
```

the squared-radius offset is about `1.524157875...e-68`. The earlier p39 route and a deliberate p51 route both rounded the magnitude to one and returned a zero
imaginary component. Independent p220 evaluation gives an imaginary component

```text
7.620789376619418375247675781283333020...e-69.
```

Exact subtraction and scaling assert digit 34 in all seven output modes. This case establishes the p75 requirement independently of the large-product case.

## Exact axes and branch cut

Axes and diagonals have rational multiples of pi. The real exponent is reduced modulo eight for equal-magnitude components, modulo four for a pure imaginary base,
and modulo two for a negative-real base. A decimal128 exponent now uses the exact real34 remainder helper. Wider reusable inputs use the general wide remainder.

The former p75 direct remainder returns NaN when the integer quotient needs more than 75 digits. Both `(-1)^(1e6144)` and `i^(1e6144)` therefore returned NaN. Exact
modular reduction returns one for both. Integer negative-real powers also set the imaginary component to exact zero after the trigonometric calculation.

The sign of an exact imaginary zero selects the negative-real branch-cut side. The stored square-root cases assert `(-1+0i)^0.5=+i` and `(-1-0i)^0.5=-i`. An exact
finite exponent of one copies both base components and their signs, avoiding a logarithm and exponential reconstruction. This identity failed by one decimal128 unit
under floor mode before the direct branch was added.

## Conditioning limit

No fixed context can give a uniform 34-digit guarantee for every general complex decimal128 power. Errors in `L` and `theta` are multiplied by exponent components,
which may have adjusted exponent 6,144. The p75 value of `v` can lose every fractional phase digit before the wider trigonometric reducer receives it. Cancellation
in `u` can likewise expose an arbitrarily small result of two large products. A complete remedy would need logarithm and angle precision that grows with the exponent
magnitude, potentially beyond 6,200 digits, followed by wide formation of `u` and `v`.

The exact-axis reductions remove this limitation for rational pi phases. The p75 route materially improves ordinary finite inputs and cases with about 34 digits of
product cancellation, but the extreme general-phase limitation remains explicit.

## Zero, NaN, and infinity

A zero complex base with a NaN in either exponent component now returns two NaNs. Zero to a zero exponent remains indeterminate, and the existing finite nonzero
exponent branch returns complex zero. Infinite-base behaviour retains the existing sector handling and zero or infinity magnitude rules.

The finite identity branch excludes NaN base components, so it does not replace NaN propagation. Infinite bases are classified before that branch. Real negative
nonintegral bases continue through the complex route when complex results are enabled and report a domain error otherwise.

## Verification

The cases are in the existing `power_real.txt`, `power_longInteger.txt`, and
`power_complex.txt` files. They cover all seven output modes, the p39 and uncorrected-p51 real discriminators,
near-unit complex values, large complex exponent products, exact exponent one, both negative-real branch-cut sides, decimal128 exponent-limit axes, zero-base NaNs,
exact large-exponent parity, and existing finite and special-value behaviour.

With the former p39 complex route, 217 of 227 then-current focused checks succeeded. The ten failures were the seven near-unit modes, the large-product value, and two
negative-axis integer values. A deliberate p51 complex route still failed all seven near-unit modes and the large-product value. With the former direct axis remainder,
the two exponent-limit axis results were NaN. The revised source succeeds in all 345 focused checks across these files.

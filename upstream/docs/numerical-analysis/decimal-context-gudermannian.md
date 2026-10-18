# Decimal context analysis for the Gudermannian functions

## Scope and result

This analysis covers the public scalar and complex `gd` and `invGd` routes, their reusable real and complex helpers, and elementwise matrix evaluation. Long-integer and short-integer conversion is outside the scope.

| Calculation | Former context | Selected context | Result |
| --- | ---: | ---: | --- |
| finite scalar `gd` | 39 | 39 | a tanh/atan identity removes subtraction at zero |
| finite scalar `invGd` | 39 | 39 | an asinh/tan identity removes addition to `pi/4` at zero |
| finite complex `gd` | 39 | 39 | a global tanh/atan identity avoids exponential saturation and cancellation at every zero |
| finite complex `invGd` | 39 | 39 | a global asinh/tan identity avoids loss of the half-angle offset for large real components |
| real and complex matrices | 39 | 39 | every element uses the corresponding scalar calculation |

P39 is the narrowest established context for all four public routes. P34 has neither the arithmetic margin nor the wide exponent range used by the audited tangent, hyperbolic tangent, arctangent, and inverse-hyperbolic-sine dependencies. P51 and p75 add no needed digit after the stable rewrites. Reusable helpers select p75 constants when a wider caller context requests them.

The working context uses round-to-nearest, ties-to-even. Decimal128 conversion applies the selected calculator mode. Differences caused only by the accepted p39-to-p34 boundary effect are outside this analysis.

## Scalar Gudermannian

The former formula was

```text
gd(x) = 2*atan(exp(x)) - pi/2.
```

For a tiny `x`, the p39 exponential rounds to one and the subtraction returns zero. The revised formula is

```text
t = tanh(x/2)
gd(x) = 2*atan(t).
```

The division by two is exact in the p39 exponent range. The completed hyperbolic-tangent analysis bounds its stable p39 arithmetic by twice the `expm1` relative bound plus less than `3.01e-38`. The completed `expm1` analysis has a conservative p39 bound below `9.1e-37` in its small-argument region. Thus the relative perturbation in nonzero `t` is below `1.86e-36`, apart from second-order terms.

For real `|t| <= 1`,

```text
|t / ((1+t^2)*atan(t))| <= 1.
```

The input perturbation is therefore not amplified. Adding the completed p39 arctangent bound below `7e-36` and the closing multiplication gives a conservative relative bound below `9e-36` for every finite nonzero scalar result. This is less than one tenth of the smallest relative decimal128 spacing.

Both signs of zero use an explicit exact branch. Infinite inputs return signed `pi/2`, and NaN propagates.

## Scalar inverse Gudermannian

The former formula was

```text
invGd(x) = ln(tan(x/2 + pi/4)).
```

The addition rounds to `pi/4` when `x` is tiny. The revised real-domain formula is

```text
invGd(x) = asinh(tan(x)),  |x| < pi/2.
```

The trigonometric audit uses a 12,321-digit radian reduction where memory permits, a p75 reduced angle, a p51 series, and the requested p39 tangent. Its p51 series error is below `1.6e-46`; the p39 division supplies the first relevant working-width rounding. The relative condition of the following transformation is

```text
|t / (sqrt(1+t^2)*asinh(t))| <= 1.
```

The completed scalar asinh bound is below `1.2e-36`. Including the tangent rounding gives a conservative relative bound below `1.3e-36`. Near either domain endpoint, the wide angle reduction retains the distance from `pi/2`, while the asinh transformation damps relative perturbation in the large tangent.

Both zero signs receive explicit treatment. A NaN now propagates instead of reporting a domain error. Inputs with `|x| >= pi/2` retain the domain error.

## Complex Gudermannian

The defining branch is

```text
gd(z) = 2*atan(exp(z)) - pi/2
```

The exponential can overflow even when the result is finite. Near zero the expression also subtracts nearby order-one values and can erase either small component. The same cancellation recurs at `z=2*pi*i*k`.

Set

```text
w = tanh(z/2).
```

The tangent addition identity gives

```text
atan(exp(z)) - pi/4 = atan(w)
```

up to an integer multiple of `pi`. The revised calculation uses

```text
gd(z) = 2*atan(w)
```

for every input. It then subtracts `2*pi` from the real component when `Re(z)` is nonnegative and `cos(Im(z))` is negative. A negative real zero selects the other cut side. This branch correction follows from the principal arctangent and reproduces the defining exponential form without evaluating the exponential.

For `|w| < 0.1`, the atan power series gives

```text
|atan(w)/w - 1| < |w|^2 / (3*(1-|w|^2)) < 0.00337,
|1/(1+w^2)| <= 1/(1-|w|^2) < 1.011.
```

The zero-centred map therefore has a normwise condition factor below `1.015`. The p39 complex tanh and arctangent analyses retain the required decimal128 margin there. An exact component zero uses an absolute error statement; no uniform componentwise-relative claim is possible.

Away from a zero, the derivative is `sech(z)`. Its growth near `z=i*(pi/2+pi*k)` is inherent in the function. The complex tanh arithmetic contributes less than `1.31e-37` beyond its audited trigonometric and exponential dependencies. The complex arctangent contributes less than `4e-37` radians in its ordinary finite region. Halving and doubling add at most two p39 unit roundoffs. The branch correction changes an order-one real component by a p39 `2*pi` value and introduces no small-result subtraction. P39 supplies the required guard margin; p51 and p75 do not improve conditioning near a mathematical pole.

The wide reducer used for `cos(Im(z))` covers the decimal128 phase range and makes the branch decision before either aliased output is written. The global hyperbolic form also gives finite phase-dependent limits for an infinite real component and avoids the positive exponential overflow route.

## Complex inverse Gudermannian

The defining form is

```text
invGd(z) = ln(tan(z/2 + pi/4)).
```

For `w=tan(pi/4+z/2)`, the tangent identity gives

```text
sinh(log(w)) = (w-1/w)/2 = tan(z).
```

Thus `A=asinh(tan(z))` supplies the value on each even half-period. When `cos(Re(z))` is negative, the defining branch is

```text
invGd(z) = -A + sign(Im(z))*i*pi.
```

The sine sign resolves a reduced cosine zero on the odd half-period. Signed imaginary zero selects the corresponding side of the logarithmic cut. The implementation stores both input sign properties before writing either aliased output, then applies the reflection and p39 or p75 `pi` correction.

The completed p39 complex tangent and asinh analyses apply across the full plane. Reflection is exact, and addition of p39 `pi` affects an order-one imaginary component without erasing a small real component. The tangent uses the audited 12,321-digit radian reduction, a p75 reduced angle, and a p51 series before the requested p39 quotient.

The asinh map has derivative `1/sqrt(1+t^2)` and a normwise condition close to one for small `|t|`. The complex asinh analysis gives less than `1.3e-36` relative error for a nonzero real component and less than `3.7e-37` radians absolute error for its ordinary imaginary component. Near a tangent pole, the combined derivative is `sec(z)`, so the growth is inherent. P39 retains a decimal128 margin away from those mathematical singularities.

The former half-angle expression added p39 `pi/4` after dividing the input by two. For `Re(z)=1e50`, that offset vanishes completely. Direct reduction of `tan(z)` avoids the loss, and the cosine sign supplies the correct logarithmic branch.

## Context discriminators and periodic regressions

An independent decimal power-series computation gives

```text
gd(0.3) = 0.295598675984604137678966703688534014290530137...
invGd(0.3) = 0.304603974401704103793067467766915779175631951...

gd(0.3+0.4i)
  = 0.319305696454250568242587122091079383593921527...
  + i*0.391355791786976172468507477138065745635418187...

invGd(0.3+0.4i)
  = 0.280489856561165048611578136788980513007012353...
  + i*0.406060632506121673029721386227258148394528602...
```

The final file-driven cases assert all seven scalar output modes through digit 34. With only the scalar public work context changed to p34, 103 of 114 checks succeed and 11 fail. With only the complex public work context changed to p34, 140 of 146 checks succeed. Failures include both ordinary complex digit-34 assertions and four directed large-phase assertions.

For the nearest decimal128 value above `2*pi`,

```text
6.283185307179586476925286766559006 - 2*pi
  = 2.3160566120124978835805011081538436718...e-34.
```

At `z=1e-100+i*6.283185307179586476925286766559006`, a selector restricted to the raw origin loses the `1e-100` real result. At the corresponding real input for `invGd`, it loses the displayed residual. Together with the odd-pi cases below, that restricted selector succeeds in 110 of 114 checks. The transformed selectors succeed in all 114.

The nearest decimal128 value above `pi` differs from `pi` by

```text
1.1580283060062489417902505540769218359...e-34.
```

The former inverse-complex expression loses this real displacement beside its signed `i*pi` component. The reflected formula retains it on both signed-zero sides. The prior local implementation inspected the output sign after aliased evaluation and consequently reversed those two cut sides; the stored input sign corrects that defect.

An independent 180-digit trigonometric and logarithmic calculation gives

```text
invGd(1e50+i*0)
  = -1.070561023278629803527587916664403509...
    + i*3.141592653589793238462643383279502884...
```

The negative-zero side has the opposite imaginary sign. With the revised expectations present, the former implementation succeeds in 134 of 146 focused checks. It returns a real value wrong by about `1.785e40` scaled units for every large-phase output mode, reverses both odd-`pi` signed-zero cut sides, and loses the negative real zero beside an infinite imaginary input. The revised implementation succeeds in all focused checks.

The final cases are in the existing `gd.txt` and `invGd.txt` file-driven suites. They include all scalar output modes, tiny scalar and complex inputs, ordinary complex digit-34 values, repeated even- and odd-pi points, a `1e50` inverse phase, infinite components, signed zero, NaN, and real and complex matrices. No auxiliary test script is required.

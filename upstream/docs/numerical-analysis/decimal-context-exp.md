# Decimal context analysis for exponential

## Scope and result

This analysis covers `realExp`, the scalar decimal128 entry, and `expComplex` in `src/c47/mathematics/exp.c`. Matrix application reuses the same entry functions element by element. Functions that invoke `realExp` inside another approximation need an error analysis for the enclosing calculation.

| Calculation | Selected context | Reason |
| --- | ---: | --- |
| scalar `exp(x)` | 39 | the library exponential may err by one unit in its working precision, while p39 supplies five digits beyond the result |
| complex magnitude `exp(a)` | 39 | the scalar bound applies |
| complex sine and cosine | p12321 reduction, p75 reduced angle, p51 series, p39 result | the audited trigonometric kernel preserves the phase before returning guarded components |
| closing complex products | 39 | each component is one correctly rounded multiplication without cancellation |

P39 is the narrowest established caller context for both public routes. P51 and p75 do not improve the scalar bound in a way needed for a 34-digit result. The complex conclusion uses the completed analysis of `C47_WP34S_Cvt2RadSinCosTan`; the original DM42 memory-limited reduction remains its documented platform exception at extreme exponents.

The working contexts retain round-to-nearest, ties-to-even. The selected user mode is applied when the p39 result is converted to decimal128. Differences caused only by this accepted p39 to p34 boundary are outside the context decision.

## Scalar error

The scalar route performs no arithmetic on its finite input before calling `decNumberExp`. The decNumber implementation documents a finite result as half-even and almost always correctly rounded, with a possible error of one unit in the last working digit in rare cases. For a normal p-digit result this gives the conservative relative estimate

```text
|result_p / exp(x) - 1| <= 10^(1-p).
```

At p39 the bound is `1e-38`. The distance between adjacent 34-digit results is at least `1e-34` relative, so five decimal guard digits separate the documented library error from the result precision. This reasoning excludes a true value within the p39 uncertainty interval around a p34 boundary, as required by the accepted boundary policy.

P34 cannot support the same claim. Its documented one-unit error is already one complete result unit, with no guard digit. It also uses the decimal128 exponent limits during `decNumberExp`. At

```text
x = 14149.38539644841072829055748903542,
```

the exact exponential is approximately

```text
1.00000000000000000000000000000194429123135e6145.
```

Rounding modes 4 and 6 require the largest finite decimal128 result, but a p34 exponential overflows before result conversion and the finite directed result cannot be recovered. A deliberate p34 substitution fails this regression with overflow. P39 has exponent limits of plus or minus 999999, so it retains the finite intermediate until decimal128 conversion.

For finite user input, the explicit magnitude limit at `|x| > 2e6` is far outside the decimal128 output transitions near `14149.4` and `-14221.5`. It therefore maps to the correct public zero or infinity region. This limit is a property of the reusable helper: a composite calculation requesting a wide result does not receive finite exponentials beyond that input limit, even where the p39 number format could represent them.

## Decimal128 range transitions

The upper transition is bracketed by adjacent decimal128 inputs around `6145 log(10)`:

```text
exp(14149.38539644841072829055748903541)
  = 9.99999999999999999999999999991944291231...e6144,

exp(14149.38539644841072829055748903542)
  = 1.00000000000000000000000000000194429123...e6145.
```

The first value rounds to a finite result. For the second, modes 0, 1, 2, 3, and 5 request infinity, while modes 4 and 6 return `9.999999999999999999999999999999999e6144`.

The lower half-even transition is bracketed by adjacent inputs around `log(0.5e-6176)`:

```text
exp(-14221.45868151178608980453245625210)
  = 4.99999999999999999999999999995761356239...e-6177,

exp(-14221.45868151178608980453245625209)
  = 5.00000000000000000000000000000761356239...e-6177.
```

The first rounds to zero in modes 0, 1, 2, 4, and 6 and to `1e-6176` in modes 3 and 5. The second rounds to `1e-6176` in modes 0, 1, 2, 3, and 5 and to zero in modes 4 and 6.

The seven tests of `exp(1)` assert result digit 34 under every rounding mode. Independent high-precision evaluation gives

```text
exp(1) = 2.7182818284590452353602874713526624977572470...
```

Modes 3 and 5 therefore return a result ending in `663`; the other modes return one ending in `662`.

## Complex error

For finite `z = a + ib`, the implementation evaluates

```text
exp(z) = exp(a) cos(b) + i exp(a) sin(b).
```

The magnitude has the p39 scalar error above. A p39 request to `C47_WP34S_Cvt2RadSinCosTan` reduces radians at p12321 on builds with sufficient memory, shortens the first-octant angle at p75, and evaluates the series at p51. On `|r| <= pi/4`, the completed trigonometric analysis bounds the p51 relative arithmetic error below `1.6e-46`, including its 1,000-iteration implementation limit. The actual interval needs fewer than 32 terms. The components are then rounded to the requested p39 context.

The p75 reduced angle preserves small components before the p51 series. The returned p39 component and one p39 multiplication remain far below one p34 unit, with absolute error controlling components close to zero. There is no subtraction in either closing component. The three local working values have explicit p75-sized frame storage, which supports every established context accepted by this helper and requires no heap allocation.

Direct phase input avoids the phase-formation problem in power functions, where multiplying a large imaginary input by a logarithm can lose fractional phase digits. Independent 220-digit evaluation gives

```text
exp(i 1e20) =
   0.7639704044417283004001468027378811228344734...
 - 0.6452512852657808442058117113125230074069042... i.
```

Both component regressions subtract the rounded decimal128 value and scale the difference by `1e40`; both produce zero with the audited reduction and series widths.

The p12321 `2 pi` constant bounds reduction error below `8e-6178` at the decimal128 upper exponent limit. This is less than one tenth of the minimum decimal128 subnormal unit, so it also protects components close to a trigonometric zero. The exponential regression at the upper exponent limit uses

```text
b = 5.829979800222281883747164188135449e6144,
sin(b) = -2.908962159350783229012734764285262...e-34,
cos(b) = 1 - 4.230...e-68.
```

The original DM42 uses a p2139 remainder context because of available memory. As documented by the trigonometric audit, this cannot cover the complete decimal128 complex exponent range. Other builds use p12321. Changing the `expComplex` caller context to p75 would not remove this hardware limit.

## Zero, NaN, and infinity

Both signs of scalar zero map to positive one. With special results enabled, positive infinity maps to positive infinity, negative infinity maps to positive zero, and NaN maps to NaN.

An exact zero complex imaginary component takes the scalar route and returns a positive imaginary zero. This includes negative zero and avoids multiplying an infinite magnitude by a computed zero sine. A NaN real component with nonzero finite imaginary component, or any nonzero special imaginary component, returns two NaNs.

For a finite nonzero imaginary component, the real component may be infinite. The formula remains defined: positive infinity produces signed infinite components according to cosine and sine, while negative infinity produces signed zeros. The earlier special-value guard returned two NaNs instead. The revised guard lets these values use the existing magnitude, trigonometric, and multiplication operations. Regressions check both infinity signs and expose negative zero by taking its reciprocal.

## Regression evidence

The focused file contains 95 checks. With the earlier special-value guard, 91 succeeded and four failed: the two positive-infinity phase cases and two negative-infinity signed-zero cases. All 95 succeed with the revised guard.

With the scalar call deliberately reduced from p39 to p34, the upper-bound mode-4 case reports overflow instead of returning the largest finite decimal128 value. Restoring p39 makes the focused file succeed. The complete suite succeeds in all 14,508 cases.

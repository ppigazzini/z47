# Decimal contexts for printer number formatting

## Scope and decisions

This analysis covers numeric formatting in `printing/print.c`: Real34 values,
rectangular and polar complex values, and the corresponding matrix elements.
`display.c`, plot and graph code, long integers, and short integers are outside
this scope.

| Route | Work precision | Reason |
|---|---:|---|
| Real34 and rectangular complex | none | The stored Real34 coefficients are formatted without decimal arithmetic in `print.c` |
| Polar complex, magnitude and argument | 18 digits | The printer emits at most 16 significant figures; two work digits retain a faithful result |
| Radian-to-output-unit conversion | 18 digits | One multiplication or division without cancellation follows the argument calculation |
| Real and complex matrices | as above | Each element uses the corresponding scalar formatter |
| Real character-code input | none | Real34 comparison and bounded integer conversion operate on the stored value |

The polar context starts from `ctxtReal39` to retain its wide exponent limits
and changes only `digits`. A 34-, 39-, 51-, or 75-digit coefficient width is
unnecessary at this 16-figure output boundary. The selected 18 digits are the
narrowest defensible width from the bounds below.

## Polar finite error

Let `u18 = 0.5E-17 = 5E-18`. For rectangular components `x` and `y`, the
magnitude calculation is

```text
s = RN(y*y + RN(x*x))
r = RN(sqrt(s)).
```

The nonnegative sum avoids cancellation. With `S = x*x + y*y`,

```text
|s-S|/S <= 2*u18 + u18^2
```

and square-root propagation plus its final rounding gives a relative error
below `1.01E-17`. The unit roundoff at the 16-figure output boundary is
`u16 = 5E-16`, so the magnitude error uses less than 2.1 percent of that
budget.

The argument calculation first divides the two components at p18. Perturbing
the quotient changes `atan` by at most `u18/(2*(1-u18))` radians. The atan
kernel then evaluates its table reduction at p20 because it adds two internal
guard digits. Outside the table cell centred on zero, scaling the integrated
40-operation bound to p20 and including the quotient gives an absolute error
below `6E-18` radians. Division by `atan(0.05)` bounds the relative error by
`1.3E-16`. Inside the zero-centred cell the calculation is relative-stable and
the bound is below `8E-18`.

Degrees, gradians, DMS, and multiples of pi add one p18 multiplication or
division. The operation has no subtractive cancellation and contributes at
most one further `u18`; the p39 constants contribute much less. The resulting
bound remains below half of `u16`. P17 is not selected because the quotient
and table-cell bound can consume the complete 16-figure margin.

These are faithful-accuracy bounds, not a universal correct-rounding claim.
The accepted final p39-to-p34 double-rounding distinction is outside this
decision.

## Exponent range defect

The former polar printer precision was

```text
max(0, maximum adjusted component exponent) + display allowance + 2.
```

Precision does not need to grow with a uniform scale because both `hypot` and
`atan2` are well conditioned under scaling. More importantly, the largest
finite Real34 adjusted exponent is 6144. In `DF_ALL`, a component such as
`3E6144` therefore requested 6,168 digits from a `real_t` that has capacity for
75 digits. `realRectangularToPolar` rejects a request above 75, and aliased
input/output variables then left the original components in place. Polar
printing of `(3E6144,4E6144)` consequently produced
`3.E6144` and `4.E6144` instead of `5.E6144` and approximately
`0.9272952180016` radians.

The fixed p18 context remains within `real_t` capacity. Its inherited exponent
limits contain component squares with adjusted exponents from -12352 through
12288, so finite Real34 inputs do not overflow or underflow in the work
calculation. A magnitude outside the Real34 output range becomes infinity at
the existing result-pack boundary.

## Packing and nonarithmetic routes

Real34 input expands to `real_t` exactly. The p18 polar results then receive
one Real34 pack per component before the common number formatter. Since a
p18 coefficient fits in Real34, this pack does not shorten a finite
coefficient; it applies the established Real34 range boundary. A single p34
operation is cost-neutral. This route introduces no chained p34 arithmetic,
so it also avoids the conversion work that can make such chains slower than
p39.

Ordinary real and rectangular-complex printing performs no decimal arithmetic
in `print.c`. Matrix printing applies the same scalar helpers element by
element; `real34Reduce` only removes redundant coefficient zeroes. The
character-code helper uses Real34 comparison and integer-conversion wrappers
and needs no `decContext`.

NaN and infinity classifications come from the shared rectangular-to-polar
special table. Signed zero remains observable: a negative finite ordinate
beside positive infinity gives a negative-zero angle, while any signed-zero
pair at the origin gives positive-zero magnitude and angle under the existing
rectangular convention. Real formatting retains a stored negative zero.

The complex formatter now directs text to its supplied output buffer. Its
previous use of the global scratch buffer happened to work for production
callers because they supplied that same buffer, but it did not satisfy the
helper interface.

## Verification

The existing `polar_display_cov.txt` file now also covers real, complex, and
complex-matrix printer formatting. Cases include both Real34 exponent limits,
negative zero, NaN, both infinity signs, an infinite-axis negative-zero angle,
and ordinary finite polar output.

With the former exponent-scaled precision reinstated, the focused file
succeeded in 14 of 15 cases. The `(3E6144,4E6144)` case produced the original
components rather than their polar values. The revised source succeeds in all
15 cases.

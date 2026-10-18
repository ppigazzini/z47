# Decimal contexts for RDP and RSD

## Scope and decisions

This analysis covers `roundToDecimalPlace`, `roundToSignificantDigits`, the
Real34, Complex34, matrix, DMS and time entry routes, and the XRDP and XRSD
uses of the two helpers. Long and short integers are outside its scope.

An ordinary Real34 value and each rectangular complex component now use p34.
The same choice applies elementwise to real matrices and rectangular complex
matrices. P34 is sufficient because the operation changes only a decimal
exponent and then invokes the decimal integral-value operation. That operation
uses the selected rounding mode but explicitly ignores the context digit
count.

DMS, time and polar complex values remain at p39. DMS and time conversion can
need four digits beyond the Real34 coefficient before the requested rounding.
Polar conversion uses the established p39 magnitude, atan2 and trigonometric
routes. P51 and p75 add no required margin for these Real34 entries. The
accepted p39-to-p34 boundary effect is outside this analysis.

XRDP and XRSD retain their caller-created context. Its digit count is 75 on
the DM42 and the configured extended width on other builds. An extended input
can contain more than 34 digits, so replacing that context with a fixed p34
context would break the extended-precision contract.

## Decimal rounding kernels

Write a finite nonzero decimal as

```text
x = sign * coefficient * 10^e,
```

where the coefficient contains `d` decimal digits. RDP with parameter `n`
changes the exponent by `n`, rounds to an integer with the selected mode, and
changes the exponent back. It therefore computes

```text
RDP(x,n) = round_integer(x * 10^n) * 10^-n.
```

RSD first uses `d + e - 1` to place the leading digit, then applies the same
integral rounding. It computes the corresponding `n`-significant-digit value.
The exponent changes are exact field changes. For a negative exponent,
`decNumberToIntegralValue` internally sets its work precision to the operand's
digit count; for a nonnegative exponent it copies the operand. The public
Real34 kernels consequently have no arithmetic error before their requested
rounding and need no guard digits.

Zero and special operands are copied before exponent changes. This also
preserves the sign of zero. Tests exercise positive and negative ties under
all seven selectable rounding modes, signed subnormal results and both
decimal128 exponent limits.

## DMS conversion

The stack stores a DMS-tagged real as decimal degrees, while RDP and RSD act on
the displayed `ddd.mmss` fields. Conversion from a 34-digit decimal degree
value to this field representation proceeds as follows:

```text
fractional degree * 60
fractional minute * 60.
```

Each multiplication can add two coefficient digits. The exact displayed-field
value can therefore need 38 digits. Subtraction of the integral degree and
minute fields is exact, and decimal placement of minutes and seconds changes
only exponents. P39 represents the complete forward conversion and the
requested integral rounding.

The inverse conversion divides minutes by 60 and seconds by 3600, then adds
nonnegative terms before restoring the input sign. With
`u39 = 5E-39`, the two correctly rounded divisions and two additions give a
relative error below `4*u39` for a nonzero result. This leaves more than four
guard digits before Real34 conversion.

P34 is insufficient. For the exact Real34 decimal-degree input

```text
0.01388888888888888888888888888888889
```

the displayed-field value is

```text
0.0050000000000000000000000000000000004.
```

RDP 2 in half-even mode must select `0.01`. Shortening the converted value to
p34 first makes it the exact tie `0.005` and incorrectly selects zero. The
analogous RSD 1 input

```text
0.004166666666666666666666666666666666
```

has displayed-field value

```text
0.00149999999999999999999999999999999976.
```

It is below the half-even tie and must select `0.001`; a p34 intermediate
selects `0.002`. The conversion now remains p39 until the decimal-degree result
is ready for Real34 storage.

The generic wide conversion helpers copy NaN and infinity before arithmetic.
This prevents an infinite tagged value from entering an infinity-minus-
infinity subtraction.

## Time conversion

A time register contains seconds, while decimal-place and significant-digit
rounding apply to the displayed `H.MMSS` fields. The route now divides by 3600
at p39, uses the wide decimal-degree to DMS conversion for the structurally
identical base-60 fields, rounds the field value, converts back, and multiplies
by 3600.

The former repeated single-digit mapping mixed some second values with the
adjacent minute. For example, RDP 2 of `00:00:41.918` returned `00:01:00`; the
field value is `0.0041918`, so the half-even result is zero seconds.

P34 is also too narrow for the replacement route. The Real34 input

```text
00:00:50.00000000000000000000000000000001
```

is above the RDP 2 half-even boundary. P39 returns `00:01:00`; a p34 candidate
loses the nonzero suffix during division and returns zero. Across the allowed
time range, five guard digits exceed the four decimal positions introduced by
the two base-60 fields. The initial division, inverse conversion and closing
multiplication have a combined relative error below `6*u39` away from zero.
The p39 exponent range also contains every finite Real34 time input, including
subnormal values.

NaN and infinity retain their special classification through conversion.
The existing time-range check still reports an out-of-range result for an
infinite time. Negative values and signed zero retain their signs.

## Complex and matrix routes

Rectangular Complex34 values round their two stored components independently,
so p34 is exact up to the requested rounding. The real and rectangular complex
matrix routes invoke those scalar paths for each element and use the same
contexts.

Polar mode first derives magnitude and radian angle, rounds both values, and
converts them to rectangular storage. The completed coordinate-conversion
analysis establishes p39 for both conversions. The result is faithfully
accurate to Real34 except for the accepted p39-to-p34 boundary case. The same
route applies to each polar complex matrix element.

## Verification

The expanded `round_cov.txt` file covers all scalar and matrix routes, DMS and
time adversaries, polar conversion, signed zero, wide exponents, NaN, infinity
and positive and negative ties in every rounding mode. Existing `xfn.txt`
cases exercise 20-, 50- and 238-digit XRDP and XRSD results.

Before the DMS change, the two field-boundary cases returned zero and the
opposite RSD neighbour respectively, and tagged infinity became NaN. Before
the time rewrite, its new field case returned one minute rather than zero.
The p34 time candidate also failed the 50-second boundary case. The revised
p39 conversion and p34 direct routes satisfy all focused cases.

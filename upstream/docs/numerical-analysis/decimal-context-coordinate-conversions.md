# Decimal contexts for coordinate conversions

## Scope and decisions

This analysis covers the dyadic Real34 entry points in `toPolar.c` and
`toRect.c`, their reusable real helpers, and the complex and vector dispatch
in those files. The polar-entry analysis includes exact source-unit reduction
for a long-integer angle.

The public rectangular-to-polar route remains at p39. Its magnitude and angle
depend on the completed complex-magnitude and atan2 analyses. The public
polar-to-rectangular route also remains at p39. Its trigonometric dependency
performs source-unit or radian reduction at its established wide precision,
uses p75 for the reduced argument, and uses at least p51 for the series.

P39 is the narrowest established direct-entry context for both conversions.
P51 and p75 add no needed margin for Real34 output. The accepted p39-to-p34
boundary effect is outside this analysis.

## Rectangular to polar

For finite nonzero components, write

```text
S = x^2 + y^2
r = sqrt(S)
theta = atan2(y, x).
```

The magnitude route calculates one rounded square, one fused multiply-add,
and one square root. With p39 nearest work and `u39=5E-39`, the calculated
squared magnitude has relative error at most

```text
E = 2*u39 + u39^2.
```

Propagation through the exact square root contributes at most

```text
E / (1 + sqrt(1-E)),
```

and the rounded square root contributes one further `u39`. The combined
relative error is below `1.01E-38`. The p39 exponent range contains the
squares of all finite Real34 components. P34 can overflow or underflow during
those squares and has no complete final-digit margin for the three rounded
steps.

The completed p39 atan2 analysis gives relative error below `7E-36` for every
finite nonzero angle, and below `2.1E-37` in its cell centred on zero.
Conversion from radians to degrees, gradians, or multiples of pi adds one p39
rounding and a p39 constant error without cancellation. This is a
faithful-accuracy result rather than a universal correct-rounding result.

Axis and infinite cases do not need arithmetic. Their p39 pi-family constants
retain the margin required by a final Real34 result and match the atan2
constant selection. A reusable p75 request does not receive a full p75
special-axis angle; changing that contract requires audits of its p75 callers.

For a finite negative ordinate beside positive infinity, the exact extended
angle is negative zero. Beside negative infinity it is negative pi. The
special table now applies the ordinate sign to these two limits. An exact zero
ordinate retains the established rectangular convention: positive zero on
the positive axis and positive pi on the negative axis, regardless of the
stored zero sign.

The rectangular convention maps either sign of an exact imaginary zero on the
negative real axis to positive pi. At the origin it returns positive zero for
both radius and angle. NaN input gives two NaNs. Infinite pairs use the exact
quarter-turn directions listed in the source table.

## Polar to rectangular

For finite nonzero magnitude, each output has one trigonometric evaluation
and one multiplication:

```text
x = r*cos(theta)
y = r*sin(theta).
```

The audited trigonometric kernel has relative series error below `1.6E-46`
for a nonzero first-octant component at the p51 public setting. The component
then receives one p39 rounding, and the correctly rounded product contributes
at most another `u39`. Away from a trigonometric zero, the combined relative
error is below `1.01E-38` plus the much smaller series term. Near a zero, the
absolute phase-reduction bound replaces the relative bound. P39 therefore
provides more than four guard digits before Real34 conversion.

At p34, rounding the trigonometric component and then its product can consume
two p34 rounding errors before output. This has no final-digit margin, so p34
is not a defensible common work context. Wider public work is unnecessary
because the internal reducer and series already supply their established
precision.

Finite radian inputs from the public route now enter the trigonometric reducer
without an earlier p75 modulo. The earlier order could shorten a remainder
close to an axis before quadrant subtraction. The trigonometric reducer keeps
radian reduction and quadrant subtraction at 12,321 digits on builds with
sufficient memory, then shortens only the first-octant residual.

The exported `realPolarToRectangular` helper retains its p75 preliminary
reduction because several p75 algorithms depend on its established residuals
and ordering. P75 is sufficient for their normal components and for a final
Real34 component that is not extremely close to an axis. It is not a complete
p75 guarantee: a wider input can have a small component requiring digits
beyond the 75th digit of a remainder close to `2*pi`. Changing that reusable
contract requires separate audits of the polynomial, Bessel, power, and
solver callers.

## Source-unit reduction

The former public route converted the complete tagged angle to radians at
p39 before reduction. For a large angle, the absolute error from the p39 pi
constant grows in proportion to the unreduced angle and can make the final
phase unrelated to the input phase.

The revised route gives degrees, gradians, DMS, or multiples of pi directly to
the trigonometric helper. Exact modulo 360, 400, or 2 reduction occurs in the
source unit. Only the small residual is converted to radians at p75.

For the exact Real34 input

```text
theta = 1E6144 degrees,
```

integer arithmetic gives `10^6144 mod 360 = 280`. Independent 120-digit
evaluation gives

```text
cos(theta) =  0.173648177666930348851716626769314796...
sin(theta) = -0.984807753012208059366743024589523013...
```

The former p39 radian conversion produced approximately `-0.3800032625` and
`-0.9249851461`. Source-unit reduction produces the expected Real34 results
in all seven rounding modes. Exact huge gradian and multiple-of-pi periods are
also retained. Infinite magnitudes use the same source-unit reduction, with
an exact zero factor converted to positive zero before multiplication.

On the original DM42 hardware, the wide reduction temporary remains limited
to 2,139 digits. As documented for sine and cosine, that limit does not cover
the full Real34 exponent range. Other builds use the wider reduction needed
by the exponent-limit cases.

A long-integer angle now uses the same reducer before entering the polar
kernel. This matters even when the integer has only 41 digits: converting
`10^40+1` to a Real34 first loses the unit and changes its degree phase from
281 to 280. Exact integer reduction preserves the 281-degree components.

## Special values and dispatch

A NaN magnitude or angle, or an infinite angle, gives two NaNs. A zero
magnitude gives two positive zeros for every finite angle. The shared
trigonometric convention also normalises an exact angular zero. A nonzero
component from an infinite magnitude becomes the correctly signed infinity;
an exact zero factor remains positive zero. The established radian-axis
classification remains in use for stored pi-family constants.

Complex scalars and complex matrices do not perform numeric conversion in
these entry points. Their rectangular or polar display tag changes. A 2D real
vector receives or loses a polar tag. A 3D real vector cycles between
spherical and cylindrical display tags, and the reverse entry removes that
tag. These dispatch routes have no decimal context to narrow.

## Verification

The existing `rectangularToPolarB.txt` and `polarToRectangularB.txt` files now
cover the finite exponent limits, the exact negative-real-axis convention,
NaNs, infinities, signed zero, exact source-unit periods, and the decimal128
degree adversary in all seven rounding modes. The polar file also distinguishes
the exact 281-degree long-integer phase from its rounded 280-degree value.

Before the source-unit change, the focused polar-to-rectangular file succeeded
in 12 of 13 cases. The new exponent-limit case failed in both components. The
source-unit revision succeeded in all retained cases. Reinstating the former
infinite-abscissa table gives positive pi for `(-infinity,-2)` and fails the
new negative-axis check. The signed-zero result beside positive infinity is
made observable by its reciprocal.

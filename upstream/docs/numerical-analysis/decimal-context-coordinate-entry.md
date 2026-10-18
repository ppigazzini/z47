# Decimal contexts for ancillary coordinate entry

## Scope and decisions

This analysis covers polar numeric input in `bufferize.c`, complex input from
the matrix editor, the optional polar vector edit route, the coordinate helpers
in `matrix.c`, and stack-to-vector and vector-to-stack conversion in `addons.c`.
The public `toRect.c` and `toPolar.c` functions have a separate completed
analysis.

The ancillary routes now retain each source angle unit until the audited
trigonometric reducer has removed complete turns. Their finite chained work
stays at p39. A Real34 parse or final conversion remains p34 because it defines
the public input or output lattice. One direct p34 operation is cost-neutral and
can also be an appropriate result operation. P34 has no speed advantage in a
chain and can add unpack and repack work. P39 is therefore the minimum useful
intermediate width for these coordinate calculations. P51 and p75 do not
improve the final Real34 result.

| Route | Work context | Result |
|---|---:|---|
| Polar numeric input | p39 | Source-unit reduction and one component product |
| Optional polar vector edit | p39 | Source-unit reduction and one component product |
| Polar and cylindrical vector input | p39 | Source-unit reduction and one component product |
| Spherical vector input | p39 | Two source-unit reductions and at most two component products |
| Rectangular vector output | p39 | Magnitude, atan2, and angular-unit conversion |

Differences confined to the accepted p39-to-p34 rounding boundary are outside
this analysis.

## Full-range source angles

Converting a complete degree angle to radians at p39 forms

```text
theta_rad = RN39(theta_deg * pi / 180).
```

The absolute error from the finite p39 value of pi grows in proportion to
`|theta_deg|`. At the upper Real34 exponent it greatly exceeds a complete turn,
so later radian reduction cannot recover the source phase. Gradians and
multiples of pi have the same defect, and adding pi to encode a negative
magnitude can disappear beside a large converted angle.

The revised routes give the tagged angle directly to
`C47_WP34S_Cvt2RadSinCosTan` through
`realPolarToRectangularInUnit`. Degrees, gradians, and multiples of pi are
reduced modulo 360, 400, and 2 in their source unit. Only the small residual is
converted to radians. DMS uses its established source conversion, while radian
input uses the wide radian reducer.

For the exact input

```text
theta = 1E6144 degrees,
```

integer reduction gives `10^6144 mod 360 = 280`. Independent 120-digit
evaluation gives

```text
cos(theta) =  0.173648177666930348851716626769314796...
sin(theta) = -0.984807753012208059366743024589523013...
```

The former ancillary routes returned approximately `-0.3800032625` and
`-0.9249851461`. The source-unit route returns the expected Real34 pair.
Negative magnitude now uses the linear products directly instead of changing
the magnitude sign and adding half a turn.

## Forward error bounds

Let `u39=5E-39` for a normal half-even p39 operation. The completed
trigonometric analysis bounds the relative series error of a nonzero reduced
component below `1.6E-46`; its p39 shortening contributes at most `u39`. One
correctly rounded component product contributes another `u39`, so a 2D polar
or cylindrical component has relative work error below

```text
2*u39 + u39^2 + 1.6E-46 < 1.01E-38.
```

Near a trigonometric zero, the reducer's absolute phase bound replaces the
relative statement. The p39 product preserves more than four decimal guard
digits before Real34 conversion.

Spherical conversion first forms

```text
z     = r*cos(phi)
rhoXY = r*sin(phi),
```

using the polar angle's own tag. It then forms `x` and `y` from `rhoXY` and the
azimuth using the azimuth's tag. Thus `z` has the 2D bound above, and each of
`x` and `y` has at most one propagated component error, a second trigonometric
shortening, and a second rounded product. Their first-order relative bound is
below `2.01E-38`, apart from the absolute near-axis case. P39 is sufficient;
p34 chained work would have no final-digit margin, while p51 and p75 add unused
digits after the internal reducer has completed its wider work.

The spherical helper takes two angular-mode arguments. This is required for
valid inputs such as a degree azimuth and a gradian polar angle. The vector tag
format contains one angular unit, so a stored spherical vector retains its
existing single-unit display convention after conversion; both original tags
still control the numeric input conversion.

## Reverse conversion

Two-dimensional polar and cylindrical output use the completed p39 magnitude
and atan2 routes. Their established finite magnitude bound is below
`1.01E-38`, and the atan2 bound is below `7E-36` relative for a finite nonzero
angle, with the sharper `2.1E-37` bound in the cell centred on zero. Angular-unit
conversion adds p39 rounding without cancellation.

The three-dimensional radius uses the scaled p39 matrix Euclidean norm. For
three real elements the scale is an exact input magnitude. Each scaled ratio
and square contributes at most about `3u39`, two nonnegative additions add at
most `gamma_2`, the square root reduces the accumulated relative error by about
one half and adds `u39`, and the closing multiplication adds `u39`. A
conservative bound below `5u39` follows for a normal radius.

The spherical polar angle is now

```text
phi = atan2(sqrt(x*x + y*y), z)
```

instead of `acos(z/r)`. The former quotient loses the displacement from one
near either pole. For `[1,0,1E6144]`, p39 division gives `z/r=1`, followed by
`acos(1)=0`, although the Real34 result is `1E-6144` radians. The atan2 form
returns that value and has no subtraction from one. This is a conditioning
improvement rather than a wider-context workaround.

## Special values and exact axes

A finite zero magnitude in numeric input produces two positive zeros, matching
the public polar conversion convention even when the entered angle is not
finite. NaN magnitude or angle, or an infinite angle, otherwise produces NaN
components unless spherical geometry makes the azimuth irrelevant at an exact
pole. Infinite magnitude with a finite source-unit angle produces signed
infinities for nonzero factors and positive zero for an exact zero factor.

Spherical conversion first evaluates the polar angle. If its transverse radius
is exactly zero, `x` and `y` are set to positive zero without evaluating the
azimuth. This gives `[0,0,+infinity]` for an infinite radius, a zero polar angle,
and any azimuth, including infinity. Away from an exact spherical pole,
negative finite magnitudes retain the signs supplied by their component
products. Numeric input still parses the magnitude and angle to Real34 before
work, as required by the public entry format.

## Verification

The existing `reToCx.txt` file now drives `closeNimWithComplex` through a narrow
file-driven fixture. The existing `stkexV4.txt` file covers polar, cylindrical,
and spherical stack conversion, including mixed angle units, an exact pole,
negative magnitude, and the near-pole reverse case.

With the earlier source, every new wide-angle entry produced components
unrelated to the expected phase. With the source-angle changes, all 75 focused
checks succeeded. The near-pole reverse case separately returned zero with the
former `acos(z/r)` expression and `1E-6144` with the atan2 expression.

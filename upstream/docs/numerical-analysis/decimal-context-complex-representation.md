# Decimal contexts for complex representation conversion

## Scope and decisions

This analysis covers `Re->Cx` and `Cx->Re` for Real34 and Complex34 scalars
and matrices, including exact source-unit reduction for a long-integer polar
angle. Rectangular entry and exit copy stored components and need no arithmetic
context. Polar entry and exit use p39 until the single Real34 result conversion.

P39 is the narrowest useful intermediate context. A p34 trial passed the
retained ordinary polar-entry cases, but that result does not establish a
full final-digit margin for a trigonometric evaluation followed by a
multiplication. It also has no performance advantage: decQuad operands must
be unpacked into decNumber form and packed again, and a p34 chain can cost
more than its p39 counterpart. P34 is therefore reserved for the final
Real34 lattice and the selected public rounding mode.

The accepted p39-to-p34 boundary discrepancy is outside this analysis. P51
and p75 add no useful margin at the public boundary because the shared
trigonometric reducer and series already use their established wider
contexts.

## Polar entry

For magnitude `r` and angle `theta`, the finite result is

```text
x = r*cos(theta)
y = r*sin(theta).
```

The shared coordinate analysis bounds each nonzero component's p39 work
error by `1.01E-38` relative, plus a trigonometric series term below
`1.6E-46`. Near an axis the argument-reduction error supplies an absolute
bound instead. These bounds leave more than four decimal guard positions
before Real34 conversion.

The former entry path first converted the complete angle to radians at p39.
For a large angle, the absolute error in that multiplication grows with the
unreduced angle. For the exact Real34 input

```text
r = 1
theta = 1E6144 degrees,
```

integer reduction gives `10^6144 mod 360 = 280`. Independent 120-digit
evaluation gives

```text
cos(theta) =  0.173648177666930348851716626769314796...
sin(theta) = -0.984807753012208059366743024589523013...
```

The former path returned approximately `-0.3800032625` and
`-0.9249851461`. The revised entry gives the original angular unit to the
wide reducer, which performs the exact source-unit remainder before radians
are formed. Tagged angles take precedence over the current angular mode.

A long-integer polar angle uses the same exact source-unit reducer before any
Real34 conversion. The value `10^40+1` degrees therefore retains its exact
281-degree phase instead of being rounded to `10^40`, whose phase is 280
degrees.

A negative magnitude is multiplied into the two components directly. This
is algebraically equivalent to adding pi to the phase, without introducing
another reduction of a large angle. A zero magnitude gives two positive
zeros. An infinite magnitude maps nonzero direction components to signed
infinities while an exact zero direction remains positive zero. Scalar and
matrix entry use the same helper.

## Polar exit

For stored components `x` and `y`, the p39 path calculates

```text
r = sqrt(x^2 + y^2)
theta = atan2(y, x)
```

and then converts `theta` to the requested angular unit at p39. The completed
coordinate and atan2 analyses bound the magnitude error below `1.01E-38`
relative and the finite nonzero angle error below `7E-36` relative, with a
`2.1E-37` bound in the cell centred on zero. Unit conversion adds one p39
operation and the corresponding p39 constant error without cancellation.

The former `Cx->Re` path packed the radian angle into Real34 before unit
conversion, then unpacked it and packed the converted angle again. Besides
the conversion overhead, that intermediate Real34 rounding could change the
final result. For

```text
x = 3048008690445896896529848328311436
y = 9952312671413145870766573821977592,
```

independent high-precision evaluation gives the degree angle

```text
72.972198247502292860267574214176044528...
```

The former two-stage path returned
`72.97219824750229286026757421417606`; the p39 chain followed by one public
conversion returns `72.97219824750229286026757421417604`.

Axis, origin, infinity and NaN semantics remain those of the audited p39
magnitude and atan2 helpers. Rectangular exit remains an exact component
copy. Complex matrices use the same p39 polar kernel element by element.

## Verification

The existing `reToCx.txt` file now covers the Real34 exponent-limit degree
case in every rounding mode, tagged-angle precedence, negative and infinite
magnitudes, matrix entry, zero signs, exact long-integer phase, and exact
digit-34 checks for ordinary finite components. With the initial five new records, the former source
succeeded in 24 of 29 cases; the five wide-angle and sign cases failed. The
revised source succeeds in all 43 `Re->Cx` checks.

The existing `cxToRe.txt` file contains the two-stage-rounding discriminator.
Restoring the former path produced a scaled residual of `-2` and a focused
result of 52 successes from 53 checks. The revised combined focus succeeds
in all 53 checks. A clean repository run succeeds in all 17,800 checks with
zero GMP-owned bytes at exit. The build reports only the existing linker
section-alignment warning.

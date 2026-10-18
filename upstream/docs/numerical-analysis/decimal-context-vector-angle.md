# Decimal context analysis for real-vector angle

## Scope and result

This analysis covers the two- and three-dimensional Real34 matrix route for
the angle between two real vectors.  The result is written in the selected
angular unit as one Real34 value.

Use the stable identity

```text
theta = atan2(s, d),
d = x dot y,
s = magnitude(x cross y).
```

The cross components, cross magnitude, dot product, angle, and angular-unit
conversion use p39 as the primary working context.  The audited dot-product
accumulator selects p75 when cancellation removes more than twenty decimal
places.  One final conversion writes the Real34 result under the selected
rounding mode.

P39 is the narrowest useful primary context.  A single p34 operation is
cost-neutral, but this calculation chains products, residual corrections,
magnitudes, `atan2`, and unit conversion.  Chained p34 work can add Real34
unpack and repack operations, gives no speed benefit, and has neither the
needed error margin nor the work exponent range.  P51 and p75 are unnecessary
as the primary width; p75 remains the cancellation retry for the dot product.

## Conditioning of the formula

The previous formula calculated

```text
theta = acos(d/(magnitude(x)*magnitude(y))).
```

For a small angle,

```text
1-cos(theta) = theta^2/2 + O(theta^4).
```

The normalised dot product therefore rounds to one when the angle is much
smaller than the square root of the working unit roundoff.  More working
digits postpone this failure but do not remove its quadratic loss.  For
example, the exact angle between `[1,0]` and `[1,1E-100]` is
`atan(1E-100)`, which rounds to `1E-100` in Real34.  The normalised-dot formula
returns zero even with p75 arithmetic.

The `atan2` formula retains the first-order cross product.  If finite computed
values satisfy

```text
computed s = s*(1+delta_s),
computed d = d*(1+delta_d),
```

then the angle differential is

```text
d theta = (d*d s - s*d d)/(d^2+s^2).
```

Consequently, relative errors in `s` and `d` contribute at most
`(|delta_s|+|delta_d|)/2` radians.  Near zero, the stable ratio `s/d` preserves
relative accuracy.  Near `pi/2`, an absolute angle bound is appropriate and
the cancellation retry protects the small dot product.  Near `pi`, the cross
magnitude retains the distance from the negative axis while `atan2` selects
the correct quadrant.

## Cross product and magnitude

Each two-product determinant is evaluated through the p39 compensated kernel

```text
q = RN39(a*b)
t = RN39(c*d-q)
e = FMA(a,b,-q)
r = RN39(t-e).
```

A product of two Real34 coefficients has at most 68 digits.  Its residual
after a p39 product has at most 29 digits, so the fused residual is exact at
p39.  The established even-radix compensated-product bound is

```text
|r-(c*d-a*b)| <= 2*u39*|c*d-a*b|,
u39 = 5E-39.
```

Thus every nonzero cross component has relative error at most `1E-38`, and an
exact component zero remains exact.  P39's extended exponent range contains
every product of two finite Real34 components.

The two-dimensional route takes the magnitude of its single determinant.  The
three-dimensional route applies the audited p39 complex-magnitude kernel
twice to the three compensated components.  One magnitude application has
relative error below `1.01E-38`.  Combining the component and nested-magnitude
bounds gives the conservative result

```text
|computed s-s|/s < 4.1E-38
```

for a finite nonzero cross magnitude.  A small angle beside a maximum-exponent
component therefore remains visible.  The file-driven case
`[1E6144,0,0]` and `[1E6144,1E6044,0]` returns `1E-100` radians rather than
zero.

## Dot product

The dot product uses the audited magnitude-ordered two-term accumulator.  Each
Real34 product is decomposed into a rounded high part and an exact fused low
part.  At p39, its forward bound for `m` floating summands is

```text
|computed d-d| <= u39*|d| + (3*m^2/4+m)*u39^2*A,
A = sum(abs(product_j)).
```

Here `m` is at most six.  If the exponent difference between `A` and the
result exceeds twenty, or a nonzero `A` produces zero, the dot product is
recomputed at p75.  The p75 route represents each Real34 product exactly and
protects cancellation between the two or three products.  As with every fixed
width, a uniform relative result cannot be promised for every exponent-
separated cancellation available in the complete Real34 range.  This
limitation affects a dot result arbitrarily close to zero; its contribution to
the angle retains an absolute qualification there.

## Atan2 and final conversion

The p39 `atan2` dependency has a conservative absolute error below `3E-37`
radians outside its zero-centred table cell and relative error below
`2.1E-37` inside that cell.  The p39 angular-unit conversion adds only stable
multiplication or division by a p39 constant.  The angle stays wide until this
conversion is complete.

The final Real34 conversion is one p34 result operation and is cost-neutral.
It applies half-even, half-up, half-down, away from zero, toward zero, ceiling,
or floor as selected by the user.  This analysis claims faithful 34-digit
accuracy rather than universal correct rounding.  Differences confined to an
accepted p39-to-p34 boundary are excluded.

At p34, the compensated cross-component bound is `1E-33`, leaving no full
output-digit margin.  Its decimal128 exponent range also permits intermediate
product overflow before a finite angle is formed.  A deliberate p34 mutation
succeeds in 19 of 21 exact rounding-mode checks; the ceiling and floor results
differ by one Real34 unit after amplification.  P39 succeeds in all 21.

## Domains and verification

Only equal-length two- and three-dimensional real vectors are accepted.  A
zero vector makes both `s` and `d` zero and returns NaN.  A NaN or infinite
component also returns NaN.  These classifications match an undefined finite
Euclidean angle and avoid indeterminate infinity products.

For

```text
N = 12345678901234567,
y = [N,N-1],
x = [N+1,N],
```

integer arithmetic gives

```text
magnitude(y cross x) = 1,
y dot x = 2*N^2,
theta = atan(1/(2*N^2)).
```

The positive ratio begins

```text
3.280500059049001276114522497669392833...E-33.
```

The cubic difference between this ratio and its arctangent is below `1.2E-97`,
so it cannot affect the displayed Real34 value.  Existing file-driven tests
assert the result under all seven rounding modes by subtracting the expected
34-digit value and scaling the residual by `1E70`.

With the three initial stability cases added, the former implementation
succeeds in 224 of 227 matrix checks; the two small-angle cases and the
maximum-exponent case return zero.  The revised implementation succeeds in
all 247 expanded matrix checks.  A C47 simulator run constructed both Pell
vectors through the public vector-entry command, invoked the catalogue vector
angle by name, and displayed
`3.280500059049001276114522497669393E-33` radians.

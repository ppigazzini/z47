# Decimal context for real and complex arcsine

## Scope and result

This analysis covers the public real34 and complex34 arcsine routes in `arcsin.c`, `C47_WP34S_Asin`, the shared finite-component calculation, and elementwise real
and complex matrices. The direct numerical dependencies are `C47_WP34S_Atan2` and `WP34S_ArcSinh`.

| Calculation | Former context | Selected context | Result |
| --- | ---: | ---: | --- |
| finite scalar | 39 | 39 | factored endpoint distance and one `atan2` replace a square-first half-angle formula |
| finite complex components | 39 | 39 | a direct component decomposition replaces complex square root and logarithm cancellation |
| matrix elements | 39 | 39 | each element uses the corresponding scalar calculation |

The p39 context is the narrowest established context that has both a 34-digit accuracy margin and enough exponent range for all complex squares. The result has
faithful 34-digit accuracy. Universal correctly rounded decimal128 output after the final p39-to-p34 conversion is not claimed, and differences confined to that
conversion are outside this analysis.

Intermediate work uses round-to-nearest, ties-to-even. Conversion to real34 uses the calculator's selected rounding mode.

## Scalar formula and endpoint error

For `|x|<=1`, the revised scalar helper evaluates

```text
c = sqrt((1-|x|)*(1+|x|))
asin(x) = atan2(x,c).
```

The two factors are exact at p39 for a real34 input. Their product has relative error at most `u39=5e-39`, and the correctly rounded square root gives

```text
|computed c-c|/c < 1.51*u39.
```

This remains valid for the decimal128 values adjacent to either endpoint. The square-first expression `1-x*x` instead has an absolute product error of order `u39`.
When `1-|x|` is near `1e-20`, that error is magnified by subtraction and the square root. For the tested input, the former scalar arcsine has absolute error
`3.53e-31` radians and the corresponding arccosine has only 20 correct significant digits.

For a relative perturbation `delta` in `c`, angle sensitivity gives

```text
|d asin(x)| = |x*c|/(x^2+c^2) * |delta| <= |delta|/2.
```

Near zero, the relative condition factor tends to one. Near either endpoint, arcsine is order one and the displayed absolute bound applies. Adding the established
p39 `atan2` bound gives an absolute error below `3.1e-37` radians outside the table cell centred on zero and a relative error below `2.2e-37` inside that cell.
Conversion to degrees, gradians, or multiples of pi introduces no subtractive cancellation and preserves the stated relative margin.

A p34 calculation has no guard digit for the product, square root, `atan2`, or angular conversion. The p39 context is therefore the narrowest established width for
the scalar result.

## Stable complex decomposition

Write

```text
z = x+i*y
asin(z) = a+i*b,
```

where `-pi/2<=a<=pi/2`. Expanding `sin(a+i*b)` gives

```text
x = sin(a)*cosh(b)
y = cos(a)*sinh(b).
```

Set `t=sinh(b)^2` and `q=x^2+y^2-1`. Eliminating the angle gives

```text
t^2-q*t-y^2 = 0
d = sqrt(q^2+4*y^2).
```

The nonnegative root uses one of two equal forms:

```text
t = (q+d)/2             when q >= 0
t = 2*y^2/(d-q)         when q < 0.
```

The second form avoids cancellation between `q` and `d`. The component magnitudes then follow from

```text
b = sign(y)*asinh(sqrt(t))
a = atan2(x*sqrt(t), |y|*sqrt(1+t))       when t > 0.
```

Both angle arguments have the same omitted positive scale. When `t=0`, the input is on the finite real segment and the angle becomes

```text
a = atan2(x, sqrt((1-|x|)*(1+|x|))).
```

This path neither forms `1-z^2` as a rectangular complex value nor takes a complex logarithm. It avoids loss of a square-root-sized component near `z=+/-1`, avoids
loss of a small real component when `|x|` is large, and remains finite throughout the real34 exponent range.

## Error in the complex components

The calculation forms

```text
h = (|x|-1)*(|x|+1)
q = y^2+h.
```

The factors in `h` are exact at p39 for real34 input. With `Y=y^2`, sensitivity of the positive root follows from `t^2-(Y+h)t-Y=0`:

```text
d(log(t)) = Y*(t+1)/(t*d) * d(log(Y)) + h/d * d(log(|h|)).
```

The first coefficient has magnitude at most one because `Y=t*cos(a)^2<=t`. The second has magnitude at most one because

```text
d^2-h^2 = Y*(Y+2*h+4) >= 0,  h >= -1.
```

Cancellation while adding `Y+h` does not amplify the root error. If `h>=0`, then `Y+h<=d`; if `h<0`, then

```text
d^2-(Y+|h|)^2 = 4*x^2*Y >= 0.
```

Thus the total magnitude entering the addition is no greater than `d`, the derivative denominator. Accounting for the two initial products, two fused additions,
square root, selected root expression, and first-order propagation gives

```text
|computed t-t|/t < 20*u39 = 1e-37
```

for nonzero `t`. The next square root contributes less than `11*u39` relatively. The audited p39 inverse-hyperbolic-sine helper has relative error below `1.2e-36`,
and its relative condition factor is at most one. Consequently every nonzero finite imaginary component satisfies

```text
|computed b-b|/|b| < 1.3e-36.
```

For `t>0`, each nonzero angle argument has relative perturbation below `6e-38`. If their relative perturbations are `deltaN` and `deltaD`, then

```text
|delta a| <= |sin(a)*cos(a)|*(|deltaN|+|deltaD|)
          <= (|deltaN|+|deltaD|)/2.
```

Combining this with p39 `atan2` gives absolute error below `3.7e-37` radians outside its zero-centred table cell. In that cell the sharper `atan2` result gives relative
error below `3.4e-37`. The `t=0` factored expression has the scalar endpoint bound.

## Range, cuts, and special values

A finite real34 component has adjusted exponent from `-6176` through `6144`. The largest intermediate is `q^2`, with adjusted exponent no greater than about `24576`.
The smallest nonzero square has adjusted exponent near `-12352`. Every intermediate fits the `+/-999999` p39 exponent range. A p34 context can overflow or underflow
while forming a component square, before precision is considered.

The shared component calculation applies these special values and established cut choices:

- A NaN component produces two NaN components.
- Infinite `x` with finite `y` produces `sign(x)*pi/2` and an infinity signed from `y`.
- Finite `x` with infinite `y` produces a zero signed from `x` and an infinity signed from `y`.
- Two infinite components produce `sign(x)*pi/4` and an infinity signed from `y`.
- On either real-axis cut, an exact zero imaginary component retains the established real continuation: positive real input uses the lower shore and negative real
  input uses the upper shore. The sign of that exact zero does not change the result.
- Exact signed origins and endpoint zero components keep their signs.

A real input outside `[-1,1]` uses the same continuation. Complex arcsine is dimensionless and its imaginary component remains independent of angular mode.

Real matrices use the scalar route for each element. Complex matrices use the shared component calculation. Matrix processing adds no numerical operation after each
element's final real34 conversion.

## Independent values and verification

An independent 280-digit decimal calculation used a Machin expression for pi, a direct power series for reduced arctangent, decimal square root, and the defining
complex logarithm for moderate inputs. A separately derived component evaluation covered large exponent separations. Representative values are

```text
asin(0.9999999999999999999900158109407330)
  = 1.57079632665358710745474665134764953677916604456079...

asin(1+i*1e-50)
  = 1.57079632679489661923132159163975144209858469968755...
    + i*1.0000000000000000000000000000000000000000000000000008333...e-25

asin(1e100+i)
  = 1.57079632679489661923132169163975144209858469968755...
    + i*230.951656479964513711216377589894597328185648997237...
```

The file-driven cases cover all seven result rounding modes, values near an endpoint, square-root-sized complex components, large exponent separations, exact cut
values, infinities, NaNs, and real and complex matrices. With the earlier source, 96 of 117 focused arcsine and arccosine cases succeeded. The revised source
succeeds in all 117 focused cases.

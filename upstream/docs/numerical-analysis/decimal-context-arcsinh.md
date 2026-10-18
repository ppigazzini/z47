# Decimal context analysis for inverse hyperbolic sine

## Scope and result

This analysis covers the scalar and complex decimal128 routes in `arcsinh.c`, the shared `WP34S_ArcSinh` helper, and real and complex matrix entry through
`processRealComplexMonadicFunction`. The direct numerical dependencies are `WP34S_Ln1P` and `C47_WP34S_Atan2`.

| Calculation | Former context | Selected context | Result |
| --- | ---: | ---: | --- |
| finite scalar | 51 | 39 | odd evaluation removes large-negative cancellation |
| finite complex components | 39 | 39 | a direct component decomposition removes cancellation in the complex logarithm |
| real and complex matrix elements | 51 or 39 | 39 | every decimal128 element uses the corresponding scalar calculation |

The 39-digit context is the narrowest established context with a defensible 34-digit margin and enough exponent range for all intermediate squares. The result has
faithful 34-digit accuracy. Universal correctly rounded decimal128 output after the final 39-to-34 conversion is not claimed, and differences confined to that
conversion are outside this analysis.

The fixed work mode is round-to-nearest, ties-to-even. Conversion to decimal128 applies the selected calculator mode.

## Scalar formula

For `a=|x|`, the revised helper evaluates

```text
s = sqrt(1+a^2)
w = a * (1 + a/(s+1))
asinh(x) = sign(x) * log1p(w).
```

The identity follows from

```text
a^2/(sqrt(1+a^2)+1) = sqrt(1+a^2)-1.
```

Thus `w=a+sqrt(1+a^2)-1`, and `log1p(w)=log(a+sqrt(1+a^2))`. Every finite arithmetic step before `log1p` uses nonnegative operands. In particular, the formula
does not add a negative `x` to `sqrt(1+x^2)-1`. The previous formula did so and returned zero for `x=-1e100` and for large negative decimal128 values.

For tiny `a`, an addition may round `sqrt(1+a^2)` to one and may round `1+a/(s+1)` to one. The resulting `w=a` differs from the exact transformed argument by
`O(a^2)`. The compensated `WP34S_Ln1P` shortcut returns `a` if `1+a` rounds to one, with relative error below `2.6e-39` at p39.

Let `u39=5e-39`. The fused square addition, square root, positive addition, division, positive addition, and multiplication perturb the nonzero `w` by less than
`6u39` relatively, apart from second-order terms. The relative condition factor for a relative perturbation of `w` is

```text
w / ((1+w)*log(1+w)) <= 1.
```

The audited p39 logarithm arithmetic contributes less than `9.1e-37` before a small allowance for its compensation operations. A conservative bound for the complete
scalar calculation is

```text
|computed asinh(x)-asinh(x)| / |asinh(x)| < 1.2e-36
```

for finite nonzero decimal128 `x`. Exact zero uses a separate branch so that its sign is retained. Infinities and NaNs are copied without finite arithmetic.

At p34 the logarithm operation count alone permits an error near `9.1e-32`, with no 34-digit margin. The p39 context is therefore the narrowest established choice.
The former p51 context adds twelve digits beyond the selected width without correcting the sign-dependent cancellation.

## Complex decomposition

Write

```text
z = x+i*y
asinh(z) = u+i*v
```

on the principal branch, where `u` is real and `-pi/2 <= v <= pi/2`. Expanding `sinh(u+i*v)` gives

```text
x = sinh(u)*cos(v)
y = cosh(u)*sin(v).
```

Set `t=sinh(u)^2` and `q=x^2+y^2-1`. Eliminating `v` gives

```text
t^2-q*t-x^2 = 0
d = sqrt(q^2+4*x^2).
```

The nonnegative root is evaluated by one of two algebraically equal forms:

```text
t = (q+d)/2             when q >= 0
t = 2*x^2/(d-q)         when q < 0.
```

The second form avoids cancellation between `q` and `d`. The real component is then

```text
u = sign(x)*asinh(sqrt(t)).
```

For `t>0`, both arguments of the angle calculation share the omitted positive scale factor:

```text
v = atan2(y*sqrt(t), |x|*sqrt(1+t)).
```

When `t=0`, the input is on the finite imaginary segment and the formula becomes

```text
v = atan2(y, sqrt((1-|y|)*(1+|y|))).
```

The factored products retain distances from both branch points. No complex square root, rectangular-to-polar conversion, or complex logarithm is needed.

## Error in the nonnegative root

The calculation forms

```text
h = (|y|-1)(|y|+1)
q = x^2+h.
```

Both factors in `h` are exact at p39 for a decimal128 input before their product is rounded. Let `X=x^2`. Sensitivity of the positive root follows by
differentiating `t^2-(X+h)t-X=0`:

```text
d(log(t)) = X*(t+1)/(t*d) * d(log(X)) + h/d * d(log(|h|)).
```

The first coefficient has magnitude at most one because `X=t*cos(v)^2 <= t`. The second also has magnitude at most one because

```text
d^2-h^2 = X*(X+2*h+4) >= 0,  h >= -1.
```

Rounding `q` after cancellation is also benign. Its absolute error affects `t` by the factor `1/d`. If `h>=0`, then `X+h<=d`. If `h<0`, then

```text
d^2-(X+|h|)^2 = 4*y^2*X >= 0.
```

Consequently the total magnitude of the terms that form `q` is no greater than `d`. Cancellation in `q` cannot amplify a p39 product error in `t`.

The calculation of `d` is a fused addition of the nonnegative terms `q^2` and `4X`, followed by a correctly rounded square root. The selected expression for
`t` then uses operands of the same sign. Direct accounting for the two initial products, fused additions, square root, selected root expression, and their
first-order propagation gives

```text
|computed t-t|/t < 20*u39 = 1e-37
```

for nonzero `t`. Exact `t=0` arises only on the finite imaginary segment and uses the separate angle expression.

The square root of `t` adds less than one further unit roundoff plus half the relative `t` error. The scalar `asinh` condition factor

```text
s / (sqrt(1+s^2)*asinh(s)) <= 1
```

does not amplify that perturbation. Including the scalar-helper bound gives

```text
|computed u-u|/|u| < 1.3e-36
```

for every nonzero finite real component.

## Error in the angle

For `t>0`, write `N=y*sqrt(t)` and `D=|x|*sqrt(1+t)`. The root bound gives relative perturbations below `6e-38` in each nonzero angle input. For relative
perturbations `deltaN` and `deltaD`,

```text
|delta v| <= |sin(v)*cos(v)|*(|deltaN|+|deltaD|)
           <= (|deltaN|+|deltaD|)/2.
```

The established p39 `atan2` bound is below `3e-37` radians outside its zero-centred table cell. The complete ordinary angle calculation therefore has absolute
error below `3.7e-37` radians. In the zero-centred cell, the `atan2` relative bound and the input perturbations give relative error below `3.4e-37`.

For `t=0`, the product `(1-|y|)(1+|y|)` has no subtractive cancellation after the exact first factor. Its square-root perturbation changes the angle by at most
half that relative perturbation. The same `3.7e-37` absolute bound applies, including decimal128 inputs adjacent to `y=+/-1`.

## Range and branch behaviour

A finite decimal128 component has adjusted exponent from `-6176` through `6144`. The largest intermediate is `q^2`, whose adjusted exponent is at most about
`24576`. The smallest nonzero square has adjusted exponent about `-12352`. Every intermediate fits the `+/-999999` exponent range of `ctxtReal39`.

`ctxtReal34` uses the decimal128 exponent range. It can overflow or underflow while forming `x^2`, before any precision argument is considered. The p39 context is
therefore the narrowest established context for both precision and range.

The explicit special branches implement these principal values:

- A NaN component returns two NaN components.
- Infinite `x` with finite `y` returns signed infinity for the real component and a zero signed from `y`.
- Finite `x` with infinite `y` returns an infinity signed from `x` and `+/-pi/2` signed from `y`.
- Two infinite components return an infinity signed from `x` and `+/-pi/4` signed from `y`.
- Signed real zero selects the side of each imaginary-axis cut outside `[-i,i]`.
- Signed origins and the exact branch points retain their zero components.

Complex inverse hyperbolic sine is dimensionless and returns its imaginary component in radians. Matrix processing places each decimal128 element through the same
scalar register route, so it introduces no extra numerical stage.

## Independent values and verification

An independent 220-digit decimal computation used the defining complex logarithm and square root for moderate inputs. A separately derived atan series, with Machin's
formula for pi, evaluated the component decomposition at large exponent separations. Representative values are

```text
asinh(-1e100)
  = -230.951656479964513711216377589894597328185648997237...

asinh(1e-50+i)
  = 1.0000000000000000000000000000000000000000000000000008333...e-25
    + i*1.570796326794896619231321591639751442098584699687...

asinh(-1e100+i)
  = -230.951656479964513711216377589894597328185648997237...
    + i*9.999999999999999999999999999999999999999999999999...e-101

asinh(+0+2i)
  = 1.316957896924816708625046347307968444026981971467...
    + i*1.570796326794896619231321691639751442098584699687...
```

For `x=1e-6176` and `y=0.5`, the first-order real component is
`2e-6176/sqrt(3)=1.154700538379251529018297561003914911...e-6176`; omitted terms are far below the decimal128 range.

The file-driven cases cover all seven rounding modes, signed zeros, both branch points and cut sides, both decimal128 exponent limits, infinities, NaNs, and real and
complex matrices. With the former source, the focused file succeeded in 52 of 72 cases. It lost large negative scalar values, tiny complex real components, cut-side
signs, and principal infinite values. The revised source succeeds in all 72 focused cases.

# Decimal context for real and complex arccosine

## Scope and result

This analysis covers the public real34 and complex34 arccosine routes in `arccos.c`, `C47_WP34S_Acos`, the component calculation shared with arcsine, and elementwise
real and complex matrices. The direct numerical dependencies are `C47_WP34S_Atan2` and `WP34S_ArcSinh`.

Both scalar and complex work use p39. It is the narrowest established context with a 34-digit accuracy margin. For the complex path it is also the narrowest existing
context whose exponent range contains every square of a finite real34 component. The results have faithful 34-digit accuracy. Universal correctly rounded output after
the p39-to-p34 conversion is not claimed, and differences confined to that conversion are outside this analysis.

## Scalar endpoint formula

For `|x|<=1`, the revised helper evaluates

```text
c = sqrt((1-|x|)*(1+|x|))
acos(x) = atan2(c,x).
```

This direct angle is in `[0,pi]`. It does not subtract an arcsine result from `pi/2`, so the small result near `x=1` is evaluated as a small `atan2` angle. It also
does not divide by `c`, and exact `x=+1` and `x=-1` use the ordinary signed-axis rules of `atan2`.

For real34 input the two factors are exact at p39. Their product and correctly rounded square root give relative error below `1.51*u39`, where `u39=5e-39`. A relative
perturbation `delta` in `c` changes the angle by

```text
|d acos(x)| = |x*c|/(x^2+c^2) * |delta| <= |delta|/2.
```

Near `x=1`, the angle is proportional to `c`, so its relative perturbation is below `1.51*u39`. The zero-centred p39 `atan2` bound gives total relative error below
`2.2e-37`. Elsewhere, its absolute error is below `3.1e-37` radians. The same margin applies after angular-mode conversion.

The square-first expression `1-x*x` can lose about five significant digits when a real34 input is adjacent to one. The factored formula removes that endpoint loss.
A p34 route has no guard digit through product, square root, `atan2`, and angular conversion, so p39 is the narrowest established scalar context.

## Direct complex complement

For

```text
asin(x+i*y) = a+i*b,
```

principal arccosine is `pi/2-a-i*b`. Computing the real component by subtracting from `pi/2` is unstable when `a` is close to `pi/2`, including inputs near `+1` and
large positive real components. The implementation instead evaluates the complementary angle directly.

The shared decomposition sets `t=sinh(b)^2`, `q=x^2+y^2-1`, and

```text
d = sqrt(q^2+4*y^2)
t = (q+d)/2             when q >= 0
t = 2*y^2/(d-q)         when q < 0.
```

For `t>0`, define

```text
N = x*sqrt(t)
D = |y|*sqrt(1+t).
```

The arcsine angle is `atan2(N,D)`. Since `D>=0`, its complement on `[0,pi]` is obtained without subtraction:

```text
Re(acos(x+i*y)) = atan2(D,N)
Im(acos(x+i*y)) = -sign(y)*asinh(sqrt(t)).
```

When `t=0`, the input is on the real segment and the direct expression is

```text
Re(acos(x+i*y)) = atan2(sqrt((1-|x|)*(1+|x|)),x).
```

This preserves a real component of order `1e-100` for `acos(1e100+i)`. Subtraction from a p39 `pi/2` value can instead leave an error of order `1e-39`, sixty-one
decimal orders larger than the result.

## Complex error and context width

The companion arcsine analysis derives the positive-root bound

```text
|computed t-t|/t < 20*u39 = 1e-37
```

for every nonzero finite `t`. It follows from exact endpoint factors, stable selection of the quadratic-root expression, and coefficients no greater than one in the
root sensitivity. The square root of `t` has relative error below `11*u39`. Applying the p39 inverse-hyperbolic-sine bound gives

```text
|computed Im(acos)-Im(acos)|/|Im(acos)| < 1.3e-36
```

for every nonzero finite imaginary component.

Each nonzero input to the complementary `atan2` has relative perturbation below `6e-38`. Angle sensitivity contributes less than `6e-38` radians before the audited
`atan2` error. The complete real-component error is below `3.7e-37` radians outside the table cell centred on zero. Near a zero real component, including values close
to `+1` and large positive real coordinates, the sharper relative bound is below `3.4e-37`.

The p39 work exponent range contains component squares with adjusted exponents near `-12352` through `12288` and the subsequent `q^2` range near `+/-24576`.
A p34 context can overflow or underflow during these intermediates. P51 and p75 add digits beyond the proven margin without improving the conditioning of either
component, so p39 is selected.

## Cuts, special values, and matrices

The shared special branches give these special values and established cut choices:

- A NaN component produces two NaN components.
- Infinite `x` with finite `y` produces zero or pi according to the sign of `x`, with an infinity oppositely signed from `y`.
- Finite `x` with infinite `y` produces `pi/2`, with an infinity oppositely signed from `y`.
- Two infinite components produce `pi/4` or `3*pi/4` according to the sign of `x`, with an infinity oppositely signed from `y`.
- On either real-axis cut, an exact zero imaginary component retains the established real continuation: positive real input has positive imaginary result and negative
  real input has negative imaginary result. The sign of that exact zero does not change the result.
- Exact origins and endpoints preserve the required signed zero components.

For a real input outside `[-1,1]`, the complex-result path uses the same continuation. Complex arccosine is dimensionless and does not use the selected angular mode.

Real matrices apply the scalar helper to each element. Complex matrices apply the shared component calculation. No additional matrix arithmetic follows the element
conversion to real34.

## Independent values and verification

Independent 280-digit decimal arithmetic used a Machin expression for pi, reduced arctangent series, decimal square root, and the defining complex logarithm for
moderate inputs. A separately derived component calculation supplied references across large exponent separations. Representative values are

```text
acos(0.9999999999999999999900158109407330)
  = 1.41309511776575040292101905319418655126766077017278...e-10

acos(1+i*1e-50)
  = 9.9999999999999999999999999999999999999999999999999916666...e-26
    - i*1.0000000000000000000000000000000000000000000000000008333...e-25

acos(1e100+i)
  = 9.999999999999999999999999999999999999999999999999...e-101
    - i*230.951656479964513711216377589894597328185648997237...
```

The file-driven cases exercise every result rounding mode, endpoint-adjacent values, direct complementary angles, exact cut values, wide exponent separation,
infinities, NaNs, and real and complex matrices. The earlier implementation succeeded in 96 of the 117 combined focused cases. The revised implementation succeeds
in all 117.

# Decimal context analysis for sine and cosine

## Scope

This analysis covers the shared sine/cosine angle reducer and Taylor series and the public scalar, complex, and matrix entry points. The complex conclusion uses the completed analyses of hyperbolic sine and cosine and correctly rounded multiplication.

The analysis treats the accepted 39-to-34-digit boundary effect as out of scope.

## Recommendations

Use the selected 34-digit context for the public scalar result and the fixed 39-digit context for a direct complex Real34 input. Before a scalar or complex trigonometric factor is rounded to its caller's width, use these internal widths:

- 12,321 digits for reduction of radians on builds with sufficient memory;
- 75 digits for source-unit conversion and the reduced radian argument;
- 51 digits for the sine and cosine Taylor series.

The public complex route needs no 51- or 75-digit closing product. The reusable `sinComplex` and `cosComplex` helpers continue to use the supplied context so wider elliptic and special-function callers keep their requested width.

## Radian reduction

A decimal128 complex component can have adjusted exponent 6,144. Write a positive input as

```text
x = q(2*pi) + r,  0 <= r < 2*pi.
```

The largest possible quotient is less than `1.6E6143`. A `p`-digit stored value of `2*pi` has absolute error at most `5E(1-p)`, so its contribution to the reduced phase is bounded by

```text
1.6E6143 * 5E(1-p).
```

At `p=6147` this can be about `8E-3`. It is therefore not an accuracy-preserving reduction for the complete decimal128 exponent range. At `p=12321` the bound is below `8E-6178`, less than one tenth of the minimum decimal128 subnormal unit.

The previous reducer shortened the remainder before quadrant subtraction. That can lose most of a small phase even when the stored `2*pi` value is long enough. For the valid scalar-radian input

```text
5.075769612216191749472115895925863E999
```

the true centred phase is

```text
-2.029767486356259219375295526031457...E-34.
```

Shortening the remainder to 51 digits before subtracting its quadrant retained only about 17 correct phase digits.

The revised reducer keeps the remainder at 12,321 digits while it identifies the quadrant and folds the residual into `[0, pi/4]`. Multiplication by four identifies the quadrant using at most three subtractions of `2*pi`. A further doubling and reflection folds the upper half of that quadrant. Division by eight then shortens the already small angle to 75 digits. This order avoids cancellation after shortening.

On the original DM42 hardware the temporary is limited to 2,139 digits by available memory. This is sufficient for scalar radians and the existing 1,000-digit long-integer limit, but not for the most extreme complex decimal128 components. Other builds use the 12,321-digit path.

## Taylor series

After reduction, `0 <= a <= pi/4`. The kernel evaluates

```text
cos(a) = 1 - a^2/2! + a^4/4! - ...
sin(a) = a(1 - a^2/3! + a^4/5! - ...).
```

Both series are alternating with decreasing terms. The absolute-term sum for cosine is at most `cosh(pi/4) < 1.325`, while the result is at least `sqrt(2)/2`. The corresponding ratio for `sin(a)/a` is smaller. Thus cancellation in the first-octant series is bounded.

For directed rounding, use `u51=1E-50`; for a nearest mode the bound is half as large. Even the implementation limit of 1,000 iterations uses fewer than 8,005 rounded elementary operations. The standard product bound therefore gives

```text
gamma_8005 < 8.01E-47.
```

Including the absolute-term ratio gives less than `1.6E-46` relative arithmetic error for either nonzero series result. The equality termination adds less than one 51-digit ulp of truncation error: under a directed mode, an unchanged addition occurs on the side whose omitted alternating tail remains within that ulp. The final multiplication by `a` adds one more 51-digit rounding for sine.

Consequently the 51-digit series retains more than eleven decimal guard digits before conversion to decimal128. A 34-digit series would have no such margin. Precision 51 is the narrowest existing fixed context established for this stage; precision 75 is unnecessary after the wide reduction has produced the first-octant angle.

## Scalar result context

The helper restores the caller's context only after the 51-digit series. A final unary plus then applies the selected output mode at 34 digits. No further transcendental work uses the shortened value. Exact subtraction and scaling for `sin(0.3)` verifies all seven output modes through digit 34; `cos(0.3)` provides an independent exact last-digit check.

Special inputs retain the existing behavior. Scalar infinities produce NaN, signed zeros are normalized by the shared kernel, and exact degree, gradian, DMS, and multiple-of-pi reductions continue to use their source units before conversion to radians.

## Complex result context

For `z=a+ib`, the two functions use

```text
sin(z) = sin(a) cosh(b) + i cos(a) sinh(b),
cos(z) = cos(a) cosh(b) - i sin(a) sinh(b).
```

Each component is one product. No addition or subtraction combines large opposing terms. The completed hyperbolic analysis bounds the p39 relative error of each finite nonzero hyperbolic factor below `4E-38`. The trigonometric series contributes less than `1.6E-46` before its p39 result rounding. With the fixed half-even p39 context, each factor rounding and the final correctly rounded multiplication contribute at most `u39=5E-39`. Thus, apart from the separately bounded absolute phase-reduction error, the relative component error is less than

```text
4E-38 + 2u39 + 1.6E-46 + second-order terms < 5.1E-38.
```

This leaves more than three decimal guard digits before the final Real34 conversion. When a trigonometric component is close to zero, the angle-reduction analysis supplies an absolute error bound and multiplication by the hyperbolic factor supplies the corresponding component bound. The original DM42 reduction-width exception described above also applies to these complex components at extreme exponents.

P34 is too narrow for the public complex work. With all other changes present, a deliberate p34 mutation fails every exact `sin(0.3+0.4i)` check across the seven rounding modes and four directed-mode `cos(0.3+0.4i)` checks. The residuals after scaling by `1E40` range from `1E6` to `1E7`, which corresponds to one to ten Real34 units before scaling. P39 succeeds in every mode. The selected mode is applied only when each p39 component is converted to Real34, so directed work rounding does not perturb either transcendental helper.

Real and complex matrices use the same scalar and complex entry functions for each element.

## Infinite factors

The identity formulas have well-defined exact zero components when either factor is zero, including a zero multiplied by an infinite or NaN factor from the other component. Decimal multiplication instead returns NaN for those special products. The closing product now returns the signed zero first. For the remaining infinite-hyperbolic cases, a NaN trigonometric factor returns NaN and a finite nonzero factor returns the signed infinity. This covers infinite and NaN inputs and a finite imaginary input whose hyperbolic value exceeds the p39 exponent range.

## Complex adversary

For

```text
x = 5.829979800222281883747164188135449E6144
```

the centred phase is

```text
-2.908962159350783229012734764285262...E-34.
```

With the former 6,147-digit constant, `sin(x+0i)` had real component approximately `4.8598095E-4`, and `cos(x+0i)` was approximately `0.9999998819`. The revised reduction gives the expected decimal128 sine component and rounds the cosine component to one.

## Tests

The cases are in the existing `sin.txt` and `cos.txt` file-driven suites. They cover the scalar exponent limit, the complete complex decimal128 exponent range, all scalar and complex sine output modes through digit 34, all complex cosine output modes through digit 34, ordinary real and complex matrices, and special hyperbolic factors with exact zero components.

With the final cases present, the former public complex route succeeds in 122 of 134 focused checks; all twelve failures are exact zero components returned as NaN. The p34 complex experiment with the special-value correction succeeds in 123 of 134. The p39 route succeeds in all 134 focused checks, and the complete suite succeeds in all 14,990 checks.

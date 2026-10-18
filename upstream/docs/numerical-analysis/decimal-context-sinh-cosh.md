# Decimal context analysis for hyperbolic sine and cosine

## Scope

This analysis covers `WP34S_SinhCosh` and the public real, complex, and matrix paths for `sinh` and `cosh`. The shared helper also serves elliptic, logistic, integration, sine, cosine, and sinc-related code. Those callers may supply a wider context and continue to receive that width.

The accepted 39-to-34-digit boundary effect is outside this analysis.

## Recommendation

Retain 39 digits for direct scalar and complex Real34 evaluation. This is the narrowest established context among 34, 39, 51, and 75 digits. The 51- and 75-digit contexts do not improve the final Real34 result enough to justify their cost on these direct paths.

`WP34S_SinhCosh` must continue to use its caller-supplied context. Wider callers depend on that property.

A single p34 operation has no extra cost. These formulas form chains of at least five arithmetic operations, however, and p34 can add unpack and repack work between those operations. The accuracy experiments already exclude p34, independently of execution cost. P39 supplies the required guard margin without a p34 arithmetic chain.

## Scalar formulas

For `|x| < 1/2`, the helper evaluates

```text
w       = expm1(x)
sinh(x) = w(w+2) / (2(w+1)).
```

This avoids subtracting two values near one. On the selected interval, `w` lies between `exp(-1/2)-1` and `exp(1/2)-1`. The relative condition of the formula with respect to `w` is

```text
1 - w / ((w+1)(w+2)),
```

whose magnitude is below 1.405. The additions have positive results bounded away from zero. Apart from `WP34S_ExpM1`, this path uses five elementary operations. Their first-order p39 contribution is below `5u39`, where `u39=5E-39`. Combining the 1.405 sensitivity with the separate `expm1` bound leaves more than two decimal guard digits beyond the Real34 target.

For `|x| >= 1/2`, set `u=exp(x)` and `v=1/u`. The helper uses

```text
sinh(x) = (u-v)/2
cosh(x) = (u+v)/2.
```

The subtraction condition induced by an error in `u` is

```text
(u+v)/|u-v| = coth(|x|) <= coth(1/2) < 2.164.
```

The reciprocal-rounding coefficient is at most

```text
max(u,v)/|u-v| <= 1/(1-exp(-1)) < 1.583.
```

Using the separate `realExp` bound of one p39 ulp, then allowing one rounding each for reciprocal, addition or subtraction, and scaling, gives less than `4E-38` relative error for the finite `sinh` path before second-order terms. For `cosh`, addition has no cancellation and the sensitivity to the exponential error is at most one, giving a smaller bound.

The p39 exponent range contains the intermediate exponential for every finite Real34 argument whose mathematical hyperbolic result can affect a finite Real34 output. Larger results are converted to the selected infinity or maximum-finite result according to the final context.

A deliberate p34 public mutation fails the exact digit-34 `sinh(0.3)` check in all seven output modes. The residuals range from two to six Real34 units. The fixed-operation bound at p34 also has no complete Real34 margin. P39 is therefore retained.

## Complex formulas

For `z=a+ib`, the implementation evaluates

```text
sinh(z) = sinh(a) cos(b) + i cosh(a) sin(b)
cosh(z) = cosh(a) cos(b) + i sinh(a) sin(b).
```

Each component contains one hyperbolic factor, one trigonometric factor, and one multiplication. There is no sum of large opposing products. For a nonzero component, the relative error is the sum, to first order, of the audited hyperbolic-helper error, the sine/cosine error, and at most `u39` from the final multiplication. At an exact component zero, the corresponding statement is absolute rather than relative.

P39 is the narrowest established direct context. A deliberate p34 complex mutation changes digit 34 for both `sinh(0.3+0.4i)` and `cosh(0.3+0.4i)`. The p39 results agree with independently computed 34-digit references. This conclusion is conditional on the separate trigonometric-kernel analysis.

Matrices reuse the same scalar or complex kernel for each element.

## Special values and signed zero

Classification, copy, sign, infinity, zero, and NaN operations implement the cases with a special real or imaginary component. They need no decimal context and introduce no rounding error. The direct complex routes now return:

```text
input                 sinh result       cosh result
NaN + i(+/-0)         NaN + i(+/-0)     NaN + i(+/-0)
+/-0 + i(NaN/Inf)     +/-0 + iNaN       NaN + i(+/-0)
+Inf + i(NaN/Inf)     +Inf + iNaN       +Inf + iNaN
-Inf + i(NaN/Inf)     -Inf + iNaN       +Inf + iNaN
```

The sign of a zero component whose IEC 60559 sign is unspecified follows the corresponding real input. The complex matrix route invokes the same complex function for each element.

IEEE multiplication makes `Infinity * 0` a NaN, but the limiting complex formulas require an exact signed zero when the trigonometric factor is exactly zero. The complex kernel now handles an infinite hyperbolic factor explicitly:

- a NaN trigonometric factor remains NaN;
- an exact trigonometric zero remains zero, with the product sign;
- every other finite trigonometric factor maps to the correctly signed infinity.

This applies both to infinite real inputs and to finite inputs whose hyperbolic factor exceeds the working range. The former code returns a NaN imaginary component for `sinh(+/-Infinity+i0)` and `cosh(+/-Infinity+i0)`.

## Tests

The new cases are in the existing `sinh.txt` and `cosh.txt` file-driven suites. They check all seven scalar output modes through digit 34, ordinary finite complex values through digit 34, infinite real components, exact zero factors, finite overflow, and signed-zero selection.

With the final cases present, the former infinite-factor multiplication succeeds in 312 of 320 focused checks. The revised implementation succeeds in all 320. The p34 scalar experiment succeeds in 313 of the 320 final focused checks, and the p34 complex experiment succeeds in 318 of 320.

The bounded follow-up set combines `sinh.txt`, `cosh.txt`, and `tanh.txt`. Before the special-value repair it succeeds in 193 of 216 checks; all 216 succeed after the repair. The added matrix cases exercise both the real and complex element dispatch.

The clean complete file-driven suite succeeds in all 18,351 checks with zero GMP-owned bytes.

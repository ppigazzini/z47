# Decimal context for real and complex arctangent

## Scope and result

This analysis covers the public real34 and complex34 arctangent routes in `arctan.c`, including elementwise matrix evaluation. It also records the assumptions placed
on `C47_WP34S_Atan`, `C47_WP34S_Atan2`, and `WP34S_Ln1P`.

The real route remains at `ctxtReal39`. The complex route now uses stable component formulae at the context supplied by its caller. The public caller supplies
`ctxtReal39`, so no 51-digit or 75-digit intermediate is needed. The results have at least 34 faithful digits subject to the stated logarithm-helper assumption. This
is not a universal correct-rounding claim. Differences confined to an accepted 39-to-34 rounding boundary are outside this analysis.

## Real arctangent

A finite real34 input enters `C47_WP34S_Atan` exactly. Requests through 39 digits use the table reduction analysed for `atan2`:

```text
a = min(|x|, 1/|x|)
c = j/10, where j is the nearest integer to 10*a
q = (a-c)/(1+a*c), so |q| <= 1/20
atan(a) = atan(c) + q*P(q^2).
```

The stored coefficients have an independently evaluated uniform relative approximation error below `2.929e-41` on the reduced interval. The table constants
contribute at most `5e-40` radians. With `u39 = 5e-39`, fewer than forty rounded operations give an absolute error below `3e-37` radians outside the cell centred on
zero and a relative error below `2.1e-37` inside that cell. Division for `|x|>1`, subtraction from `pi/2`, and angular conversion do not introduce a cancellation that
invalidates those bounds. A conservative relative bound for every finite nonzero result is `7e-36`.

The internal table dispatcher raises a 34-digit request only to 36 digits. The subsequent inversion correction and conversion to degrees, gradians, or multiples of
pi would remain at 34 digits. That route has no established margin for a 34-digit result. The p39 route retains the wide work exponent range and more than one decimal
guard digit under the conservative bound, so it is the narrowest established context.

Signed zero keeps its sign through the odd table evaluation and angle conversion. A NaN produces NaN. With special results disabled, either infinity reports the
existing domain error. With special results enabled, infinity becomes signed 90 degrees before p39 conversion to the selected angular mode. Real matrix entries use
the same route.

## Stable complex formulae

For finite `z = a+bi`, the principal value can be written as

```text
Re(atan(z)) = atan2(2a, 1-a^2-b^2)/2
Im(atan(z)) = log((a^2+(b+1)^2)/(a^2+(b-1)^2))/4.
```

The direct quotient identity previously formed `a^2+b^2-2b+1`. Near `z=+i`, this subtracts two from two after `a^2` or `(b-1)^2` has already disappeared. Exact
`z=i` consequently produced two NaNs, and finite real34 values adjacent to it could do the same.

The revised real component factors the cancellation:

```text
q = (1-b)(1+b)-a^2
Re(atan(z)) = atan2(2a, q)/2.
```

When `q` is susceptible to cancellation, `a^2+b^2` is close to one. In that region, each `1+/-b` factor from a real34 input is exact at p39. The rounded product error
is at most `u39*|1-b^2|`, and the fused `-a*a` addition adds at most `u39*|q|`. The sensitivity to an absolute perturbation of `q` is

```text
|d Re/dq| = |a|/(q^2+4a^2).
```

For `|q|` comparable to or larger than `a^2`, the atan2 condition bound controls the perturbation. For `|q| < a^2`, the product error is proportional to `a^2`, so
the displayed sensitivity reduces its effect to a constant times `u39*|a|`. It therefore does not become unbounded as `a` approaches zero. Allowing eight p39 unit
roundoffs for the factored quadratic argument adds less than `4e-38` radians before the established atan2 bound. The total conservative absolute error is below
`4e-37` radians. Near a zero real component, the zero-centred atan cell supplies its sharper relative bound; near a cut the result magnitude is close to `pi/2`.

For the imaginary component, the implementation selects a positive compensated-logarithm argument:

```text
h = |b|
D = a^2+(h-1)^2
r = 4h/D
Im(atan(z)) = sign(b)*log1p(r)/4.
```

`D` is a sum of squares, so its evaluation has no cancellation. For public real34 operands the p39 square, fused addition, exact multiplication by four, and division
give a relative perturbation in `r` below `4.1e-38`. The logarithm condition factor is

```text
r / ((1+r)*log(1+r)) <= 1.
```

Thus input perturbation contributes less than `4.1e-38` relative error to every finite nonzero imaginary component. The compensated `WP34S_Ln1P` shortcut for a value
lost in `1+r` has relative error below `2.6e-39`; otherwise its correction ratio removes the rounded addition error. This component's 34-digit claim assumes that the
underlying p39 `WP34S_Ln` result has relative error below `1e-35`. This is a deliberately loose requirement of two thousand p39 unit roundoffs and leaves three decimal
digits beyond the result width. A separate full audit of `WP34S_Ln` can tighten that dependency.

A 34-digit context provides no guard digits for either `atan2` or compensated `ln(1+x)`. At p39 the products of the most extreme finite real34 exponents remain inside
the `+/-999999` work range. The stable nonnegative denominator removes the need for 51 or 75 digits. Running the expanded denominator at either of those widths would
spend digits on cancellation that the factored formula avoids.

## Cuts and special values

The sign of zero in `a` selects the side of the imaginary-axis cuts beyond `+/-i`. In particular, `+0+2i` returns `+pi/2+log(3)i/2`, while `-0+2i` returns the negative
real counterpart. At `a+bi = +/-0 +/- i`, the nonnegative denominator is zero, so the compensated logarithm returns the correctly signed infinite imaginary component;
the real component is the signed zero selected by `a`.

A NaN component produces two NaN components. If either component is infinite and neither is NaN, the limiting result is `copysign(pi/2,a) + i*copysign(0,b)`.
Complex results remain in radians, independent of the selected real angular mode. The helper copies both inputs before writing either output, so aliased use by the
Gudermannian and elliptic-function routes remains valid. Those callers supply their own context; the real34 exact-factor argument above applies specifically to the
public p39 route.

## Verification

Independent 180-digit decimal arithmetic evaluated the table-edge, rounding-mode, branch-point, near-branch-point, and compensated-logarithm references. The focused
file includes all seven final rounding modes for a real value, three table-cell boundary values, both logarithmic branch points, both sides adjacent to them, signed
cut values, extreme small exponents, infinities, NaNs, and a complex matrix.

Against the original quotient implementation, 44 of 54 focused cases succeeded and ten failed. Failures included NaN at and adjacent to `+i`, erased tiny imaginary
components, an incorrect cut side for positive real zero, and nonfinite limiting values. The revised implementation succeeded in all 54 focused cases.

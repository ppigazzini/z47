# Decimal context analysis: cube root

## Scope and conclusion

This audit covers the public Real34 scalar and complex cube-root routes in
`src/c47/mathematics/cubeRoot.c`, including the finite, zero, NaN, infinity and
exponent-limit cases. Short integers, long integers and the 159-digit cubic
solver route are dependencies only.

`ctxtReal39` is the narrowest established global context for both public
routes. `ctxtReal34` is too narrow in precision and exponent range. The 51- and
75-digit contexts provide no needed margin for a final Real34 result. The code
keeps p39 and adds two corrections that precision alone cannot provide:

- an exact-decimal-cube verification before the selected Real34 rounding;
- explicit finite-side handling beside an infinite real component, plus
  preservation of the sign of a zero imaginary component.

Differences caused only by a p39 to p34 rounding boundary are excluded as
requested. The analysis below does not use that exclusion to excuse the exact
cube or infinity defects.

## Units and exponent range

For a p-digit normalized result, let

```text
eta_p = 10^(1-p).
```

A correctly rounded nearest operation contributes at most `eta_p/2` relative
error away from zero, and a directed operation contributes less than `eta_p`.
Thus `eta_34 = 1e-33` and `eta_39 = 1e-38`.

Real34 has the decimal128 normal exponent limits. Its smallest subnormal is
`1e-6176`, and its largest finite adjusted exponent is 6144. The p39 context
uses `emax = 999999` and `emin = -999999`. That wider range is material on the
complex route: squaring a legal component above about `1e3072` overflows under
`ctxtReal34`, even though its cube root is representable.

## Scalar route

For a finite nonzero magnitude `x`, `PowerReal` evaluates

```text
exp((1/3) * ln(x)).
```

`WP34S_Ln` separates the decimal exponent, reduces the coefficient, and uses
the odd-power logarithm series on a bounded interval. Across Real34,
`|ln(x)| < 1.43e4`. The stored 39-digit value of one third differs from the
exact value by less than `3.34e-40`, so its direct contribution to the
exponential argument is below `4.8e-36`. Reconstruction of the logarithm's
decimal-exponent term has an absolute p39 rounding scale near `1e-34` at the
range limits. Division by three turns that into a root-relative scale of a few
times `1e-35`. `decNumberExp` documents a fixed half-even result with an error
of at most one p39 ulp in its rare inaccurate cases, which is smaller than the
exponent-reconstruction term.

The resulting forward-error scale is below one tenth of a Real34 ulp. This is
enough margin for the requested result outside a final rounding boundary. It
is not a proof that the transcendental composition is correctly rounded for
every possible input. Such a proof would require a directed enclosure and a
retry at greater precision when the enclosure straddles a Real34 boundary.

At p34, the logarithm reconstruction and the multiplication by one third can
lose roughly four digits at the exponent limits. A measured p34 substitution
made every exact-digit `curt(2)` check fail across the seven rounding modes;
the scaled residuals ranged from 10 to 60 Real34 last-place units. For
`curt(1e6144)`, the p34 relative error was about `4.9e-30`. The exact-cube
verification could not repair a candidate that far from the true root.

The p39 transcendental approximation can still sit slightly to one side of an
exact cube. Directed rounding then returns an adjacent Real34 value even
though the mathematical result is exact. The new verification performs these
steps:

1. Round the p39 approximation to nearest-even Real34 and reduce trailing
   decimal zeros.
2. Reject a candidate whose reduced coefficient has more than 12 digits.
3. Cube the remaining candidate with two p39 multiplications and compare it
   with the operand.
4. Use the candidate when the comparison is equal.

If a reduced decimal root has `d` coefficient digits, its cube has at least
`3d - 2` coefficient digits. A Real34 exact cube therefore has `d <= 12`.
Its cube has at most 36 digits, so both p39 multiplications are exact. The
digit test also prevents a rounded p39 comparison from accepting a general
34-digit candidate whose exact cube would require as many as 102 digits.
Exact roots now remain exact under all seven rounding modes.

Negative finite inputs use the same magnitude analysis and receive their sign
after the power evaluation. Positive and negative zero retain their signs.
With `SPCRES` enabled, positive and negative infinity remain exact. NaN remains
NaN. With `SPCRES` disabled, the existing infinity domain error is unchanged.

### LongInteger inputs

Non-perfect LongInteger cubes cannot safely pass through p75 first. The shared exact-root route uses the same coefficient construction as square root with
`q=floor((d-1)/3)` and `S=33-q`. GMP produces

```text
c = floor(cuberoot(abs(N)) * 10^S)
```

and exact remainders. Nearest rounding compares `8*abs(N)` with `(2c+1)^3` after applying the matching power-of-ten scale. Directed rounding uses the remainder and
maps ceiling and floor according to the sign of `N`. This directly resolves both `10^81+1` and `10^81-1`, their negative counterparts, and midpoint-sensitive wide
integers under every selected mode. Perfect integer cubes still return a LongInteger.

## Complex route

For finite `z = a + ib` with `b != 0`, the p39 route evaluates

```text
rho   = sqrt(a*a + b*b)
theta = atan2(b, a)
w     = rho^(1/3) * (cos(theta/3) + i sin(theta/3)).
```

The magnitude uses one rounded square, one fused multiply-add and one square
root. With correctly rounded arithmetic, its relative error is bounded by a
small multiple of `eta_39`. The p39 arctangent implementation documents about
38 correct digits. Division of the angle by three and the final p39
multiplications add errors of the same or smaller order. Sine and cosine use
51-digit Taylor arithmetic before rounding to the requested p39 result. The
radius power has the scalar bound above and dominates the normwise error near
the Real34 exponent limits.

The map `z -> z^(1/3)` has normwise relative condition number `1/3` away from
zero. The polar implementation therefore has a forward normwise error below
one tenth of a Real34 ulp at p39, apart from the accepted final boundary case.
A uniform component-relative guarantee is impossible: the imaginary component
is zero on the positive real axis and can be arbitrarily small nearby. The
appropriate guarantee there is an absolute error scaled by `|z|^(1/3)`.
Inputs with an exactly zero imaginary component take the real-valued branch,
so an exact zero does not acquire trigonometric residue.

The widened p39 exponent limits keep all intermediates finite for finite
Real34 inputs:

- component squares have adjusted exponents between about -12352 and 12289;
- an `atan2` ratio can span about 12320 decimal exponent positions;
- the radius cube root is between about `1e-2059` and `2.2e2048`;
- conversion to Real34 applies the selected underflow or overflow rounding to
  each final component.

A p34 substitution failed every exact-digit `curt(1+i)` check across all seven
rounding modes. It also returned infinity plus zero for
`curt(1e6144 + i*1e-2000)`: the component square overflowed before the finite
cube root could be formed. This range failure alone rules out `ctxtReal34` for
the present polar formula. A scaled-hypot rewrite would remove that overflow,
but it would not supply guard digits for the power, angle and final coordinate
multiplications.

## Complex zeros and special values

The public function intentionally uses the real-valued cube root when the
imaginary component is exactly zero. The result now copies that zero, including
its sign, and applies the exact-decimal-cube verification to the real
component.

For a nonzero finite imaginary component beside an infinite real component,
the limiting principal values are

```text
(+infinity, b) -> (+infinity, signed zero)
(-infinity, b) -> (+infinity, signed infinity), sign from b.
```

The general rectangular-to-polar special table uses `+pi` for both finite
sides of negative infinity and `+0` for both finite sides of positive
infinity. That loses the side needed by cube root. `curtComplex75` now handles
these two cases before polar conversion. Inputs with an infinite imaginary
component, with both components infinite, or with a NaN continue through the
existing special tables. Their sector signs remain unchanged.

## Higher-precision dependencies

`curtComplex` dispatches contexts through p75 to `curtComplex75` and greater
contexts to the 159-digit Halley implementation. The public Real34 entry uses
p39 only.

The name `curtComplex75` must not be interpreted as a 75-digit accuracy
guarantee. Its exponent is `const39_1on3`, and `PowerReal` reconstructs the
logarithm with 39-digit constants. Those constants limit a p51 or p75 request
to about 39 useful digits. The 159-digit solver route constructs its own third
and uses a separate algorithm. Changing either solver route is outside this
audit.

## Regression evidence

The focused baseline with the first new cases reported 58 successes and six
failures. The failures were three directed-mode exact cubes, the equivalent
complex real-axis case, a negative-zero sign, and the lower side beside
negative infinity.

After the fixes, the focused file contains 110 checks. It covers all seven
rounding modes for `curt(2)` and `curt(1+i)` with subtraction and `1e34`
scaling, an exact nine-digit root, exact cubes at the Real34 upper exponent,
signed zero, infinity sides, NaN through the existing cases, and a finite
component-exponent spread of 8144 positions.

The scalar signed-zero cases now verify both complex-result settings and use a
reciprocal check for the negative sign.

The complete suite reported 14,033 successes and zero failures in 350.36
seconds, including its rebuild.

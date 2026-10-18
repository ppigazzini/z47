# Decimal context analysis: x-th root

## Scope and conclusions

This audit covers the public Real34 scalar and complex routes in
`src/c47/mathematics/xthRoot.c`, together with the logarithm constants used by
those routes and the exact integer-root shortcut. Matrix solvers and the
159-digit solver kernels are dependencies only.

The recommended contexts are:

- keep `ctxtReal39` for scalar Real34 x-th root;
- use `ctxtReal75` for the public complex Real34 route and for the complex
  fallback from a negative scalar operand.

For scalar input, p39 is the narrowest established context among 34, 39, 51
and 75 digits. The p34 context has neither guard digits nor the exponent range
needed by the logarithm and power composition. For complex input, p39 gives a
small normwise error but can lose most digits of a near-axis component. An
independent input shows that p51 also has too few digits after phase
cancellation, while p75 returns all 34 result digits. No fixed precision can
give a uniform component-relative guarantee at a component zero.

Differences confined to a p39-to-p34 rounding boundary are excluded as
requested. The exact-root, phase-cancellation and infinity-side defects below
are not members of that excluded class.

## Arithmetic model

Let

```text
u_p = 0.5 * 10^(1-p)
```

for a p-digit half-even operation on a normal result. The 39- and 75-digit
contexts use half-even internally and have exponent limits of `+/-999999`.
Only `ctxtReal34` follows the selected user mode. The final Real34 conversion
therefore applies half-even, half-up, half-down, away from zero, toward zero,
ceiling or floor after the work result has been formed.

Real34 inputs range from the minimum subnormal `1E-6176` to a maximum adjusted
exponent of 6144. Products of two finite Real34 coefficients contain at most
68 digits, and a sum of two such products contains at most 69 digits.

## Scalar route

For a positive finite operand `y` and nonzero finite order `x`, the scalar
kernel evaluates

```text
q = 1 / x
r = exp(q * ln(y)).
```

Negative operands with an odd integral order use the same magnitude kernel
and apply the negative sign afterwards. Across the Real34 range,
`abs(ln(y)) < 1.43E4`. `WP34S_Ln` reduces the coefficient to a bounded
interval, evaluates its odd-power series, and reconstructs the decimal
exponent term with a 39-digit `ln(10)`. The p39 division, multiplication and
exponential then leave about five guard digits for a Real34 result whenever
the function value is not at an accepted final rounding boundary.

This is a forward-error margin, not a correctly-rounded transcendental proof.
The map is ill-conditioned as `x` approaches zero, and a certified result in
that region would require interval evaluation plus a higher-precision retry.
The current special and overflow rules remain applicable when the requested
root is outside Real34.

The p34 context is not suitable. It changes with the user rounding mode, uses
the decimal128 exponent limits for intermediate values, and has no guard
digit for the logarithm, reciprocal and exponential composition. A p34 trial
at the upper exponent limit produced relative errors near `1E-29`. The exact
input

```text
(1E6144)^(1/3) = 1E2048
```

also landed one Real34 unit below the exact answer under toward-negative
rounding. P39 made the approximation close enough for exact verification;
p51 and p75 are unnecessary for the scalar path.

### Identities and exact decimal roots

Precision does not by itself preserve an algebraic identity through
`ln` followed by `exp`. Order one now copies the operand, and order minus one
uses the correctly rounded primitive division. The copy preserves all 34
digits and a finite component adjacent to an infinity.

For a long-integer operand, order one converts the exact integer directly to
Real34. Order minus one uses the exact scaled-integer quotient path, including
when the order is also a long integer. For an ordinary Real34 operand, order
minus one performs the sole p34 division directly. These routes apply the
selected rounding mode once instead of first shortening the operand or a p39
quotient.

For other positive integral orders, the p39 approximation is checked for an
exact decimal result before user rounding:

1. Round the approximation to nearest-even Real34 and reduce trailing zeros.
2. Multiply the candidate by itself at p39, stopping before a product whose
   coefficient must exceed 34 digits.
3. Compare the exact product with the original operand.
4. Substitute the candidate when they are equal.

Every multiplication that reaches step 3 is exact: its result coefficient has
at most 34 digits in a 39-digit context. If the reduced candidate coefficient
has absolute value at least two, an exact Real34 power needs at most 112
factors because `2^113` has 35 digits. A separate exponent identity handles a
unit coefficient, so exact powers of ten can use larger 32-bit orders without
thousands of multiplications. The check cannot change an inexact result.

The focused checks include `123^5`, `7^40`, `(1E2048)^3`, and
`10^6144`. The exponent-limit cube is checked under all seven user modes.

LongInteger orders two through four additionally use the exact GMP coefficient and midpoint method documented for square root. This applies both when the order is
itself an integer register and when an exact Real34 `2`, `3` or `4` selects the scalar route. It avoids the former LongInteger-to-p75 conversion, which could lose
the side of a Real34 value or midpoint before the root calculation began. Negative orders two through four use the reciprocal construction directly: the
coefficient is the integer root of `floor(10^(n*S)/abs(Y))`, and an exact cross-product comparison selects the final neighbour. Computing and then inverting a
rounded positive root would not preserve directed rounding. A negative LongInteger with order `2` or `-2` uses the same exact magnitude to form its complex
imaginary component. Other non-perfect LongInteger orders retain the general p75 path.

### Integer order bounds

The GMP integer-root function accepts a bounded machine-word order. The exact
integer shortcut now checks that the order, rather than the operand, is
positive and within the existing `2147483640` limit before conversion. Larger
orders continue through the decimal route. This prevents an order such as
`4294967296` from wrapping to zero before the GMP call, while a large perfect
cube with order three still returns its exact long-integer root.

### Exact order parity

The real branch choice needs the mathematical parity of an integral order.
A p39 decimal remainder is not reliable when a Long order has more than 39
integer digits because even its quotient by two exceeds the context width.
The register conversion layer now classifies integer parity exactly with GMP
before any decimal conversion. Real34, short-integer, and long-integer orders
share this classification. An odd order of `10^40+1` therefore keeps the real
negative root and the sign of a negative infinity.

## Complex route

Write

```text
y = rho * exp(i theta)
x = a + i b
D = a^2 + b^2.
```

For logarithm branch integer `k`, the candidate logarithm of a root is

```text
Re(Log r) = (a ln(rho) + b(theta + 2 pi k)) / D
Im(Log r) = (a(theta + 2 pi k) - b ln(rho)) / D.
```

The implementation chooses zero when that branch has an imaginary part in
`[-pi, pi]`; otherwise it chooses the admissible integer nearest zero. It then
forms `exp(Log r)`.

At p75, `D` is exact for finite Real34 `a` and `b`: both squares and their sum
fit within 69 digits. The wide exponent range also prevents the component
squares from overflowing or underflowing. The magnitude square root is
correctly rounded at p75. The integrated trigonometric path reduces a radian
input at p12321 before shortening its reduced angle and evaluating the guarded
Taylor kernel. `WP34S_Ln` now selects the existing 75-digit `ln(10)` for a p75
context, so a magnitude with a nonzero decimal exponent does not reintroduce a
39-digit limit. Other context widths keep their prior logarithm constant
selection.

Away from a branch boundary and `x = 0`, the resulting normwise work error is
on the p75 scale, far below a Real34 unit. The conditioning includes a factor
near `1/abs(x)`, so no input-independent relative bound exists as the order
approaches zero.

### Near-axis components

The two terms in either component of `Log r` may nearly cancel. Componentwise
relative accuracy is then not implied by a small normwise error. This is
unavoidable at an exact zero and arbitrarily close to it.

The following independent input exposes a practical fixed-width distinction:

```text
y = -1.1 + i0
x = 0.09531017980432486004395212328076509
    + i*3.141592653589793238462643383279503
```

A 150-digit decimal evaluation gives the selected root

```text
Re = 2.7182818284590452353602874713526623977085...
Im = -4.956687236259292612797915169072767572617...E-36.
```

The former p39 route returned

```text
2.718281828459045235360287471352662
  - i*4.956569985554033026113413094793845E-36.
```

Its normwise error is tiny, but the small component has only about five useful
digits. The cancellation consumes about 36 decimal positions, so p51 cannot
retain 34 component digits. P75 leaves about 39 positions and returns the
34-digit reference value under each user mode. This establishes p75 as the
narrowest member of the existing context set that resolves this input.

A second check uses `y = -1.1E6000 + i0` and an order whose real component is a
34-digit approximation to `ln(1.1E6000)`. It exercises the p75 `ln(10)` term
and verifies a `1.557001000667983372564508220782606E-37` imaginary component.

### Exact half orders

P75 cannot retain an angular displacement below its 75-digit phase scale. For
example, the phase of `1E-6000-5i` differs from `-pi/2` by about `2E-6001`.
The logarithmic route therefore cannot distinguish the valid positive-real
side from the invalid negative-real side.

For the exact real orders `1/2` and `-1/2`, rectangular identities avoid the
phase calculation. A finite nonzero `y` has a half-order root exactly when it
is in the open right half-plane or on the selected imaginary half-axis:

```text
x =  1/2: Re(y)>0, or Re(y)=0 and Im(y)>0
x = -1/2: Re(y)>0, or Re(y)=0 and Im(y)<0.
```

The result is `y*y` for `x=1/2` and `1/(y*y)` for `x=-1/2`. Products of
Real34 components have at most 68 coefficient digits, and their sum or
difference has at most 69, so p75 preserves the exact rectangular square.
The reciprocal retains more than the required 34 result digits. In particular,

```text
(1E-6000-5i)^(1/(1/2)) = -25-1E-5999i,
(1E-6000+5i)^(1/(-1/2)) = -0.04-1.6E-6002i.
```

Changing the sign of the tiny real component moves each input to the excluded
side and returns no root under the half-open principal logarithm convention.

## Exponent range

With finite Real34 components, `a^2`, `b^2` and `D` have adjusted exponents
within roughly `[-12352, 12290]`. The p39 and p75 exponent ranges contain
these values; `ctxtReal34` does not. A scaled-hypot rewrite could avoid that
particular p34 range failure, but it would not add the guard digits required
by the logarithm, division and coordinate conversion.

The result exponent is governed by `Re(Log r)`. Values beyond the Real34 range
are converted according to the user mode and `SPCRES` rules. Intermediate
logarithms and finite branch arithmetic remain well inside the p75 exponent
range for ordinary branch indices.

## Zeros, NaNs and infinities

The existing zero rule is retained: `0^X = 0` needs `Re(X) > 0`, while order
zero is accepted only for the operand one. A finite positive scalar order
copies either sign of a zero operand directly. This preserves a negative-zero
root independently of the special-result and complex-result settings. NaN
inputs preserve the prior NaN-pair behavior instead of taking an identity
shortcut.

The shared rectangular-to-polar special table uses 39-digit phase constants
and assigns the same phase to both finite sides of an infinite axis. A local
logarithm wrapper now selects p75 phase constants and preserves the side:

```text
(-infinity, negative finite) -> phase -pi
(+infinity, negative finite) -> phase -0
```

Thus a square root selected through x-th root returns `0 - i*infinity` for
`-infinity - i` and `infinity - i*0` for `+infinity - i`. Axis and diagonal
infinity combinations retain the existing eight-sector semantics. The exact
half-order identities resolve their Real34 phase boundaries. For other
nonintegral real orders, a negative phase within ten p75 units of `-pi` stays
an unresolved boundary rather than an interior root. It is rejected under the
function's half-open logarithm convention even when the trigonometric kernel
leaves a tiny phase residue.

## Extreme branch indices

P75 does not solve every branch-selection input. For example,

```text
y = 2 + i0
x = 1E-200 + i*1E-100
```

has an admissible branch with an integer index near `1E99`. Its phase step is
slightly below `2*pi`, but a 75-digit value of the index cannot retain the low
digits needed when `k*step` cancels the branch-zero phase.

Eliminating the explicit integer does not eliminate the precision need. The
index is determined by the fractional part of

```text
sign(a) * theta/(2*pi) - (b/abs(a)) * ln(rho)/(2*pi).
```

For the example, about 100 displaced decimal positions of a transcendental
product are required. Across the full Real34 component-exponent spread, the
requirement can exceed 12,000 positions. Splitting the exact decimal
coefficient and exponent avoids construction of a huge decimal integer, but
still needs logarithm and pi values to that displaced precision. The existing
fixed p75 kernel and constants cannot supply it.

A complete repair therefore needs variable-precision modular logarithm and
phase arithmetic, with a certified interval for the selected integer. That is
a materially larger dependency than this Real34 context audit. The current
function continues to return no root for some members of this extreme-index
class, and the limitation is explicit rather than attributed to final
p75-to-p34 rounding.

## Regression evidence

Before the changes, the first focused addition reported ten failures: three
infinity-side checks and seven exact 34-digit near-axis checks. Strengthened
subtraction-to-zero checks also exposed `1E6110` residuals for order-one at
the upper Real34 exponent and `1E2014` residuals for the exact cube root.

The focused file also checks an order beyond the exact integer shortcut and a
30-digit perfect cube whose root remains an exact long integer. The previous
operand-based bound both admitted the oversized order and excluded the large
perfect cube.

The final focused file contains 419 checks. It covers scalar identities,
several exact roots, all seven user modes, complex order one, both infinity
sides, all seven rounded near-axis results, and the p75 logarithm-exponent
dependency. Each finite corner check uses subtraction, and the small complex
components are scaled so a one-unit error is nonzero in the comparison. The
repository-wide suite then passed all 14,508 checks.

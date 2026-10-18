# Decimal contexts for parallel combination

## Scope and result

This analysis covers the real and complex `parallel` operations in `src/c47/mathematics/parallel.c`. For finite nonzero operands they calculate

\[
x\mathbin{\|}y=\frac{xy}{x+y}.
\]

The real route now uses `ctxtReal39` for its multiply, add, and divide. Its finite working error is below `1.51e-38` relative to the exact result. This is the
narrowest established context that gives a margin beyond 34 digits and has the wide exponent limits required by the intermediate product.

The complex route keeps `ctxtReal75` for the cancellation-sensitive complex products and component sums. It replaces generic division of those wide
intermediates with a compensated multiplication by the conjugate, then uses `ctxtReal39` for the positive denominator and the two scalar divisions. The finite
normwise working error is below `1.51e-38`. A component near zero has an absolute bound derived below, but no uniform componentwise relative bound.

The analysis describes working accuracy, not universal correctly rounded real34 results. The accepted differences caused only by the final 39-to-34 conversion are
outside its claims.

Those bounds assume exact Real34 inputs. A wider LongInteger can lose a small nonzero `x+y` even during p75 conversion and turn a finite near-pole result into a
false pole. When either real scalar operand is a LongInteger, the revised route unpacks any Real34 operand to its exact coefficient and exponent, forms `xy` and
`x+y` with GMP, and performs one quotient rounded directly to the configured result precision. A single infinite operand selects the finite LongInteger through direct conversion, so
that limit case also avoids pre-rounding. The ordinary Real34 and complex routes retain their established work contexts.

The matrix dispatch applies these same scalar kernels element by element. It introduces no further decimal operations, so the bounds and special-value rules below
also apply to each real or complex matrix element.

## Real finite error

Let `p` be the context precision and let

\[
u_p=\tfrac12 10^{1-p}.
\]

The wide contexts use round-to-nearest-even. For finite nonzero `x`, `y`, and `s=x+y` the three correctly rounded operations give

\[
\widehat m=xy(1+\delta_m),\qquad
\widehat s=s(1+\delta_s),\qquad
\widehat q=\frac{\widehat m}{\widehat s}(1+\delta_q),
\]

where every `|delta|` is at most `u_p`. Thus

\[
\frac{\widehat q}{q}=\frac{(1+\delta_m)(1+\delta_q)}{1+\delta_s}
\]

and, at `p=39`,

\[
\left|\frac{\widehat q-q}{q}\right|
\leq\frac{(1+u_{39})^2}{1-u_{39}}-1
<1.51\mathbin{\cdot}10^{-38}.
\]

Subtraction-like cancellation in `x+y` does not add a condition factor to this arithmetic bound: the addition is correctly rounded relative to its exact nonzero
result. The mathematical input condition does become large near the pole. Its componentwise relative condition sum is

\[
\kappa=\frac{|x|+|y|}{|x+y|}.
\]

This separates sensitivity to perturbed inputs from rounding of the supplied real34 inputs. At the exact pole, the denominator is zero and the operation returns
the signed infinity produced by division. The file-driven reference checks `1 || -1 = -Infinity`.

At 34 working digits the same bound is about `1.51e-33`, which supplies no 34-digit margin. `ctxtReal34` also has decimal128 exponent limits. For example, its
intermediate product for `1e6144 || 1e6144` overflows even though the result is the representable `5e6143`. `ctxtReal39` is therefore the narrowest suitable
established context.

## Complex reformulation

Write

\[
P=xy,\qquad S=x+y,\qquad D=|S|^2.
\]

The operation is evaluated as

\[
\frac{P\,\overline S}{D}.
\]

The former route supplied the wide values `P` and `S` to `divComplexComplex`. Its 75-digit component numerators each used one ordinary product followed by one
fused addition. The public complex-division proof relies on initial real34 operands, whose elementary products have at most 68 coefficient digits and are exact at
75 digits. That premise is false here: components of `P` already contain as many as 75 digits, so the final products can have as many as 150. A rounded first
product can lose digits needed when the fused addition cancels it.

The replacement computes `P*conj(S)` with the integrated compensated complex-multiplication kernel. Its cancellation bound applies to the operands supplied at this
stage, including the wide components of `P`. The denominator has no subtraction and is calculated separately with one square and one fused addition.

## Complex normwise error

Set `v=u_75` and `u=u_39`. The first compensated multiplication gives

\[
|\widehat P-P|\leq2v|P|.
\]

The component additions for `S` give the complex-norm bound

\[
|\widehat S-S|\leq v|S|.
\]

Before rounding the second complex product, perturbing these two operands changes its norm by at most

\[
(3v+2v^2)|P||S|.
\]

The compensated kernel then contributes at most `2v` relative to the product of its supplied operands. Consequently the numerator vector satisfies

\[
|\widehat N-P\overline S|
\leq(5v+8v^2+4v^3)|P||S|
<2.51\mathbin{\cdot}10^{-74}|P||S|.
\]

The denominator calculation has the standard square-plus-FMA bound `2u+u^2` relative to `|widehat S|^2`. Including the 75-digit sum error gives

\[
|\widehat D-D|<1.01\mathbin{\cdot}10^{-38}D.
\]

Each final scalar division adds at most `u=5e-39` relative error. Combining the numerator, denominator, and division terms gives

\[
\frac{|\widehat z-z|}{|z|}<1.51\mathbin{\cdot}10^{-38}.
\]

This is a complex-norm result. For either component `z_j`, it implies the absolute bound

\[
|\widehat z_j-z_j|<1.51\mathbin{\cdot}10^{-38}|z|.
\]

The corresponding relative bound contains `|z|/|z_j|`, which is unbounded as that component approaches zero. This is both a conditioning issue and a reason to
retain 75 digits in the two compensated products. The result does not claim 34 relative digits in every arbitrarily small component.

## Cancellation cases and context choice

An exact integer family exposes the former generic-division error. Let

```text
M = 123456789012345678901234567890123,
y = 5M + 5M i,
x = -2M + 4M i.
```

Then

```text
P = -30M^2 + 10M^2 i,
S = 3M + 9M i,
P*conj(S) = 300M^3 i,
x || y = (10M/3) i.
```

The real component is exactly zero. Scaling both operands by `1e6000` scales the result by the same factor. The former route returned
`-5.476521551566151861071839527520049e5956` for that exact-zero component. The compensated route returns zero and the exact finite imaginary component.

A second independently derived family is

```text
M = 36662192161839641574916785799,
y = 232M(4 - 3i),
x = 55M(-11 + 13i).
```

Its exact real numerator is zero because

```text
-605 * 232^2 * 25 + 928 * 55^2 * 290 = 0.
```

An independent 180-digit decimal calculation gives

```text
Re(x || y) = 0
Im(x || y) = 123107782101335217498931101788221.052631578947368421...
```

Evaluating the redesigned cancellation stages at 51 digits instead gives a real component of about `-1.1880677672451384384e-20`; 75 digits gives exact zero.
The test scales this family by `1e6000`, so the 51-digit residue is about `-1.188e5980` and cannot be hidden by an absolute comparison near zero. The 34-, 39-, and
51-digit contexts cannot represent every elementary product of two real34 components exactly. `ctxtReal75` is the narrowest established context which can do so,
and it is retained where those discarded digits can determine a cancelled component. The denominator and divisions have no such cancellation, so their proved
39-digit bounds permit the narrower context.

## Exponent range

All wide contexts have exponent limits of `+/-999999`. Real34 input components have adjusted exponents from `-6176` through `6144`. The real product, the first
complex product, the second complex product, and the squared complex denominator remain many orders inside the wide limits. No working underflow or overflow occurs
for finite real34 inputs. Any final underflow or overflow is therefore applied during the intended real34 conversion.

The file-driven cases include maximum-exponent equal operands and minimum-subnormal equal operands. They verify `5e6143` and final zero respectively without a
premature working exception.

## Rounding modes and special values

The 39- and 75-digit work uses round-to-nearest-even. Final conversion applies the configured half-even, half-up, half-down, away-from-zero, toward-zero, ceiling,
or floor mode. Exact mixed-LongInteger quotients also round directly to `SDIGS` when it is active, avoiding a 34-digit intermediate midpoint. The file-driven cases
exercise every mode. The finite error bounds precede that conversion and do not depend on the selected final mode.

Special values are handled before finite arithmetic:

- A NaN component returns NaN, including when the other operand is zero.
- Zero is absorbing. The zero operand supplies the result. The public real result is normalised to positive zero; the complex result retains the component sign.
- One infinite operand and one finite operand return the finite operand, which is the limit as the infinite operand's magnitude increases.
- Two infinite operands return NaN because their relative magnitudes and directions are unspecified.
- A finite complex pole `x=-y` reaches zero numerator components and a zero denominator, returning `NaN+iNaN`.

## Verification

The two existing parallel test files cover near-pole finite input, both exact cancellation families, large and subnormal exponents, signed zero, finite and infinite
operand order, two infinite operands, NaN with zero, exact poles, and all seven rounding settings. With the former implementation, the focused 48-case reading
reports eight failures: two real finite/infinite orders, real NaN with zero, both exact complex cancellations, two complex finite/infinite orders, and complex NaN
with zero.

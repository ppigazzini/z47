# Decimal context for public complex division

## Scope and result

This analysis covers the public real34 calculation

\[
(a+ib)/(c+id)
\]

through `divCplxCplx` and `divComplexComplex75`. The scalar route supplies
`ctxtReal75` to the kernel. The same proof now governs complex matrix division
by a complex scalar and complex scalar division by a complex matrix, since each
matrix component has four Real34 coefficients. Scalar-real, integer,
matrix/matrix, and 159-digit calculations are outside this analysis.

For finite real34 inputs and a nonzero denominator, each nonzero 75-digit component has relative error below `1.51e-74`. An exactly zero numerator component remains exactly zero. The result therefore has considerably more than 34 correct significant digits before conversion to real34, including severe component cancellation.

This is an accuracy result, not a universal correctly rounded real34 result. A finite working error can cross a final rounding boundary. Differences caused only by that final conversion are outside the stated requirement.

## Formula

The kernel evaluates

\[
D=c^2+d^2,
\qquad N_r=ac+bd,
\qquad N_i=bc-ad,
\]

followed by `N_r/D` and `N_i/D`. Each numerator uses one multiplication and one fused multiply-add.

## Error at a narrower context

Let a context have precision `p` and unit roundoff

\[
u_p=\tfrac12 10^{1-p}.
\]

For round-to-nearest-even, the initial rounded square and the fused addition give

\[
|\widehat D-D|\leq u_pD+u_p(1+u_p)c^2
                 \leq (2u_p+u_p^2)D.
\]

There is no denominator cancellation because both terms are nonnegative. The denominator alone would therefore be safe at 39 digits.

The component numerators have a different bound. With `A=ac` and `N=N_r`,

\[
\widehat N=\operatorname{fl}_p\!\left(bd+\operatorname{fl}_p(A)\right)
\]

and

\[
|\widehat N-N|\leq u_p|N|+u_p(1+u_p)|A|.
\]

For the imaginary component the same result applies with `A=bc` and `N=N_i`. The term `|A|/|N|` has no finite upper bound when the two products nearly cancel. A 39-digit or 51-digit context therefore has no componentwise 34-digit accuracy guarantee.

Two real34 coefficients can produce a 68-digit product. A 39-digit multiplication can discard 29 product digits, and a 51-digit multiplication can discard 17. A later fused addition cannot recover those digits. Measured cancellation cases retained about 6 significant digits at 39 digits and about 18 at 51 digits in the small component.

## Error at 75 digits

Every product of two finite real34 values has at most 68 coefficient digits, so each initial multiplication is exact at 75 digits. The exponent bounds of `ctxtReal75` also prevent intermediate overflow, underflow, or subnormal rounding. Consequently the denominator and each numerator receive one rounding:

\[
\widehat D=D(1+\delta_D),\qquad
\widehat N=N(1+\delta_N),\qquad
|\delta_D|,|\delta_N|\leq u_{75}=5\mathbin{\cdot}10^{-75}.
\]

If a component numerator cancels to zero, the exact products and fused addition produce zero exactly. For a nonzero quotient, the final division contributes `|delta_q| <= u_75`, giving

\[
\frac{\widehat q}{q}
=\frac{(1+\delta_N)(1+\delta_q)}{1+\delta_D}.
\]

The larger one-sided bound is

\[
\left|\frac{\widehat q-q}{q}\right|
\leq \frac{(1+u_{75})^2}{1-u_{75}}-1
<1.51\mathbin{\cdot}10^{-74}.
\]

Equivalently,

\[
|\widehat q-q|<1.51\mathbin{\cdot}10^{-74}|q|.
\]

This relative bound remains valid for a nonzero component arbitrarily near cancellation. Exact cancellation uses the separate exact-zero result above.

## Exponent range and scaling

A finite real34 value has an adjusted exponent from `-6176` through `6144`. Products and sums used here remain far inside the `-999999` through `999999` working range. Even loose independent bounds put a nonzero intermediate quotient between approximately `1e-24650` and `1e24650`.

The unscaled formula therefore cannot overflow or underflow in the working context for real34 inputs. Overflow or underflow can occur only during the intended conversion of a valid wide result to real34. A Smith-style scaled division would add branches without reducing the required product precision, because component cancellation would still require the exact low product digits.

## Rounding modes

The configured 75-digit context uses round-to-nearest-even. The final conversion applies the selected calculator mode: half-even, half-up, half-down, away from zero, toward zero, ceiling, or floor.

The working bound is independent of that final selection and leaves more than 40 decimal orders beyond the requested 34-digit accuracy. Directed modes have the same boundary sensitivity as nearest modes when the exact result is representable or extremely close to a boundary, so no universal exact-final-rounding claim is made.

## Zeros and special values

The context change does not alter the kernel's explicit special-value branches:

- Any NaN input returns `NaN+iNaN`.
- An infinite denominator returns zero for a finite numerator and `NaN+iNaN` for an infinite numerator.
- A zero denominator reaches two `0/0` divisions and returns `NaN+iNaN` when special results are enabled.
- A zero numerator over a finite nonzero denominator returns zero in both components.
- One infinite numerator component uses the existing zero substitution for the other component before evaluation.

The file-driven tests exercise exact and near cancellation, final real34 overflow and underflow, zero operands, existing infinity cases, all seven rounding-mode settings, and both complex scalar/matrix operand orders.

## Context selection and dependencies

The 75-digit context is the narrowest established context that represents every real34 product exactly. The 34-, 39-, and 51-digit contexts cannot provide the required cancellation guarantee. No wider context is needed for real34 operands.

The two public complex scalar/matrix routes now select p75 explicitly. Mixed
real-matrix/complex-scalar routes retain p39 because their exact zero imaginary
coefficient removes component cancellation. Other mathematical functions and
matrix/matrix routes call `divComplexComplex` with contexts selected for their
own operand precision. Those callers require separate error analyses because
their operands are not necessarily Real34 values.

## Independent and runtime verification

An independent 160-digit decimal calculation produced the near-cancellation references in `division_complex.txt`. With 39-digit working arithmetic, the two small components retained about 6 correct digits. A 51-digit trial retained about 18. With 75 digits, the simulator produced the first 34 digits of both independent references and exact zero for both exact-cancellation cases.

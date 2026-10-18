# Decimal context analysis for basic arithmetic

## Scope

This analysis covers the user-visible Real34 routes for addition, subtraction,
multiplication and division, plus the component-wise complex routes which need
only one real operation per component.  It also maps angle-tagged and
scalar/matrix dispatch for these four operations.  The cancellation-sensitive
complex kernels and matrix products retain their separate analyses.  Time,
date and strings are outside this analysis. Mixed integer routes are included
where they produce a Real34 scalar or complex component.

The accepted result model permits a 39-digit intermediate followed by a
34-digit conversion even when that sequence differs at the final digit from a
single 34-digit operation.  None of the routes below needs that allowance.

A single p34 operation has no conversion-cost penalty and is the appropriate
implementation when it directly selects a Real34 result.  Repeated p34 work in
one dependency chain can add unpacking and repacking work; such a chain can
benefit from a p39 intermediate.  Addition and subtraction have no such chain:
each scalar or matrix component needs one operation.  The two components of a
complex result are independent.

## Error model

Let `RN34` denote one correctly rounded operation in `ctxtReal34`, using the
selected rounding mode.  Each finite real34 operand is represented exactly
when supplied to that operation.  The requested assumptions therefore give

```
fl34(x + y) = RN34(x + y)
fl34(x - y) = RN34(x - y)
fl34(x * y) = RN34(x * y)
fl34(x / y) = RN34(x / y)
```

for division by a non-zero value.  The error is at most one half ulp for the
nearest modes and less than one ulp for directed modes.  The result is already
the required 34-digit value, so a wider intermediate cannot improve it.

Cancellation in subtraction, or in addition of opposite signs, can make the
relative error arbitrarily large.  It does not weaken the result claim because
the p34 operation rounds the exact difference or sum directly to the result
lattice.  The absolute error retains the ulp bound, and an exactly
representable cancellation residue is returned exactly.

A context narrower than 34 digits cannot return every real34 result.  For
example, an exact 34-digit input plus zero requires all 34 digits, as do an
exact product by one and an exact quotient by one.  `ctxtReal34` is therefore
both sufficient and minimal.

## Public routes

The following routes already use the 34-digit wrappers and need no source
change:

- `addRealReal` and `subRealReal` when neither operand has an angle tag;
- `mulRealReal` when both operands have no angle tag, or both have angle tags;
- `divRealReal` for an untagged numerator;
- `addRealCplx`, `addCplxReal` and `addCplxCplx`;
- `subRealCplx`, `subCplxReal` and `subCplxCplx`;
- `mulRealCplx` and `mulCplxReal`;
- `divCplxReal`.

Complex addition and subtraction apply one correctly rounded real operation to
each component.  Multiplication or division by a real scalar does the same.
The component bounds are therefore identical to the scalar bounds.  A tiny or
zero component does not depend on the size of the other component.

The wide `addComplex` and `subComplex` helpers keep the context supplied by the
caller.  Their consumers include solver and graph calculations whose values
can have more than 34 digits.  Replacing that context with a fixed p34 or p39
context would narrow those consumers.

A long integer can contain more digits than any fixed decimal work context.
The mixed long-integer addition and subtraction routes therefore align the
integer and Real34 coefficients exactly, perform one integer operation, and
convert the result directly to Real34.  This also covers the affected real
component of a complex value.  The route avoids an initial p39 conversion
which can erase a small cancellation residue.  Angle-tagged operands retain
the p39 conversion chain because angular-unit conversion is also required.

Mixed long-integer multiplication uses the same scaled-coefficient model. The
integer and each finite Real34 component are multiplied exactly with an
unbounded internal integer, then converted directly to Real34. This removes
the Long-to-p39 pre-rounding and leaves one result conversion. Signed zero is
the exclusive-or of the operand signs. NaN and infinity retain the established
decimal path, and angle-tagged scalar multiplication retains its p39 unit-
conversion chain.

Nonintegral Long/Long division and the untagged mixed Long/Real division routes
use exact signed coefficients and decimal exponents. Integer division produces
34 result digits plus digit 35. A nonzero remainder adds a sticky indicator,
which distinguishes an exact midpoint or lattice value from an inexact value.
The compact coefficient is then converted once to Real34 under the selected
rounding mode. Exact Long/Long quotients remain long integers. Zero-denominator,
special-value and angle-conversion paths retain their established handling.

An untagged ShortInteger is exactly representable as Real34. Mixed
ShortInteger/Real addition, subtraction, multiplication and division therefore
convert the integer once and apply the single result operation directly at
p34. The earlier p39 operation followed by a Real34 conversion could select
the adjacent value at a rounding boundary without adding useful accuracy.
Angle-tagged routes retain p39 because unit conversion makes them chained
calculations.

## Multiplication and division contexts

The public context choices are:

| Route | Context | Reason |
| --- | --- | --- |
| real × real, real / real | p34 | One correctly rounded result operation |
| real × complex, complex × real, complex / real | p34 per component | Independent result components |
| complex × complex | p39 | Compensated two-product sums |
| real / complex | p39 | Squared-norm denominator and two products |
| complex / complex | p75 | Exact 68-digit products before possibly severe cancellation |
| one angle and one real | p39 | Arithmetic and angle conversion form one dependency chain |
| two angles | p34 or p39 | Direct multiplication is one p34 operation; division converts one angle at p39 first |

The p39 complex-multiplication selection follows
[the complex multiplication analysis](decimal-context-complex-multiply.md).
The p75 complex-division selection and its cancellation bound follow
[the complex division analysis](decimal-context-complex-division.md).

For real divided by complex, let `u` be the working unit roundoff.  There is no
component cancellation: the two numerators are `ac` and `-ad`, while the
denominator is `c^2 + d^2`.  The denominator relative error is at most
`2u + u^2`; including the numerator multiplication and final division gives a
relative error below `4.01u` for p39.  This is below `2.01e-38`, leaving more
than four guard digits for a Real34 result.  The accepted p39-to-p34 boundary
exclusion applies.  At p34 this bound exceeds half an output ulp, so p39 is the
narrowest suitable established context for the chained formula.

## Matrix routes

The matrix/matrix helpers apply `real34Add` or `real34Subtract` once to each
result component.  Real-matrix conversion to a complex matrix adds an exact
zero imaginary component.  The direct scalar/matrix routes likewise perform
one p34 operation on each affected component; an unchanged component is copied
or has its sign changed exactly.  Thus every component has the scalar error
bound, and p34 is minimal for the same 34-digit identity example.

Repeated element visits are independent rather than one arithmetic dependency
chain.  The single-operation cost rule therefore supports p34 for these routes.
Matrix dimensions are checked before component arithmetic.  A mismatch reports
the matrix error and preserves the input registers.

Mixed ShortInteger/matrix routes first convert the scalar exactly to Real34 and
then reuse these p34 Real34/matrix operations. This removes duplicated p39
loops and prevents a second rounding at the output boundary. Complex-matrix
addition and subtraction affect only the real component; multiplication and
division follow the existing Real34 scalar paths.

Mixed LongInteger real-matrix addition, subtraction, multiplication and
division apply the exact scaled-coefficient helpers independently to each real
component. This retains a small cancellation residue and the correct final
product or quotient digit even when the LongInteger exceeds the p39 input
width. Special matrix components keep the established decimal fallback.

An angle tag on a Real34 scalar is deliberately treated as metadata in matrix
addition and subtraction.  The stored numeric coefficient is applied to every
matrix element without angle conversion, and matrix results have no angle
tag.  Existing matrix fixtures establish the same behaviour for degree and
multiple-of-pi tags in both operand orders.

Multiplication and division use the same raw-number rule for a tagged matrix
scalar.  The element callback receives an untagged copy of the scalar value.
Consequently `7:Deg` and `7:MultPi` both act as the coefficient 7; neither is
converted to the current angular mode.  This established behaviour is retained.

Real matrix scaling uses one p34 multiplication or division per component.
Complex matrix scaling by a real value either uses independent p34 component
operations or the p39 general complex helper.  The latter is a chained
calculation, so p39 is a useful work format under the conversion-cost rule.
Both choices satisfy the 34-digit result requirement outside the accepted
p39-to-p34 boundary cases.

When one matrix operand is real and the scalar operand is complex, one factor
has an exact zero imaginary component.  The p39 complex helper then has no
numerator cancellation and the `4.01u39` division bound above applies.  No p75
work is needed for those mixed routes.

For a complex matrix and a complex scalar, either operand order can make a
quotient component the difference of two 68-digit products.  The former p39
dispatch retained only about five correct digits in the new cancellation
examples.  Both public routes now use p75, the narrowest established context
which represents every input product exactly.  This change applies to
componentwise scalar/matrix division only; matrix/matrix division remains with
the matrix linear-algebra implementation.

## Specials and exponent limits

NaNs, infinities, signed zero, overflow, underflow and subnormal values use the
project Real34 wrappers and the selected p34 rounding mode.  No wider
coefficient precision changes the required IEEE result.  With special results
enabled, signed zeros and non-finite values are retained component by component.
The real zero-denominator path now delegates its result to `real34Divide`, so
the quotient sign is the exclusive-or of both operand signs and a NaN numerator
remains NaN.  The result angle mode follows the same rule as the finite path:
only an angle numerator divided by an untagged real keeps an angle result.
With special results disabled, result adjustment reports a positive or negative
infinity error and restores the inputs; ordinary zero results use the project's
positive-zero convention. Mixed LongInteger/Real and ShortInteger/Real zero
divisors follow the same decimal policy. This preserves the denominator sign,
including a ShortInteger negative zero in one's-complement or sign-and-
magnitude mode, and keeps a NaN numerator as NaN. The same adjustment visits
every real or complex matrix element.

## Angle-tagged routes

The angle-tagged scalar paths which need unit conversion combine arithmetic
with `convertAngleFromTo` and use `ctxtReal39`.  Their error includes the
conversion factor and any range reduction, so the single-operation argument
above does not establish a narrower context for those paths.  Keeping p39 also
avoids conversions between chained p34 operations.  Direct multiplication of
two angles remains one p34 operation and is cost-neutral.  Division of an
untagged real by a tagged value deliberately uses the stored numeric divisor
and produces an untagged result.  The accepted p39-to-p34 boundary rule applies
when a converted result is stored.

## Verification

The existing file-driven suites exercise the covered routes:

- `addition_real.txt` and `addition_complex.txt`;
- `subtraction_real.txt` and `subtraction_complex.txt`;
- `addition_realMatrix.txt` and `addition_complexMatrix.txt`;
- `subtraction_realMatrix.txt` and `subtraction_complexMatrix.txt`;
- `multiplication_real.txt` and the real-scalar cases in
  `multiplication_complex.txt`;
- `division_real.txt` and the real-scalar cases in `division_complex.txt`.

The four corresponding `*_shortInteger.txt` files include 34-digit boundary
checks for every untagged mixed ShortInteger/Real operation and both division
operand orders.

The multiplication/division closure adds cases to `division_real.txt` and
`division_complexMatrix.txt`.  The real cases cover all sign combinations for
finite and infinite numerators over signed zero, NaN over both zero signs, all
four signed-zero numerator/denominator pairs, both zero signs over NaN, and
angle-result tags.  The
matrix cases place the scalar complex-division cancellation examples in both
operand orders.

On the former source, five new cases failed: three zero-denominator results and
both matrix cancellation results.  The p39 matrix results retained about five
correct digits in their small components, with relative errors near `2.5e-6`
and `2.9e-6`.  Production p75 and wrapper-based zero handling satisfy every
new case.

The addition/subtraction subset contains 495 successful function invocations.
The new cases use exact subtraction and scaling by `1e40` to expose result digit
34 despite the file tester's normal comparison tolerance.  They cover all
seven selected rounding modes, cancellation to `1e-33`, signed zero, NaN,
infinity, matrix overflow restoration, matrix dimension errors, mixed scalar
routes and both matrix types.  Further cases cancel an 80-digit long integer
against `1e79`, leaving `+1` or `-1` in both operand orders and in real and
complex results.

The mixed multiplication cases cover all seven rounding modes in both scalar
operand orders, both complex-scalar orders, and the three signed-zero sign
combinations. The exact products distinguish a nonzero discarded tail from a
false midpoint or false lattice value introduced by a p39 integer conversion.
The division cases cover nearest, directed and signed-zero results for
Long/Long, Long/Real and Real/Long. They include p39 false midpoints and false
lattice values even where both input coefficients fit in 39 digits.

As a width discriminator, an isolated p33 mutation of `addRealReal` fails five
addition cases; the corresponding `subRealReal` mutation fails five subtraction
cases.  Residuals after scaling reach `9e7`.  Production p34 succeeds in every
case, and no source-width change is warranted.

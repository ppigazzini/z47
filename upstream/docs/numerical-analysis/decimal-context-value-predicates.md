# Decimal context analysis for value predicates

## Scope

This analysis covers the public predicates and type-code operation in
`checkValue.c`, plus the integer predicates in `int.c`. It includes scalar
real and complex values, time and date values, real and complex matrices,
signed zero, NaN, infinity, and type errors. Integer arithmetic remains
outside the analysis; integer representation checks are included because
they are part of these predicates.

Differences caused only by shortening a p39 result to p34 and then to Real34
are outside this audit.

## Context selection

| Route | Selected context | Reason |
| --- | --- | --- |
| type, angle, matrix, square-matrix, and vector predicates | no decimal context | only tags and matrix dimensions are inspected |
| finite-number predicate | no decimal context | Real34 classification macros inspect each scalar component |
| real and imaginary zero predicates | no decimal context | each stored component is tested for zero without conversion |
| NaN, infinity, and combined-special predicates | no decimal context | project Real34 classification wrappers inspect scalar or matrix components |
| exact signed-zero predicates | no decimal context | zero and sign are representation properties |
| ordered zero-side predicates | no decimal context | sign and NaN classification determine the result |
| `TYPE` integer codes | no decimal context | the integer result is constructed by GMP |
| `TYPE` fractional codes | p34 | one exact division by 1000 constructs the public Real34 code |
| integer predicates on long and short integers | no decimal context | conversion to GMP and parity tests are exact |
| integer predicates on Real34 | p75 classification, then p39 truncation in the shared conversion helper | both operations are exact for a stored 34-digit input |

The classification routes have zero numeric error. They neither approximate a
value nor choose a decimal rounding mode. The revised component-zero route
also avoids the earlier conversion of long integers at p75 and short integers
at p34. Long-integer zero is tested by GMP, short-integer zero is tested after
exact sign-and-magnitude decoding, and Real34 components use `real34IsZero`.

The integer-predicate helper imports at most 34 Real34 coefficient digits into
`real_t`. Its shared `realIsAnInteger` test currently uses p75, and a
fractional input is then truncated toward zero at p39. Both widths preserve
the entire stored coefficient, so parity and the integer/fraction result are
exact. A representation-only integer test would need no decimal context, and
p39 would be sufficient for any Real34-only intermediate. This audit leaves
the wider shared helper unchanged because its other callers can supply wider
`real_t` values. Long and short integer inputs use no decimal context on this
route.

`TYPE` constructs every fractional code as an integer smaller than 10000 and
divides it by 1000. The denominator is a power of ten, so the p34 operation is
exact in every rounding mode. A single p34 operation is cost-neutral under the
project performance model and directly creates the public Real34 result.
There is no chained p34 arithmetic here; widening the division would add no
accuracy.

All decimal classification calls now use the project wrappers in
`realType.h`. No bare decQuad or decNumber operation remains in
`checkValue.c`.

## Correctness repairs

### Scalar complex zero storage

The exact signed-zero predicate formerly obtained a scalar `complex34_t`
through `REGISTER_COMPLEX34_MATRIX_ELEMENTS`. That macro advances beyond a
matrix header and therefore addressed bytes after the scalar value. Both
`0 + 0i` and `-0 - 0i` consequently produced false in the file-driven
checks. The scalar route now uses `REGISTER_COMPLEX34_DATA`.

The established complex rule is retained: both components must be zero, and
at least one component must have the requested sign. Real, time, and date
values require the value itself to be zero with that sign. Long zero has only
a positive representation; supported signed short-integer zero
representations continue through exact decoding.

### Unordered NaN

The ordered predicates named `x` less than or equal to negative zero and `x`
greater than or equal to positive zero formerly inspected only the sign bit.
A positive NaN therefore selected the latter result and a negative NaN
selected the former. NaN is unordered, so both predicates now reject either
NaN sign. Signed zeros, finite values, and infinities retain their sign-based
results. Complex values and matrices remain type errors for these ordered
predicates.

### Short-integer type code

The short-integer `TYPE` route formerly obtained the base through the angular
mode accessor. Its four-bit mask removed bit 4, changing hexadecimal base 16
to zero and returning `8.00`. The route now uses
`getRegisterShortIntegerBase`, so the public code is `8.bb` for every
supported base. The subsequent exact p34 scaling is unchanged.

## Matrix and special-value behaviour

The NaN, infinity, and combined-special predicates scan every component of a
real or complex matrix and stop after the first match. Scalar complex values
are true when either component matches. Time and date values use their stored
Real34 classification. These scans perform no decimal arithmetic and are
independent of exponent range and rounding mode.

`NUMBR?` retains the existing finite-value policy: long and short integers,
finite real and complex values, and finite time and date values are true;
special values, strings, configurations, and matrices are false. Matrix and
vector type predicates inspect only the type tag and dimensions. The 2D and
3D vector predicates continue to reject complex matrices.

## Verification

The existing `checkval_cov.txt` and `mathmisc_cov.txt` files now convert
predicate information to `1` or `0` in X before comparison. The cases cover
all public type tags available to the file driver, real and complex matrix
shapes, all four component-zero modes, both exact-zero signs, ordered zero
sides, NaN signs, infinities, time and date values, finite-number policy,
integer modes, and exact `TYPE` values.

With the earlier source, four focused cases produced the wrong Boolean value:
both scalar complex zero signs and both NaN orderings. The hexadecimal type
case returned `8.00` instead of `8.16`. The revised focused set succeeds in
all 153 checks with no GMP allocation remaining. The clean comprehensive set
succeeds in all 18,192 checks, also with no GMP allocation remaining.

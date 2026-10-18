# Decimal context analysis: exact complex-component transforms

## Scope

This audit covers `fnChangeSign`, `fnConjugate`, `fnRealPart`,
`fnImaginaryPart` and `fnSwapRealImaginary`, including their scalar and matrix
dispatch. Short-integer and long-integer arithmetic is outside the audit. The
full-precision long-integer conversion used by the three component-producing
routes is included.

The direct Real34 routes are:

| Function | Real input | Complex input |
|---|---|---|
| `fnChangeSign` | `a -> -a` | `(a,b) -> (-a,-b)` |
| `fnConjugate` | `a -> (a,-0)` | `(a,b) -> (a,-b)` |
| `fnRealPart` | `a -> a` | `(a,b) -> a` |
| `fnImaginaryPart` | `a -> 0` | `(a,b) -> b` |
| `fnSwapRealImaginary` | `a -> (0,a)` | `(a,b) -> (b,a)` |

Real and complex matrices use the same component maps. Conjugation promotes a
real matrix to a complex matrix, as before. Real-part and imaginary-part
extraction map a complex matrix to a real matrix. Change-sign and component
exchange keep the matrix dimensions.

## Exactness and context selection

A Real34 component contains at most 34 decimal digits. `real34Copy` copies its
128-bit encoding and `real34ChangeSign` changes only the sign bit. Setting an
exact zero also needs no arithmetic context. Therefore every map in the table
has zero numerical error before the public SDIGS boundary:

```
computed component = exact component
absolute error      = 0
relative error      = 0 for a nonzero finite component
```

This remains true at both Real34 exponent limits. Subnormal values are copied
without scaling. Infinity and NaN components are copied or have only their sign
bit changed. Signed zeros therefore retain the exact signs selected by the
operation and `FLAG_SPCRES` policy.

No p34, p39, p51 or p75 work context is needed when SDIGS is 34. In particular,
widening a component to `real_t`, applying the transform there and repacking it
cannot improve its accuracy. The revised full-precision routes operate on the
stored Real34 values directly.

At full output precision, real-part extraction, conjugation and component
exchange convert a long integer directly to Real34. The former
Long-to-p75-to-Real34 sequence could round twice. Reduced-SDIGS conversion
retains its wide source so the requested shorter result is selected directly.

When SDIGS is below 34, conjugation and component exchange call
`roundToSignificantDigits` once for each output component with `ctxtReal34`.
The input coefficient has no more than 34 digits. The exponent adjustment in
that helper is exact, its integral conversion is the sole rounding operation,
and the repack to Real34 is exact. P34 is therefore sufficient for all seven
rounding modes. This is a single p34 result operation and is cost-neutral under
the Real34 packing rule; there is no chained p34 calculation.

Change-sign and real or imaginary extraction use `adjustResult` for their
established result checks. Its shared SDIGS conversion currently uses p75 even
though the input is already Real34. P34 is sufficient by the same argument,
but narrowing that shared conversion requires an audit of all `adjustResult`
callers and is not a local change to these functions. This p75 use is an output
conversion, not a mathematical intermediate. Final p39-to-p34 double rounding
does not arise in this family.

## Special values and signed zero

The public policies differ by operation and are retained:

- Change-sign applies `adjustResult`. With special results disabled, an
  infinite result reports overflow and a zero is made positive. With special
  results enabled, every component sign is reversed, including zero and
  infinity.
- Conjugation and component exchange are representation transforms. They copy
  infinity and NaN without evaluating them. Conjugation reverses the imaginary
  sign. With special results disabled, a zero imaginary component is made
  positive after conjugation, matching the previous scalar rule.
- Real-part and imaginary-part extraction apply the ordinary scalar result
  policy. With special results disabled, extracting an infinite component
  reports the matching overflow and restores the input. NaN propagates. With
  special results enabled, the selected signed zero is retained.

The former complex-matrix extraction routes returned an infinite real matrix
while the scalar route reported overflow. Both matrix routes now call
`adjustResult`, so scalar and matrix special-result handling agree.

## Tags, allocation and dispatch

A scalar angular real keeps its tag under change-sign. Real-part extraction
removes an angular tag because the result is an untagged component. Operations
that produce transformed complex components return rectangular, untagged
values. The complex-matrix conjugation and exchange routes now clear a polar
tag after changing stored rectangular components, matching their scalar routes.

The original change-sign matrix dispatch copied every element through a scalar
register and allocated a replacement matrix. Direct matrix sign changes remove
that allocation and every wide conversion. The real-matrix promotion used by
component exchange now checks the allocation result before accessing the new
matrix. Real-to-complex scalar promotion in conjugation and component exchange
also checks the reallocation result before writing either component. Every
successfully allocated temporary matrix is freed on its existing exit route.

## Verification

The focused list contains the five existing file-driven test files. The added
cases cover 34-digit finite components, reduced SDIGS, directed rounding mode,
polar tags, signed zero, NaN, infinity and scalar-equivalent overflow handling.
With the matrix SDIGS and extraction fixes removed, the focused cases report
the component-rounding and special-policy differences. With the fixes present,
all 151 focused checks succeed. The long-integer cases use an 80-digit value
whose p75 rounding lies on the opposite side of a Real34 midpoint.

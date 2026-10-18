# Decimal context analysis for real-type wrappers

## Scope

This analysis covers the decimal arithmetic, conversion, classification, copy,
allocation, and sign wrappers in `realType.c` and `realType.h`. It also covers
the matrix-editor polar-entry conversion that directly crossed the wide-real
and Real34 representations. Decimal-library sources and native binary plotting
arithmetic are unchanged.

## Context selection

| Operation family | Selected context | Reason |
| --- | --- | --- |
| wide-real arithmetic | supplied context | the public macro forwards the supplied pointer without substituting a fixed width |
| wide-real constructors, copies, signs, and classifications | none | these operations edit or inspect an exact representation |
| wide-real string conversion | supplied context | parsing must use the requested precision, exponent limits, rounding mode, and status |
| wide-real to Real34 | p34 | this is the selected-mode Real34 storage boundary |
| Real34 to wide real | none | every decimal128 coefficient and exponent fits exactly in a 75-digit `real_t` |
| Real34 arithmetic and parsing | p34 | each macro directly produces a Real34 value |
| Real34 copies, signs, and classifications | none | decimal128 copy/sign primitives preserve the encoded value without rounding |
| host 32-bit integer conversion | none | at most ten coefficient digits are inspected and fractional digits are omitted exactly |

No arithmetic wrapper can safely narrow a supplied wide context. Its user can
select p39, p51, p75, or another supported width according to the surrounding
algorithm. The wrapper must preserve that selection and its rounding mode.
The file-driven probe uses precision five with downward and ceiling modes to
exercise this forwarding, including an in-place wide-real operation.

P34 is retained for a direct Real34 operation or a conversion into Real34
storage. One such p34 operation is cost-neutral. A chain of p34 calculations
can add repeated unpacking and packing, so a chain should normally use p39 or
wider arithmetic and convert once at its storage boundary. This audit makes no
speed claim for p34 and accepts the project's p39-to-p34 final double-rounding
exclusion.

## Real34 copy and sign operations

`real34_t` has four-byte alignment in the decimal library. Matrix payloads can
therefore occur at addresses that are four-byte aligned but not eight-byte
aligned. The former copy macros cast those addresses to `uint64_t *`, creating
undefined behavior on a valid payload address. `decQuadCopy` has the required
four-byte alignment, preserves every bit of signed zero and NaN payloads, and
supports identical source and destination addresses. Complex copies now use
two such component copies.

The former sign macros edited byte 15, which depended on the host byte order.
The decimal128 copy/sign primitives now implement negation, absolute value,
and sign setting without that byte order. Project predicates retain their prior
definition: positive means a clear sign bit and negative means a set sign bit,
including zeros, infinities, and NaNs.

## Host integer conversion

For a finite decimal value

```text
x = sign * C * 10^e,
```

truncation toward zero needs only the `d + e` integer digits, where `d` is the
coefficient length. A 32-bit result contains at most ten digits. The conversion
now rejects a larger adjusted length, then visits only those at-most-ten
coefficient positions and any appended decimal zeros. Each update checks the
target magnitude before multiplication and addition.

The previous route invoked `decNumberToIntegralValue` with a fixed 75-digit
destination. That decimal operation ignores the context precision and requires
space for any input value. A wider input could consequently write beyond the
destination even when its truncated value needed only ten digits. Direct
coefficient inspection has no decimal rounding error, supports a wider source,
and needs no decContext. NaN and infinity remain errors. Negative finite input
remains invalid for the unsigned route, except negative zero, whose numeric
value converts to zero without an error.

`REAL_MAX_DIGITS` and `REAL_SIZE_IN_BYTES` remain appropriate for wide-real
temporary storage. With `DECDPUN == 3`, the formulas round the coefficient
allocation to a whole unit and the total object size to a four-byte boundary.

## Matrix-editor representation boundary

Polar matrix entry first computes the angle in a p39 `real_t`, then stores that
angle in the matrix's Real34 imaginary component. The former route used
`real34Copy` on the p39 source address, so decimal-number header bytes were
interpreted as a decimal128 encoding. The corrected route uses `realToReal34`.
This is one cost-neutral p34 storage conversion, with the selected Real34
rounding and exponent semantics.

## Error and alias properties

The Real34 arithmetic macros use the decimal128 library's documented in-place
forms. The focused cases cover aliases for addition and fused multiply-add.
Wide arithmetic aliases remain governed by the corresponding decimal-number
operation while the supplied context is unchanged. Copies retain signed zero
and signaling-NaN payload encodings. The wide-to-Real34 test exercises a p75
source that rounds at digit 34, and the Real34-to-wide-to-Real34 case retains
negative zero.

## Verification cases

The durable cases extend `mathmisc_cov.txt`. They cover signed and unsigned
32-bit boundaries, negative zero, NaN, infinity, a 120-digit integer rejection,
a 120-digit fractional source with a valid 32-bit integer part, four-byte-only
Real34 alignment, NaN payload and sign changes, aliases, context forwarding,
p75-to-p34 storage rounding, signed-zero conversion, and matrix polar entry.

Before repair, the unsigned negative-zero case reported an error, the
matrix-editor case produced a malformed angle instead of 90 degrees, and the
120-digit conversions wrote beyond the fixed local destination under Address
Sanitizer. The former 64-bit copy casts also produced alignment sanitizer
reports at the deliberately four-byte-only addresses. The repaired focused
suite succeeds in all 63 cases; Address Sanitizer reports no error in these
cases. Alignment sanitizer reports no Real34-copy issue in these cases; its
output still includes pre-existing unrelated program-list alignment findings.

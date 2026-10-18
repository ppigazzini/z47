# Decimal context analysis for backup decimal values

This analysis covers the `real` and `real34` fields written by
`saveRestoreBackup.c`. It supplements the full-state analysis in
`decimal-context-state-serialization.md`. Native `float` and `double` fields
keep their existing binary conversion routes.

## Stored widths

| Backup type | Values | Parse context | Reason |
| --- | --- | --- | --- |
| `real` | graph bounds, saved X/Y observations | p39 | Graph bounds have 39-digit storage and p39 arithmetic. Saved observations originate as Real34 values. |
| `real34` | histogram bounds and bin count | p34 | The destination is the Real34 storage lattice and the saved token has at most 34 coefficient digits. |

`realToString` writes every coefficient digit in the source `real_t` and
`real34ToString` does the same for Real34. A valid token within the relevant
coefficient and exponent range is therefore exact at the selected width. Its
rounding error is zero in every rounding mode. P39 is the narrowest existing
working context that fits every graph-bound token. P51 and p75 add no digits
to these fields.

The Real34 route is one p34 storage conversion. A single p34 operation is
cost-neutral. Using p39 would add a conversion to Real34 without improving
the stored result. No chained p34 arithmetic occurs here. The accepted final
p39-to-p34 double-rounding exclusion is consequently not involved.

## Validation

Parsing now uses a temporary value and copies it to the destination only when
the conversion is exact and in range. `DEC_Conversion_syntax`, `DEC_Overflow`,
`DEC_Underflow`, or `DEC_Inexact` rejects the field, leaving the reset value
unchanged. An exact subnormal can set `DEC_Subnormal` alone and remains valid;
`DEC_Rounded` without `DEC_Inexact` can also describe an exact coefficient
reduction and remains valid.

The Real34 wrapper uses the fixed p34 context. The implementation saves and
restores all four fixed contexts around that call, so a corrupt field cannot
alter status state used by later calculations. The p39 route uses a local
context copy and does not modify the fixed contexts.

Older backup files represent infinity as the finite-looking tokens
`9.9e9999999` for `real` and `9.9e9999` for `real34`, with an optional minus
sign. These spellings intentionally exceed their finite exponent ranges.
They are mapped to the decimal infinity token before validation, preserving
the file format without treating intentional infinity as corrupt input. NaN,
signed zero, finite extremes, and exact subnormals use the ordinary decimal
tokens.

## Regression evidence

The file-driven backup coverage injects four invalid fields into a genuine
backup: malformed p39 text, a Real34 exponent overflow, a 35-digit Real34
coefficient, and a 40-digit p39 coefficient. Before validation, all four
cases replaced the reset value and the focused result was 5 successful cases
from 9. With staged validation, the invalid fields retain the reset values.
The same coverage checks negative Real34 infinity through the older spelling,
plus maximum finite Real34, signed zero, NaN, wide infinity, and an exact wide
subnormal.

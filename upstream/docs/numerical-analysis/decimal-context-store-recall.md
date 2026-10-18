# Decimal contexts for store and recall

## Scope

This analysis covers Real34, complex34 and matrix routes in `store.c` and
`recall.c`: direct STO and RCL, arithmetic variants, indexed elements, linear
vector elements, and register/vector transfers. Short- and long-integer
semantics are outside this audit and are unchanged.

Native floating-point and graph routes are unchanged. Final p39-to-p34 double
rounding is excluded as requested.

## Context map

| Route | Context | Error before requested SDIGS handling |
| --- | --- | --- |
| Direct STO, RCL, 2STO, 3STO, 2RCL, 3RCL, STOS and RCLS | none | stored representation copied exactly |
| Real34 or complex34 matrix element to register | none | component copied exactly |
| Real34 or complex34 register to vector element | none | component copied exactly |
| Real34 to complex34 vector storage | none | real component copied; imaginary component is exact positive zero |
| STO and RCL arithmetic | context of the selected arithmetic kernel | no extra decimal operation in store or recall |

Direct Real34 copying preserves signed zero, NaN, infinity and an angular tag.
Complex copying preserves both component encodings. No decimal context can
improve those routes. A direct copy also avoids a chained expand-and-pack
sequence. One p34 operation at a Real34 storage boundary is cost-neutral; the
updated direct-copy routes need no arithmetic operation at all.

Integer conversion paths retain their prior dispatch and width choices. The
pure short/long STO arithmetic branch also retains its prior result and error
sequence. This audit neither adds integer source types nor changes integer
rounding or arithmetic.

## Arithmetic variants

STO+, STO-, STO multiplication and STO division dispatch through the public
arithmetic tables. RCL arithmetic uses the same tables with the recalled value
and current X in their documented operand order. Their widths and error bounds
come from [basic arithmetic](decimal-context-basic-arithmetic.md),
[complex multiplication](decimal-context-complex-multiply.md), and
[complex division](decimal-context-complex-division.md). Store and recall add
no rounding after those kernels except requested SDIGS handling owned by
`adjustResult`.

The arithmetic result now receives `adjustResult` before STO writes the target
register. A domain error keeps the target and stack values unchanged. An
infinite result with special results disabled reports overflow before a target
write. Earlier code could write the unchanged X value after division by zero,
or infinity after overflow, because validation occurred after X had been
replaced by its saved value.

Register aliases use the undo image while the arithmetic kernel runs. Focused
cases cover STO+ X and RCL+ Y and check the unaffected stack entry.

## Indexed matrices and vectors

Indexed recall operates on a detached matrix copy, copies one component or
complex pair into X, and does not write that matrix copy back. Indexed store
writes the detached copy back only after successful element conversion.
STOSEQ and RCLSEQ now advance J only after success. An invalid source type
therefore leaves the cursor and matrix unchanged.

A complex value promotes a real matrix only when current I and J identify an
element. A rejected out-of-range STOEL now preserves the matrix type. Existing
entries copy unchanged during successful promotion, with exact positive-zero
imaginary components.

Vector recall copies each matrix element to its target register before target
allocation can replace X. Real34 and complex34 register-to-vector transfers
now copy the stored representation directly. Register recall and element
recall remain alias-safe when X is both the matrix source and part of the
destination span.

## Verification

The existing `vecreg.txt`, `matrixelem_cov.txt` and `storercl_cov.txt` files
exercise direct signed-zero, angular-tag, NaN and infinity copies, complex
promotion, real-to-complex zero insertion, arithmetic aliases and rejected
sequential operations.

Fail-before cases show three concrete faults: out-of-range complex STOEL
changed a real matrix into a complex matrix; invalid STOSEQ input advanced J;
and STO division by zero or finite overflow changed the target before error
processing. The revised routes leave affected values and indices unchanged.

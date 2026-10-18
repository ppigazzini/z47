# Decimal context analysis for decimal state serialisation

This analysis covers the Real34, complex34, tagged time/date, and p75
statistical-sum routes in `saveRestoreCalcState.c` and
`saveRestoreBackup.c`. Short and long integers, plotting state, and native
floating-point graph code are outside this audit.

## Exact text routes

`real34ToString` emits the complete decimal coefficient and exponent of a
Real34 value. `stringToReal34` reads that token directly into the same
34-digit format. No arithmetic separates the two operations, so every finite
coefficient and exponent in the Real34 range is reconstructed without error.
The same argument applies independently to both complex components and to
each real or complex matrix element. A finite value's exponent quantum and a
zero's sign are included in the text. Infinity and NaN use the decimal
library's special tokens.

Because every valid token fits its destination format, none of these parses
discards a digit. The exactness result is therefore independent of all seven
rounding modes.

The p34 parse is the required storage-lattice operation. A single p34
operation is cost-neutral, and p39 would add an unnecessary conversion back
to Real34 without increasing fidelity. This is not a chained p34 calculation
or a p34 performance claim.

Full state files write the underlying Real34 values for `Time` and `Date`,
with the datatype recorded separately, so this path has the same zero-error
argument. Register data files deliberately use `THMS` and one of `DYMD`,
`DMDY`, or `DDMY` instead. Those are human-readable semantic transforms. The
bounded date fields and time components are evaluated on the Real34 storage
lattice; the chain is retained for format semantics, not as a speed
optimisation. Lossless archival uses the full-state route.

## Statistical sums

State files write every `real_t` statistical accumulator with `realToString`
and read it with `stringToReal(..., &ctxtReal75)`. P75 is necessary. For
example, p75 represents

```
1 + 1e-70
```

exactly because its coefficient spans 71 decimal positions. A p39 parse
rounds the saved value to `1`; a later subtraction of `1` then produces zero
instead of `1e-70`. The file-driven regression performs this cancellation
after a save and reload. Changing only the sum parser to p39 makes that case
fail with `0E-38` in place of `1e-70`.

The simulator backup has a different representation. Its raw RAM image
contains the p75 sum block, so those values are preserved byte for byte and no
decimal context is involved. The separately written
`SAVED_SIGMA_LASTX/Y` fields originate from Real34 observations and therefore
contain no more than 34 significant digits. Their p39 text parser is the
smallest existing `real_t` context and preserves them exactly; p75 is not
needed there.

The backup's Real34 histogram parameters use a p34 parser and retain the same
storage-lattice reasoning as registers. Its historical finite infinity
sentinels overflow under half-even on restore, because `restoreCalc` resets
the decimal context before reading fields. NaN, finite exponent extremes, and
signed zero use the ordinary complete tokens. The focused backup regression
checks these categories independently of the raw register-memory image.

## Complex data-file separator repair

Human-readable complex export writes `(real+imaginary-unit*imaginary)`. The
old importer treated the first lower-case `i` anywhere in the text as the
imaginary-unit marker. The token `Infinity` itself contains lower-case `i`
characters, so an exported value such as `(Infinity-i0)` was split inside the
real component and its imaginary signed zero became NaN.

`findComplexImaginaryMarker` now skips an `i` belonging to the complete
`Infinity` word and selects the actual marker. It is used both before and
after whitespace removal, retaining the accepted compact and spaced input
forms. No decimal arithmetic or context change is involved.

## Verification discriminators

The existing file-driven serializer coverage now includes:

- complex data-file export/import of positive infinity with imaginary `-0`;
- Real34 maximum finite and minimum subnormal values;
- positive infinity, NaN, and signed zero;
- raw time and date state values and their datatypes;
- p75 statistical cancellation after reload; and
- decimal backup fields at the Real34 range limits and with special values.

With the original marker search, the complex data-file case returned the
numeric failure indicator `0` instead of `1`. With the sum parser deliberately
narrowed to p39, the post-reload cancellation returned zero instead of
`1e-70`. The repaired focused set contains 29 successful cases.

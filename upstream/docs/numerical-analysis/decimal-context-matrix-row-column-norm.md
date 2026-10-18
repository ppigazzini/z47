# Decimal contexts for matrix row, column, and zero norms

## Scope and decision

This analysis covers the `pNorm_0_NNZ`, `pNorm_1_CNORM`, and
`pNorm_inf_RNORM` selectors in `fnPNorm`, their real and complex matrix
routes in `_row_columnNorm`, and the final Real34 result conversion. The
positive integer selectors from two upwards have a separate analysis in
`decimal-context-matrix-p-norm.md`.

The zero selector needs no decimal arithmetic. It counts stored elements
that are not numeric zero and converts the exact integer count to Real34.

The one and infinity selectors retain p39 for each magnitude and sum. P39 is
the narrowest suitable established context among p34, p39, p51, p75, and
p159. P51 and wider contexts add no useful accuracy for the Real34 result.
The public conversion is the only Real34-width operation.

A single p34 operation has no extra cost and remains suitable where it
directly produces a Real34 result. These norms instead form a dependent sum,
so p34 has neither a speed advantage nor enough accuracy. Repeated p34
unpacking and repacking can also increase the cost of the calculation.

## Finite error bounds

For a p-digit half-even working context, define

```text
u_p = 5 * 10^(-p).
```

Each dimension occupies a 12-bit matrix-header field, so a row or column has
at most 4095 elements. For a real matrix, taking an absolute value is exact.
Sequential addition of non-negative finite terms at p39 has the usual bound

```text
gamma_4094 = 4094*u39/(1 - 4094*u39) < 2.048E-35.
```

The complex route first applies the audited p39 magnitude calculation to
each element. Its relative error is below `1.01E-38`. Because all magnitudes
are non-negative, their exact weighted sum has the same relative magnitude
error bound. Including the addition bound gives

```text
(1 + 1.01E-38) * (1 + gamma_4094) - 1 < 2.049E-35.
```

Selecting the greatest computed row or column sum preserves this envelope:
every candidate is inside the same relative interval around its exact sum.
The bound is more than one decimal order below `u34=5E-34`. This supports a
faithful 34-digit result. Differences caused solely by final p39-to-p34
shortening remain excluded by the requested policy.

P34 does not provide this margin. Its 4094-addition bound exceeds `2E-30`.
The exact three-term sum

```text
1 + 5E-34 + 5E-34 = 1.000000000000000000000000000000001
```

is a direct discriminator. At p34 half-even, each small term is separately
at the midpoint below the least retained place, so both additions return
one. P39 represents the complete exact sum. The same construction applies
to complex elements on either coordinate axis. A p34 mutation failed the
real and complex row and column cases; p39 produced every asserted digit.

## Exponent range and result rounding

Finite Real34 components have adjusted exponents from -6176 through 6144.
The p39 context has exponent limits of plus or minus 999999. A sum of at most
4095 magnitudes can increase the adjusted exponent by at most four, so every
finite sum fits the working range. The complex magnitude squares can reach
adjusted exponent 12288, also inside that range. No scaling or wider context
is required.

The p39 operations use their fixed internal rounding. Final conversion uses
the selected calculator mode for each of the seven modes. Hence a positive
finite result beyond the Real34 range becomes infinity or the greatest
finite Real34 value as selected, while a tiny result follows the selected
underflow direction. Signed input zeros contribute positive zero and an
all-zero matrix returns positive zero.

## Zero selector and matrix dimensions

The zero selector is a structural non-zero count rather than a sum. Both
signs of zero are excluded. Infinity, NaN, and either component of a complex
value are counted when the stored element is not numeric zero.

The largest memory pool has 65534 four-byte blocks. A Real34 element takes
four blocks and a Complex34 element takes eight, before register overhead.
Consequently every allocated real matrix has fewer than 16384 elements and
every allocated complex matrix has fewer than 8192. The existing 16-bit
count and element index are therefore sufficient, and every count is exactly
representable in Real34.

## Special values and defect correction

An infinite magnitude makes its row or column sum positive infinity. Any NaN
element makes the mathematical norm NaN. Previously, a NaN sum compared
unordered against the current maximum and was therefore omitted; a later
finite row or column could produce a finite result. The revised real and
complex routes copy a NaN sum to the result and stop the search.

## Verification

The cases are in the existing file-driven `matrix.txt` suite. They cover:

* exact digit-34 real and complex row and column sums;
* the p34 three-term discriminator above;
* NaN propagation in all four row and column routes;
* directed overflow near the upper Real34 range;
* exact subnormal addition;
* zero counts containing signed zeros, NaN, infinity, and the least positive
  Real34 value.

Without the NaN correction, four new cases returned finite values four or
five instead of NaN. With the selected source, all 222 matrix-file cases
succeed. Under the deliberate p34 mutation, the four scaled digit checks
failed with residual magnitude `1E7`.

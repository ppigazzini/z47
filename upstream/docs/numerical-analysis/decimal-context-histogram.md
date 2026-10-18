# Decimal context analysis for histogram construction

This analysis covers `fnConvertStatsToHisto`, `fnSetLoBin`,
`fnSetHiBin`, `fnSetNBins`, and `convertStatsMatrixToHistoMatrix` in
`src/c47/stats.c`. The plotting route is outside the change. Values enter the
statistics and histogram matrices on the Real34 lattice, including values
supplied by matrix input.

## Stored parameters and domain

The low bound, high bound, and bin count are public Real34 state. Converting a
setter input once to Real34 is therefore the required storage operation, and a
single p34 operation is cost-neutral. The converted bounds must be finite and
ordered `low <= high`. Equal bounds retain the existing degenerate definition:
all half-open bins are empty and the inclusive final bin contains observations
equal to the bound.

The bin count must be a finite positive integer no greater than 4095. The upper
limit follows from the 12-bit `matrixRows` field. Fractional, zero, negative,
NaN, and infinite counts report `ERROR_INVALID_INTEGER_INPUT`; a larger integer
reports `ERROR_OUT_OF_RANGE`. An invalid setter input leaves the stored
parameters and existing histogram unchanged. Automatic infinite bounds report
`ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN` because finite bin centres cannot be
formed.

For automatic selection, the row count `N` is an exact integer with
`N <= 4095`. The default count is `ceil(sqrt(N))`. If `N` is not a square, its
square root differs from the adjacent integer by more than

```
1 / (sqrt(N) + floor(sqrt(N))) > 1 / 128.
```

The p39 square root is therefore far from a ceiling boundary. P39 remains the
minimum useful intermediate context for this dependent square-root and ceiling
calculation. A p34 chain has no performance advantage and is not needed for
public storage semantics.

## Bin centres

For bin `i`, zero based, the implementation evaluates the barycentric form

```
m_i = ((2n - 2i - 1)L + (2i + 1)H) / (2n).
```

This avoids subtracting nearly equal bounds and then adding the result to a
large bound. The integer factors are at most 8191. Multiplying a 34-digit bound
by a four-digit integer needs at most 38 significant digits, so both products
are exact at p39. The fused sum has one rounding and the division has one
rounding. With `u39 = 10^-38` as the maximum relative error of a directed p39
operation, the nonzero-centre working error is bounded by

```
2 u39 + u39^2 < 2.00000000000000000000000000000000000001e-38.
```

An exact zero numerator remains zero. Thus p39 leaves more than four decimal
guard digits before the Real34 conversion. The accepted p39-to-p34 boundary
effect is excluded from the claim. P34 cannot establish the same result: two
rounded p34 operations have an error comparable with a Real34 unit, and the
dependent p34 chain is not a speed optimisation. P51 and p75 add no useful
margin for Real34 bounds.

## Edge classification

The mathematical interior edge is

```
E_j = ((n - j)L + jH) / n,       0 < j < n.
```

Division and a rounded bin width are unnecessary. The new comparison uses the
sign of

```
D_j = n x - (n - j)L - jH.
```

Each of the three integer-scaled terms is exact at p39. They are ordered by
absolute magnitude before addition. If the comparison is well conditioned,
the largest term determines the sign. Near an edge, the two largest terms have
opposite signs and are combined first, so cancellation exposes the smaller
decimal term instead of discarding it. At an exact edge the intermediate sum
equals the remaining exact product and the final sum is exactly zero. Equality
therefore selects the upper half-open bin, while the high bound remains
inclusive in the final bin.

The fixed half-even p39 context makes this discrete classification independent
of the user's result-rounding direction. A deliberate p34 substitution changes
the exact-edge example

```
L = 1.234567890123456789012345678901234
H = 1.234567890123456789012345678901243
n = 9
x = 1.234567890123456789012345678901236
```

from bin 2 to bin 1 because its scaled products need 35 significant digits.
The file-driven test reports two count failures under that mutation. This
establishes p39 as the narrowest available classification context. The tests
also cover an interior `1/2` edge generated from a recurring `1/6` width,
opposite exponent spans of 12000 decades, and cancellation to the minimum
Real34 subnormal.

NaN observations compare unordered and are not counted. Infinite observations
are outside every finite configured interval. Counts cannot exceed 4095, so
the single p34 increment is exact and is an appropriate cost-neutral Real34
operation.

## Allocation and verification

The histogram matrix is resized to `n` rows once, then its centres and counts
are populated. This replaces repeated one-row resizing, which copied an
increasing matrix for every bin. The statistics matrix is linked again after
the resize because pool movement can relocate its data.

Before the source repair, the first 54-case focused file reported 30 successful
tests and 24 failures. Those failures include incorrect exact-edge counts,
rounding-direction dependence, unchecked count parameters, lost histogram
state after invalid input, and the two exponent-imbalance cases. The completed
file also verifies equal bounds, matrix-fed Y selection, centre values, special
bounds, and the p39 discriminator described above.

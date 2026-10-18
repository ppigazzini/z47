# Decimal context analysis for statistical range

This analysis covers `fnRangeXY` in `src/c47/stats.c` for Real34 observations,
including observations supplied through a real matrix. Short- and long-integer
inputs are outside this audit.

## Arithmetic and context

The statistical accumulator records each minimum and maximum by comparison and
copy. For Real34 observations these four extrema are therefore exact Real34
values held in the wider accumulator representation. The two public results
are

```
range_x = maximum_x - minimum_x
range_y = maximum_y - minimum_y.
```

Each expression contains one subtraction and is immediately converted to a
Real34 result. Subtraction is correctly rounded in the supplied context, so
the selected p34 context computes the required public result directly. Its
exponent limits are also the required result limits: a range above the maximum
finite Real34 value receives the mode-selected infinity or finite endpoint,
and a representable subnormal range is retained.

P39, p51, and p75 cannot improve this one-operation result. A single p34
operation has no conversion penalty; the unpack/repack concern applies to
chains of p34 operations, which are absent here. P39 could also introduce the
accepted p39-to-p34 boundary discrepancy before the result conversion.

## Special values and verification

The existing minimum-data check is unchanged. A matrix observation is stored
as Real34 before its extrema are accumulated, so it follows the same argument.
The established accumulator policy for NaNs and infinities is not altered by
the context change.

The existing file-driven `statsx_cov.txt` test now includes two observations
whose X range is twice the maximum finite Real34 value and whose Y range is
`1E-6176`. All seven result modes verify the overflow selection and the exact
minimum-subnormal range. The ordinary finite range cases remain in the same
file.

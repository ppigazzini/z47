# Decimal context analysis for matrix row and column sums

## Scope

This analysis covers `fnRowColSum` for real and complex Real34 matrices.  Each
output element is one row or column sum.  Matrix norms, decompositions, inverse
calculations, and eigenvalue calculations require separate analyses.

The selected implementation uses a p39 compensated accumulator for ordinary
rows and columns.  A component is recomputed at p75 when cancellation removes
more than 20 decimal places.  Real and imaginary components have independent
cancellation tests, while a complex sum recomputes both components together.

## Compensated summation

For every finite input `x`, the implementation uses a magnitude-ordered
FastTwoSum step

```text
s = RN_q(a+x)
e = x-(s-a),
```

where `a` is the current main sum.  Magnitude ordering makes `s+e=a+x`
error-free for half-even decimal arithmetic.  The low terms enter a separate
correction, followed by one final addition.

This is the Neumaier compensated sum analysed by Ogita, Rump, and Oishi in
[Accurate Sum and Dot Product](https://doi.org/10.1137/030601818).  For `n`
summands, unit roundoff `u`, exact sum `S`, and
`A=sum(abs(x_j))`, its forward bound is

```text
|computed-S| <= u*|S| + (3*n^2/4+n)*u^2*A,
```

provided `3*n*u <= 1`.

Available matrix storage limits a real row or column to fewer than 16384
elements and a complex row or column to fewer than 8192 elements.  The
second-order coefficient is therefore below `2.02E8`.  With
`u39=5E-39`, its absolute multiplier is below `5.05E-69`.

The implementation also accumulates `A`.  If the exponent difference between
`A` and the computed component is at most 20, the component condition number
is below about `1E21`.  The second-order relative term is then below
`5.1E-48`, while the leading relative term is `5E-39`.  P39 therefore retains
more than four decimal guard places before Real34 conversion on the primary
route.

If the exponent difference is larger, or a non-zero magnitude sum produces
zero, the component is recomputed at p75.  The p75 second-order multiplier is
below `5.05E-141`.  This gives at least six decimal guard places for condition
numbers through `1E100`.  No fixed context can cover every cancellation ratio
permitted by the complete Real34 exponent range.

## Context selection

P34 is not suitable for the primary accumulator.  The same bound has a leading
term of `u34=5E-34`, with no full output-digit margin.  In addition,
`ctxtReal34` uses the selected user rounding mode, whereas the error-free
transformation requires nearest arithmetic.  P39 is the narrowest established
primary context among p34, p39, p51, and p75.

P51 is not sufficient for the cancellation retry.  The sequence

```text
1E60 + 1 + 1E-60 - 1E60 - 1 = 1E-60
```

loses the remaining low term in a p51 two-term accumulator.  P75 retains it.
The file-driven checks multiply the matrix result by `1E60`, producing one, so
the usual comparison tolerance cannot conceal a zero result.

Only the final conversion to Real34 uses the selected rounding mode.  The p39
and p75 working operations use half-even rounding.  Differences caused solely
by shortening a boundary-adjacent p39 or p75 value to Real34 are excluded under
the requested double-rounding policy.

## Special values

NaN and infinity use ordinary addition.  When a main sum becomes non-finite,
its finite correction is cleared.  This preserves the arithmetic
classifications of the former implementation, including NaN for opposite
infinities.  Special components do not request a p75 retry because a wider
finite context cannot change their classification.

## Regression evidence

The existing `matrix.txt` file covers real and complex row and column sums.
It includes `1E100+1-1E100` and the p75 discriminator above.  The former
ordinary p39 implementation succeeds in two of the eight focused checks.  The
selected p39/p75 implementation succeeds in all eight.  Replacing p75 with
p51 succeeds in six of eight, with both amplified discriminator results equal
to zero instead of one.

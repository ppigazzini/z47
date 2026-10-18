# Decimal contexts for comparison, error predicates, minimum and maximum

## Scope

This audit covers the public scalar comparison functions, complex equality and
inequality, matrix equality, `MIN`, `MAX`, the register comparison service used
by structured programs, the `CONVG?` error predicate, and the decimal helpers in
`comparisonReals.c`. Integer pairs retain their GMP comparison route. Mixed
Real34 and long-integer ordering is also included because it affects public
predicates, structured programs, `MIN`, and `MAX`.

The public result of a predicate is Boolean. `MIN` and `MAX` copy one source
register, including its type and tag, rather than computing a new decimal.
Consequently there is no final p39-to-p34 conversion in these functions.

## Exact decimal comparison

`realCompare` maps to `decNumberCompare`. In extended mode the operation does
not round either operand. Its finite result is one of `-1`, `0`, and `1`, so the
context precision does not limit the inspected coefficients. A quiet NaN
produces a NaN result. The former dynamically widened p75 or p159 contexts in
the `real_t` comparison helpers therefore provided no accuracy benefit.

The revised helpers use a private copy of `ctxtReal39` for `real_t`
comparisons. This is the narrowest useful standard internal context in this
code base. The private copy prevents a NaN comparison from recording a sticky
invalid-operation status in a shared arithmetic context. A single native p34
operation has no extra conversion cost and is appropriate when it directly
implements Real34 storage or result semantics. P34 has no performance benefit
over p39 for an extended `real_t` operation, however, and repeated
packing/unpacking can make a chained calculation slower. It is therefore not
selected as an internal optimisation for the extended helpers. The native
`real34Compare` helpers remain appropriate where both operands already occupy
Real34 storage: p34 expresses the stored-value semantics and no extended
arithmetic chain is introduced.

Magnitude comparison first makes an exact sign-cleared copy in storage sized
for the operand, then performs the same context-independent comparison. The
p75 or optional p159 storage capacity remains necessary even though the
comparison context is p39. `realIsAnInteger` is different: it computes an
integral value and a subtraction, so its adaptive p75 or p159 context remains.
Its established infinity classification is also retained because division,
power, and root algorithms use it as a category test.

All ordered helpers now test the NaN comparison result explicitly. A NaN is
unordered regardless of its sign bit, so each less-than and greater-than form,
including the magnitude forms, returns false. Numeric equality also returns
false. The internal `realCompareIdentical` special-value equivalence is
retained because it forms part of the calculator cache-key contract.

A finite Real34 value and a long integer now compare through their signed
integer coefficients and decimal exponents. The coefficients are aligned with
a power of ten and compared by GMP, so every integer digit contributes. The
former conversion of the long integer to p75 could map both `10^80-1` and
`10^80+1` to the Real34 value `10^80`. Public predicates then reported
equality, and `MIN` or `MAX` could select the wrong source register.

The integer-coefficient route applies only to an untagged real or to a tag that
matches the current angular mode. A differing angle tag still uses the common
unit conversion described below. Time values also retain their hours-to-seconds
conversion. Special Real34 values use the decimal path, preserving the existing
unordered NaN and infinity behaviour.

One root special case formerly depended on a positive NaN being reported as
greater than zero: a zero base with a NaN root order returned zero. With
unordered comparison semantics that expression has no defined root order and
returns complex NaN, consistent with the corresponding nonzero-base cases.
Date and time range checks now reject NaN explicitly, preserving their public
range errors without relying on a NaN sign bit.

## Tagged real values

An untagged real is interpreted in the current angular mode when compared with
an angle. A tagged angle is converted to that same mode before comparison.
This agrees with real addition and subtraction. It also prevents values such as
`180 DEG` and `200 GRAD` from being ordered by their unrelated stored
coefficients.

Degree, DMS, grad and multiple-of-pi conversions use factors drawn from
`9/10`, `180`, and `200`. Multiplying a p34 coefficient by these factors needs
at most 37 significant digits, so p39 represents the rational conversion
exactly. Radian conversion is more demanding because it introduces pi.

Consider the valid Real34 integers

```
p = 2660986268060398033024932428949292
q =  847018236122935192166388903710609
```

Their exact separation is

```
p - q*pi = 1.62645109392816310146199931056979e-34...
```

They are a continued-fraction pair for pi. A p51 pi error, after multiplication
by `q`, can be about `4.3e-18`, which is much larger than this separation. At
p75 the constant and multiplication errors are below about `1e-41` at this
magnitude, under every supported rounding direction. The p75 result therefore
retains at least seven decimal places of margin for this discriminator. A
mutation using p51 reverses its ordering in the file-driven test. Among the
established p39, p51 and p75 contexts, p75 is the narrowest supported choice
for conversions to or from radians. Other angle conversions use p39.

Time registers store seconds. Comparison with an untagged real interprets the
real as hours, so the time value is divided by 3600 at p39. The equivalent
integer comparison multiplies the p34 hour coefficient by 3600, which needs at
most four more significant digits. P39 therefore has one further decimal place
of margin after accounting for the rational scale. The extended exponent range
also prevents an intermediate range fault for every finite Real34 time value.

## Complex and matrix values

Complex values have no ordering. Equality is the conjunction of component
equalities; inequality is its negation. The former sequential implementation
used the selected predicate on each component, so complex inequality required
both components to differ. A difference in only one component incorrectly
returned false. The revised conjunction fixes that defect and gives the usual
NaN result: equality is false and inequality is true.

Matrix equality retains the established rule that two NaN elements compare
equal. Real and complex matrices are now inspected through their native linked
storage. A real component is paired with an exact zero imaginary component for
mixed comparisons. The former route allocated complex copies of real matrices,
so a read-only equality check could fail because memory allocation failed.
Native Real34 comparison is exact for the stored elements and needs no
arithmetic context.

Program comparisons against literal zero and one use a temporary scalar
register. The old type dispatch required a matrix on both sides, making the
special zero-matrix and identity-matrix helper unreachable. Dedicated
matrix/scalar dispatch entries now reach it for equality and inequality only.

## Minimum and maximum

The extrema functions use IEEE `minNum` and `maxNum` behaviour for numeric
registers. One quiet NaN does not displace a number; two NaNs produce a NaN.
For equal zeros, minimum selects negative zero and maximum selects positive
zero. The former generic trinary comparison interpreted a NaN result through
its sign bit and retained an aliasing-dependent zero, so both behaviours
depended on operand order.

Tagged time and angle comparisons use the common-unit contexts derived above,
then copy the selected original register without changing its coefficient or
tag. Strings retain lexicographic comparison. Complex numbers with a nonzero
imaginary component and matrices remain invalid extrema operands.

## `CONVG?`

The tolerance is `10^-d`, where `d` is the selected significant-digit count,
capped at 32. Real subtraction, division, and complex magnitude use p39. For
p34 inputs this gives at least seven decimal working places beyond the smallest
`1e-32` tolerance. A subtraction near cancellation is favoured by the decimal
format; when exponents differ enough to require rounding, the relative error is
at most one p39 unit before the division. The stable complex division and
magnitude helpers use the same or wider established context. P34 offers no
performance benefit for this chained calculation and would remove the working
margin, while p51 adds no useful discrimination to a predicate whose user
tolerance stops at 32 digits.

The existing mode flags deliberately decide whether NaN and infinity count as
converged. Those special-value rules are unchanged. The numerical predicates
remain strict: an error must be less than the tolerance.

## Verification

The existing `compare_cov.txt`, `min.txt`, and `max.txt` files now check:

- complex inequality with either or both components changed;
- scalar and helper NaN rules, including shared-context status isolation;
- rational and radian tagged-angle comparisons, including the p75 pi case;
- zero-matrix and identity-matrix literals, plus mixed real/complex matrices;
- signed-zero and quiet-NaN extrema in both operand orders;
- tagged time extrema and representative `CONVG?` numeric and special modes;
- date and time NaN range handling, plus the zero-base, NaN-order root case
  affected by unordered comparison;
- mixed Real34 and long-integer values immediately above and below `10^80`,
  in both operand orders, plus a differing angle tag.

Before the fixes, the complex single-component inequality, NaN predicates,
tagged-angle comparisons, matrix literals, signed-zero extrema and one-NaN
extrema checks failed. The p51 angle mutation fails the continued-fraction
check. With the selected contexts and algorithms, all 251 focused checks
succeed.

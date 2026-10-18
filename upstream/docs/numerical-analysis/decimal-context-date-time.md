# Julian date/time decimal contexts

## Scope and result

This audit covers `fnDateTimeToJulian` and `fnJulianToDateTime` in
`dateTime.c`.  The long-integer entry is outside the numeric scope.  Calendar
composition and decomposition retain decimal128 arithmetic because their
supported operands and results are integral.

| Route | Working context | Reason |
| --- | --- | --- |
| Date and time to Julian value | 39 | Three operations form a 34-digit result; centring at noon avoids severe cancellation |
| Julian value to date and time | 39 | A decimal128 fraction multiplied by 86,400 has at most 39 coefficient digits |
| Final Julian storage | 34 | The selected calculator mode is applied at the public boundary |
| Final time storage | integral milliseconds | Calendar time is rounded half-up to 0.001 second |

P39 is the narrowest established project context for both real routes.  P34
has measured failures in each direction.  P51 and p75 add no benefit after the
stable rearrangements.  The accepted p39-to-p34 boundary discrepancy is
outside this analysis.

## Date and time to Julian value

Let `D` be the integral Julian day assigned to noon and let `t` be the stored
time in seconds.  The revised route evaluates

```text
J = D + (t - 43200)/86400
```

at p39.  The former ordering evaluated `t/86400 + D - 0.5` at p34.  Near noon
on Julian day zero, the first division rounded a value close to 0.5 before the
subtraction.  For

```text
D = 0
t = 43200.00000000000000000000000000001
```

the mathematical result is

```text
1e-29 / 86400
= 1.157407407407407407407407407407407...e-34.
```

The former route produces `1e-34` in nearest mode and `2e-34` in the upward
modes.  The centred p39 route retains all decimal128 digits in every selected
mode.

For `21600 <= t < 86400`, the subtraction from 43,200 is exact by Sterbenz's
lemma.  Below that interval the subtraction condition factor is at most three.
The division adds at most one p39 rounding, and addition of the fractional day
to `D >= 1` has condition factor at most three.  When `D = 0`, addition by zero
is exact.  A conservative finite normal-result bound is below `3u39`, or
`1.5e-38` relative, before decimal128 storage.

The stored time is now converted directly.  The former call through
`timeToReal34(3)` applied an HMS display-oriented rounding stage.  A time of
`1e-17` second became zero there, changing the Julian result after its 21st
significant digit.  Direct conversion preserves the decimal128 operand.

P34 does not provide a multi-operation margin.  With

```text
D = 2
t = 21474.47936660504671413507398122672
```

the correctly rounded decimal128 result ends in `...4569`.  A p34 division
followed by the day addition ends in `...4568`.  The file-driven case subtracts
the reference and scales by `1e33`, exposing the one-unit error.

## Julian value to date and time

For a finite Julian input `J`, define

```text
n = floor(J)
f = J - n,  0 <= f < 1.
```

The calendar convention places noon at integral Julian values.  The revised
route therefore uses two regions:

```text
f < 0.5:  date = n,     ms = 43200000 + roundHalfUp(f*86400000)
f >= 0.5: date = n + 1, ms = roundHalfUp((f - 0.5)*86400000).
```

Adding an integral number of milliseconds commutes with half-up rounding.
Rounding the fractional contribution before adding 43,200,000 therefore
preserves which side of a half-millisecond boundary the input occupies.  It
also removes the former divide-by-86,400 and multiply-by-86,400 pair.

The fractional extraction is exact for a decimal128 Julian operand in the
supported date range.  Where `f >= 0.5`, subtraction of 0.5 is exact by
Sterbenz's lemma.  Multiplication by the five-digit integer 86,400 creates at
most 39 coefficient digits, so p39 represents the product exactly.  Scaling by
1,000 changes only the decimal exponent.  The subsequent integral operation
therefore applies the specified half-up millisecond rule to the exact product.

The former p34 addition of 0.5 could erase low positions before fractional-day
extraction.  The decimal128 value one unit below 13.5 milliseconds after noon,

```text
0.0000001562499999999999999999999999999999,
```

was classified as the midpoint and produced 12:00:00.014 rather than
12:00:00.013.  P34 is also insufficient for the product itself.  For

```text
J = 0.3004984432870370370370370370370370,
```

the exact fractional millisecond value is
`25963065.4999999999999999999999999968`.  P34 rounds it to the midpoint and
produces 19:12:43.066; p39 retains the correct 19:12:43.065 result.

NaN and either infinity do not denote a calendar date.  These inputs now
return the existing range error before integral or calendar decomposition.
The former arithmetic produced unrelated finite date and time values.

## Verification

The focused `dtToJ` and `jToDT` set contains 58 file-driven checks; all succeed
with no GMP allocation active.  The former date-to-Julian ordering fails all
seven new epoch rounding-mode cases.  Its HMS conversion stage also fails the
`1e-17`-second case.  The former Julian-to-date/time ordering fails the
one-unit-below-midpoint case.  Deliberate p34 substitutions independently fail
the date-to-Julian digit-34 discriminator and the Julian-to-time multiplication
discriminator.

The added cases remain in the existing file-driven test files.  They cover all
seven result modes, the Julian epoch, the earliest supported midnight, stored
time precision, exact and adjacent half-millisecond values, and the p34
context discriminators, plus NaN and both infinities.  No auxiliary test
script is added.

A clean repository test run succeeds for all 17,510 checks, with zero failures
and no GMP allocation active.  Compilation emits only the existing linker
section-alignment warning.

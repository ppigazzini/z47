# Unit-conversion decimal contexts

## Scope and result

This audit covers the numeric kernels in `conversionUnits.c`: multiplicative unit
conversion, reciprocal fuel-economy conversion, temperature conversion, angle-unit
scaling, and the power/field-ratio conversions.  Calendar and time representation
are outside this audit.

| Route | Working context | Reason |
| --- | --- | --- |
| One multiplication or division | 34 | The operation itself is the final decimal128 rounding |
| Reciprocal factor `c/x` | 34 | It is one division after the factor has been formed |
| Celsius/Fahrenheit affine routes | 39 | A two-operation affine result needs guard digits; multiplication by 1.8 is exact at p39 |
| Fahrenheit/kelvin affine routes | 39 | Stable forms place the potentially severe cancellation before the division |
| Other temperature routes | 34 | Each route is one basic operation |
| Fuel-economy factor construction | 39 | Two or three operations form a reusable factor before the p34 quotient |
| Ratio to or from decibels | 39 | These routes inherit the audited `log10` and `10pow` contexts |

The p34 choice is exact with respect to the stored conversion coefficient and the
selected calculator rounding mode, subject to the project assumption that a basic
operation is correctly rounded at its context width.  The accepted p39-to-p34
boundary discrepancy is outside this analysis.

## Multiplicative conversions

An ordinary conversion has either

```text
y = x*c
```

or

```text
y = x/c.
```

There is no later arithmetic before decimal128 storage.  Evaluation at p34 therefore
produces the selected decimal128 result directly.  P39 adds an intermediate rounding
without improving the mathematical result.  P34 is also the minimum useful width for
a 34-digit result.

Every registered reciprocal conversion requests the multiplication direction, so its
formula is

```text
y = c/x.
```

The former code first evaluated `1/x` at p39 and then multiplied by `c` at p39.  The
revised code evaluates the quotient once at p34.  The private opposite-direction case
retains a p39 product before its final p34 reciprocal.  Fuel-economy helpers still form
their nontrivial factors at p39; only the closing quotient narrows to p34.

At zero input, a reciprocal conversion now exits immediately after the domain error
when special results are disabled.  With special results enabled, the quotient
operation produces the correctly signed infinity without an earlier register write.

## Temperature conversions

Let `u39 = 5e-39` for nearest p39 arithmetic.  The Celsius/Fahrenheit and
kelvin/Fahrenheit pairs use

```text
F = 1.8*C + 32
C = (F - 32)/1.8
K = (F + 459.67)/1.8
F = 1.8*K - 459.67.
```

A decimal128 coefficient multiplied by the exact two-digit value 1.8 has at most 35
coefficient digits, so that product is exact at p39.  Its following addition or
subtraction has at most `u39` relative error for a nonzero normal result.  In each
division route, the addition or subtraction occurs first; two correctly rounded p39
operations then contribute less than `1.01e-38` relative error.  This leaves more than
four decimal guard orders before decimal128 storage.

The old Fahrenheit-to-kelvin ordering was

```text
(F - 32)/1.8 + 273.15.
```

The division error is proportional to a value near 273 when the final kelvin value is
near zero.  Its relative contribution to the small result is unbounded.  For

```text
F = -459.6700000000000000000000000000001
```

the exact result is

```text
-1 / 18000000000000000000000000000000
= -5.555555555555555555555555555555555...e-32.
```

The former route produces `-5.5556e-32`, only five correct significant digits.  The
stable ordering `(F + 459.67)/1.8` preserves the small numerator and produces the full
decimal128 result in every output mode.

P34 is not suitable for every affine route.  For example,

```text
C = -17.77777777777777777777777777777778
```

gives `F = -4e-33`.  A p34 multiplication rounds `1.8*C` to `-32` before the addition,
giving zero.  P39 retains the 35-digit product and the nonzero result.  This makes p39
the narrowest established project context for the four affine routes.  Celsius to
kelvin, kelvin to Celsius, Rankine scaling, Rankine/Fahrenheit translation, and the
Boltzmann conversion each contain one operation and now use p34.

## Ratio conversions

Power and field ratios use the already-audited p39 `log10` and `10pow` kernels.  The
factors 10 and 20 do not create a new conditioning issue.  Their context therefore
remains p39.  The hour/HMS entry delegates to the audited time-conversion routines.

## Verification

The final focused set contains 1,990 file-driven checks from `tempConv`, `angleConv`,
`conversions`, and `conversionsSI`; all succeed with no GMP allocation active.  The
former Fahrenheit-to-kelvin route succeeds in 25 of the final 32 temperature checks,
with one failure in every rounding mode.  A deliberate all-p34 affine mutation
succeeds in 1,989 of the 1,990 focused checks and loses the `-4e-33` Celsius-to-
Fahrenheit discriminator.

The added cases use the existing file-driven suite.  They cover every final rounding
mode for a one-operation angular conversion and for the near-zero Fahrenheit-to-
kelvin result, the p34 affine discriminator, and reciprocal zero with special results
both disabled and enabled.  No auxiliary test script is added.

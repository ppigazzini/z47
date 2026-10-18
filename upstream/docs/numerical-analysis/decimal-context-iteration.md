# Decimal-context analysis for iteration counters

## Scope and selected contexts

This analysis covers finite and special Real34 counters, encoded Real34 range counters, and time counters. Short- and long-integer arithmetic is outside the scope.

| Entry route | Selected arithmetic | Reason |
|---|---:|---|
| `ISZ` and `DSZ`, plain Real34 | p34 | One correctly rounded addition or subtraction produces the stored Real34 value. |
| `ISE`, `ISG`, `DSE` and `DSL`, encoded Real34 | p34 | Parameter extraction and every update are exact for the documented format. |
| `ISZ` and `DSZ`, time | p34 | One correctly rounded addition or subtraction of 3600 seconds produces the stored Real34 value. |

The encoded Real34 comparison now uses `real34Compare`. Comparison produces only `-1`, `0` or `1`; it introduces no rounding error. The former generic register
comparison converted two Real34 values to wide reals and selected p39, which was unnecessary for this route.

## Encoded Real34 parameters

For a finite input `x`, parameter extraction uses

```
c = trunc(x)
f = abs(x - c)
t = trunc(1000 f)
d = trunc(100 (1000 f - t))
```

and replaces a zero `d` with one. The counter update is `c+d` for the increment forms and `c-d` for the decrement forms. The fractional parameter field is then
attached with the sign of the updated counter.

A Real34 coefficient has at most 34 decimal digits. Truncation of `x` is exact. When `abs(x) < 1`, `x-c` equals `x`; otherwise the subtraction removes leading integer
digits and leaves a suffix of the input coefficient. The difference is therefore representable at p34. Multiplication by 1000 and 100 changes only the decimal
exponent in these bounded ranges, and both subsequent truncations are exact. Thus `t` is in `[0,999]` and `d` is in `[0,99]` before the documented zero replacement.

The three target digits and two step digits bound `t` and `d`, while the counter can use the Real34 exponent range. If `f` is nonzero, the coefficient of `x` already
includes every integer and fractional digit. The integer update is exact whenever its result fits in 34 digits; if that update increases the integer length, the
subsequent addition of `f` is the only rounding of the final encoded value. If the integer update itself loses a small step because of an exponent gap, `x` has no
fractional field and no second arithmetic operation follows. Thus the stored update receives at most one rounding at p34 for every finite Real34 input.

The target is at most 999. An updated counter close enough for its rounding to affect that comparison is small and its update is exact. A counter large enough for a
p34 update to round remains unambiguously above or below the target. The target comparison is therefore exact at p34 in every rounding mode, and a wider context
supplies no additional information.

Signed zero is treated as a zero counter before the update. A finite encoded counter stays finite throughout parameter extraction. `NaN` propagates through the
arithmetic. Infinity has no finite parameter field; the subtraction used to extract that field produces `NaN`. These special results do not justify wider arithmetic.

## Time counters

A time counter stores seconds as Real34. `ISZ` adds 3600 and `DSZ` subtracts 3600, after which the existing time rule classifies `abs(t) < 3600` as zero. The update now
uses `incDecTime`, the same p34 operation used by the public increment and decrement functions, and the comparison uses the rounded stored value.

This order matters at the one-hour boundary. For `t=-1e-31`, the exact increment is

```
3599.9999999999999999999999999999999
```

It has 35 significant digits. The nearest modes, away-from-zero mode and ceiling mode round it to `3600`; toward-zero and floor round it to
`3599.999999999999999999999999999999`. Comparing a p39 intermediate instead classified all seven modes from the unrounded value. The five modes which store `3600`
consequently returned the wrong test result. This is a control decision on the stored state, rather than only a difference in the closing conversion.

Fixed half-even p39 arithmetic also discards directed-rounding information for a sufficiently wide exponent gap. For ceiling mode,

```
1e50 + 3600 -> 1.000000000000000000000000000000001e50  (p34 ceiling)
```

The p39 spacing at `1e50` is `1e12`, so a half-even p39 update first rounds the exact sum back to `1e50`. The symmetric decrement of `-1e50` in floor mode has the same
defect. Direct p34 arithmetic applies the selected rounding mode once and retains the required direction.

For signed zero, the update gives exactly `3600` or `-3600`. Infinity remains infinity. `NaN` remains `NaN`; the existing absolute comparison does not classify it as
less than one hour. Decimal128 overflow and underflow follow the selected p34 rounding mode before the time test is evaluated.

## Regression coverage

`src/testSuite/tests/iteration_cov.txt` covers a seven-digit encoded counter, a sign crossing, all seven rounding modes beside the one-hour boundary, directed
wide-exponent updates, signed zeros, infinity and `NaN`. Subtraction from an independently derived wide-exponent value converts a digit-34 discrepancy into a nonzero
residual, so the ordinary result tolerance cannot hide it.

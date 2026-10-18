# Decimal count analysis for string rotation and shift

## Scope and result

This audit covers only Real34 counts supplied to `ARR`, `ARL`, `ASR`, `ASL`,
and `42AROT` in `src/c47/stringFuncs.c`. Short and long integer counts are
outside the audit. These operations return a string, so there is no final
p39-to-p34 numeric conversion.

| Route | Selected arithmetic | Reason |
| --- | --- | --- |
| `ARR` and `ARL` | Exact coefficient/exponent reduction | The modulus is the string length, at most 508 |
| `42AROT` direction | Exact sign, digit-count, and exponent inspection | Only the sign of a nonzero truncated integer is needed |
| `ASR` and `ASL` | One p34 magnitude comparison and one p34 truncation | Values above one million are clamped; every smaller finite integer part is exact |

The rotation change removes the 2,139- or 12,321-digit temporary allocated by
`WP34S_Mod`. No working `decContext` is needed. The shift route is already
bounded and exact, so it is retained.

## Exact rotation reduction

Write a finite Real34 magnitude as

```text
x = C * 10^q,
```

where `C` is the 34-digit coefficient returned in fixed-width BCD and `q` is
the stored decimal exponent. The requested count is truncation towards zero,
followed by absolute value. For a string length `m`, only

```text
floor(abs(x)) mod m
```

is observable.

When `q < 0`, truncation discards the last `-q` BCD digits. If `q <= -34`, the
integer part is zero. Otherwise the first `34+q` BCD digits are scanned with

```text
r_(i+1) = (10*r_i + digit_i) mod m.
```

When `q >= 0`, all coefficient digits are scanned and binary modular
exponentiation supplies `10^q mod m`. Thus

```text
r = (C mod m) * (10^q mod m) mod m.
```

Every step is exact integer arithmetic. Since `1 <= m <= 508`, the largest
square is `507^2 = 257049`, far below the `uint32_t` limit. The digit scan is
34 steps and the exponentiation needs at most 13 squarings for a finite
Real34 exponent. The proof is independent of every decimal rounding mode.

The former route converted the input to `real_t`, requested `WP34S_Mod`, then
converted the p39 remainder to GMP. Desktop builds allocated a 12,321-digit
temporary and evaluated the remainder at p6147. The DM42 fallback allocated a
2,139-digit temporary and evaluated at p2139, which cannot establish an exact
remainder for the largest Real34 adjusted exponents. The direct reduction has
no such context or range dependency.

The sign is deliberately ignored by `ARR` and `ARL`; their names determine
direction. NaN and either infinity retain the established zero-step result.

## `42AROT` direction

`42AROT` selects right rotation exactly when the truncated Real34 integer is
negative. For a finite nonzero coefficient with `d` significant digits, the
integer part is nonzero exactly when

```text
q + d > 0.
```

Consequently the direction test needs only the sign, zero/special predicates,
stored exponent, and digit count. It does not need to construct the integer.
This avoids forming a GMP value with more than six thousand decimal places for
a top-exponent input. It also prevents a special exponent from entering the
generic Real34-to-GMP conversion. Counts in `(-1,0)`, signed zero, NaN, and
infinity select the zero-step left route; negative counts with magnitude at
least one select right. The delegated rotation then uses the exact reduction
above.

## String shifts

`ASR` and `ASL` use the magnitude of the integer truncated towards zero, then
clamp it to the glyph length. The existing first comparison clamps every
finite magnitude above one million and either infinity before conversion.
Every remaining finite integer part has at most seven digits, so the p34
integral conversion is exact. NaN retains the observed zero-count result.

No wider context improves this route. The p34 comparison and truncation each
directly implement Real34 input semantics. A single p34 operation is
cost-neutral; chained p34 arithmetic is not a speed optimisation, but there is
no dependent arithmetic chain here. Replacing the bounded conversion would
increase the source change without improving accuracy or range.

## Verification

The file-driven cases cover negative fractional counts, both named rotation
directions, `42AROT` sign selection, a value in `(-1,0)`, all 34 coefficient
digits, positive and negative exponent extremes, NaN, infinity, and shift
clamping. The exact reference reductions include

```text
10^6144 mod 7 = 1
9999999999999999999999999999999999 * 10^6111 mod 7 = 4
floor(1234567890123456789012345678901234e-30) mod 7 = 2.
```

A deliberately altered modular result makes the focused file fail, verifying
that the new cases detect an incorrect coefficient/exponent reduction. Final
focused and repository-wide results are recorded with the commit evidence.

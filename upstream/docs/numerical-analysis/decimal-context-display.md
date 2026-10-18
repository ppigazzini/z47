# Decimal numeric display contexts

## Scope

This audit covers decimal128 numeric formatting in `display.c`, with detailed
analysis of DMS angles and time values. The ordinary ALL, FIX, SCI and ENG
routes, special values and Real34 exponent limits are included. Long-integer
formatting, polar display conversion and native plotting arithmetic are
outside this audit. Polar display conversion has a separate completed
analysis.

| Route | Working context | Reason |
| --- | --- | --- |
| ALL, FIX, SCI and ENG digit formatting | none | Coefficient extraction and decimal digit operations are exact |
| Finite DMS decomposition | 39 | Two multiplications by 60 can increase a 34-digit coefficient to at most 36 digits |
| Finite time decomposition | 39 | Five guard digits protect hour classification and the chained work has no p34 performance advantage |
| Special DMS and time values | none | They are formatted before finite decomposition |

## Ordinary Real34 formatting

`real34ToDisplayString2` obtains the stored decimal coefficient and exponent
without arithmetic. ALL, FIX, SCI and ENG selection then uses digit-array
indexing, comparison with 5, decimal increment and propagation to the next
displayed position. These operations introduce no decimal arithmetic error.
An `int16_t` exponent covers the full Real34 adjusted-exponent interval from
-6176 through 6144.

The display-only SI-unit and irrational-fraction branches invoke previously
audited mathematical helpers and remain at their established contexts. The
HP and significant-figure branches apply their explicit display precision;
they do not alter the stored Real34 value. This audit does not change those
policies.

## DMS decomposition

A DMS-tagged Real34 contains decimal degrees. The earlier display route first
encoded that value as a Real34 `ddd.mmss` number, then converted the packed
value back to a working real and decoded it. Finite display therefore used
this chain:

```text
decimal degrees -> p39 DMS encoding -> Real34 -> p39 DMS decomposition
```

The revised route decomposes decimal degrees directly:

```text
d = floor(abs(x))
m = floor((abs(x) - d) * 60)
s = ((abs(x) - d) * 60 - m) * 60
```

The input coefficient has at most 34 digits. Subtraction of each integral
part is exact, and each multiplication by 60 adds at most one coefficient
digit. P39 therefore retains the finite value through the centisecond
rounding step. P51 and p75 add no information. P34 can round after either
multiplication, and chained p34 arithmetic has no speed benefit. A single
p34 result operation remains cost-neutral, but this route has no Real34
result boundary.

The removed Real34 encoding was an intermediate storage boundary followed by
more arithmetic. Its p39-to-p34-to-centisecond boundary differences are the
accepted class of double rounding and are not used as defect evidence. The
rewrite is retained because it removes the encode, pack, unpack and decode
work, and because the finite decoder cannot process special values.

Positive infinity, negative infinity and NaN formerly entered the DMS
decoder. Infinity became NaN through infinity-minus-infinity, and all three
values produced a malformed degrees, minutes and seconds string. The revised
route formats a special value once with the degree suffix and performs no DMS
arithmetic.

## Time decomposition

A valid time satisfies `abs(t) < 3.6e19` seconds. Values below the selected
display threshold use ordinary Real34 formatting. The HMS route uses p39 for
division by 3600, the display-oriented integral operation, and extraction of
minutes, seconds and fractional digits.

For a nonintegral hour quotient, the Real34 input lattice places the exact
quotient at least `10^e / 3600` from an integer, where `e` is the stored
coefficient exponent. Relative to the p39 unit in the last position, this is
more than five decimal guard digits throughout the valid time range. Integer
minute and second reduction is exact at p39. Fractional digit extraction uses
decimal exponent changes and subtraction of one extracted digit, so a finite
Real34 fraction terminates after at most 34 digits. P39 is the narrowest useful
working context for this chain. P51 and p75 add no result information, while
p34 offers no chained-work performance gain and reduces the classification
margin.

TDISP 0 rounds the seconds value before HMS decomposition so the displayed
text fits its available positions. The earlier route calculated `h` before
this operation. When rounding increments the value into the next hour, the
minute and second reductions use the incremented value but the hour field
uses the earlier value. For example,

```text
3599.9999999999999995 seconds -> 3600.000000000000000 seconds
```

in 24-hour TDISP 0. The earlier text was `0:00:00`; the mathematical HMS value
is `1:00:00`. The same ordering defect changed
`43199.99999999999995` seconds from noon to `11:00:00a.m.`. The revised route
recalculates the integral hour after TDISP 0 rounding, producing
`12:00:00p.m.`. Other TDISP selections do not use this half-up operation and
need no second hour division.

NaN already bypassed HMS decomposition. The same guard now includes either
infinity, which otherwise produced a finite zero-hour string with spurious
fractional digits. Special time values use the existing direct Real34 text.
The presentation-specific half-up or down choices are independent of the
calculator rounding-mode setting.

## Verification

The file-driven `display_cov.txt` checks ordinary finite DMS text, DMS infinity
and NaN, the 24-hour and 12-hour TDISP 0 transitions, and time infinity and
NaN. With the source changes removed, two of nine checks succeed. The revised
source succeeds in all nine checks.

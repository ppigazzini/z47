# Decimal context analysis for order statistics

This analysis covers median, lower and upper quartile, percentile, median
absolute deviation (MAD), and interquartile range (IQR) in
`src/c47/mathematics/median.c`.

The inputs are Real34 elements copied from the `STATS` matrix. The public
result is converted to Real34 after the calculation. Differences caused only
by a p39-to-p34 final double rounding are outside this audit.

The public functions operate on real statistical observations. Matrix input
is expanded into the real `STATS` matrix before these functions run;
`median.c` has no complex or general elementwise matrix callback.

## Sorting

Comparison does not round either operand. Since every value being sorted is a
Real34 value, p34 is sufficient and p75 adds no accuracy. The comparator now
uses p34.

This comparison is one p34 operation and is cost-neutral. Arithmetic chains
in the median family use p39 or the audited p75 interpolation helper; p34 is
not selected as a speed improvement for those chains.

`decNumberCompare` returns NaN if either operand is NaN. Interpreting that
result as greater in both operand orders violates the strict ordering required
by `qsort`. The comparator now puts NaNs after numeric values and treats two
NaNs as equal. This matches the ordering already used by the complex root
sorter and makes special-value order statistics deterministic.

## Percentile position

For `n` samples the position is

```
t = (n + 1) p,
```

where `p` is the requested percentage scaled into `[0,1]`. A matrix dimension
is a 12-bit value, so `n + 1` is at most 4096 and has at most four decimal
digits. Multiplication of that integer by a 34-digit `p` therefore has at most
38 coefficient digits.
The existing p39 multiplication is exact, including its exponent range. The
integer part, fractional part, and interpolation interval are consequently
selected from the exact position.

P34 is not suitable. With three samples and

```
p = 0.4999999999999999999999999999999999,
```

the exact position is

```
4p = 1.9999999999999999999999999999999996.
```

A p34 multiplication rounds this to 2 and changes the interpolation interval.
The file-driven regression uses samples 0, 1, and 2 and obtains
`0.9999999999999999999999999999999996`, rather than 1. P39 is the narrowest
existing context that evaluates every permitted position exactly. The final
interpolation uses the separately audited p75 `linpol` kernel.

## Median and quartiles

An odd-sized median is an input copy and needs no arithmetic. An even-sized
median is the average of its two central Real34 values. Their sum can require
35 coefficient digits, so p39 makes the addition exact; multiplication by
one half is exact. P34 can also overflow before halving two maximum finite
Real34 values. The regression with two maximum finite values distinguishes
that case. Thus p39 is the narrowest available safe context.

The lower and upper quartiles use the same median kernel on the lower and
upper halves of the sorted array, so the same bound applies.

## MAD and IQR

Each MAD deviation subtracts two values represented with at most 35 exact
coefficient digits before the absolute value is taken. P39 is sufficient for
that subtraction and the second median has the bound above.

IQR subtracts the two p39 quartile results at p39. Correctly rounded
subtraction has relative error at most `u39 = 5e-39` for a nonzero exact
difference and the p39 exponent range contains every finite Real34 result.
P34 supplies no guard margin, while p51 and p75 add no established benefit to
the final 34-digit value.

## NaN percentile parameter

A NaN percentile has no ordered position and must produce NaN. The arithmetic
position route produces NaN, but conversion of that value to `int32_t` returns
zero when its error output is omitted. The subsequent endpoint branch then
returns the minimum sample. `computePercentileSorted` now detects a NaN
parameter before position arithmetic and writes a NaN result for both X and Y.
Finite out-of-range parameters retain the existing endpoint saturation.

## Selected contexts

| Work | Context | Reason |
| --- | --- | --- |
| sorting comparisons | p34 | exact comparison of Real34 inputs |
| percentile position | p39 | exact product of 34-digit `p` and four-digit `n+1` |
| even median and quartiles | p39 | exact 35-digit sum and wide exponent range |
| MAD deviations | p39 | exact subtraction of two Real34 inputs |
| IQR subtraction | p39 | five guard digits for the final difference |
| percentile interpolation | p75 | audited `linpol` dependency |
| NaN percentile parameter | none | direct NaN result before integer position conversion |

The file-driven cases in `stats_cov.txt` cover the interval-selection
boundary, maximum finite averaging, minimum subnormal averaging, and the
defined NaN ordering.

## Verification

With the final 46-case focused set, the unchanged comparator succeeded for 44
cases. Its two failures were the NaN-containing median and upper percentile;
an arithmetic status from the unordered comparisons also reached the public
operation. The p34 comparison and defined NaN ordering succeed for all 46.

A deliberate p34 substitution for percentile-position and even-median
arithmetic also succeeded for 44 of the 46 cases. The position discriminator
left a scaled residual of -4, and averaging two maximum finite values raised
overflow before division by two. The selected p39 arithmetic succeeds for all
46 focused cases.

The current `stats_cov.txt` set contains 168 checks. Without the NaN parameter
guard, 167 succeed and the NaN percentile returns zero in both result
registers. With the guard, all 168 succeed.

A clean repository test run succeeds for 16,481 of 16,481 checks with zero
GMP-owned bytes.

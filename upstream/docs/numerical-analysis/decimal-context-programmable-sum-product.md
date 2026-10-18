# Decimal contexts for programmable sum and product

## Scope and selections

This analysis covers the real and complex `sumprod.c` entries, their programmed-term callback, finite range control, and final Real34 or Complex34 conversion. The indexed long-integer variants are outside scope. A matrix is neither a range control nor one term of these scalar aggregators.

| Route | Work context | Method |
| --- | ---: | --- |
| Real sum | 75 digits | Two-part compensated summation |
| Complex sum | 75 digits per component | Two independent compensated sums |
| Real product | 75 digits | Sequential multiplication with an exact decimal scale kept separately |
| Complex product | 75 digits | Compensated complex multiplication with a common exact decimal scale |
| Counter | 34 digits | The public start, end, and step are Real34 values |

These selections target faithful 34-digit accuracy. They do not claim a universally correctly rounded result for an arbitrarily ill-conditioned sum or an arbitrarily long product. Final working-to-Real34 boundary differences are outside the proof.

## Arithmetic model

For half-even arithmetic at `p` digits, define

```text
u_p = 0.5 * 10^(1-p)
gamma_k = k*u_p/(1-k*u_p).
```

The 39-, 51-, and 75-digit contexts retain the configured exponent interval from `-999999` to `+999999`. User rounding changes `ctxtReal34`; the wider work contexts remain half even. The final register conversion therefore applies the selected user mode after the internal calculation.

Every term supplied by a real program has already been stored as Real34. A complex term has two Real34 components. No extra uncertainty is attributed to reading those values into `real_t`; the program that calculates a term has its own rounding error, independent of the aggregation.

## Compensated sum

Let the terms be `x_i`, the exact sum of their stored Real34 values be `S`, and

```text
A = sum(abs(x_i)).
```

Plain recursive addition has the familiar absolute bound

```text
abs(fl(sum(x_i)) - S) <= gamma_(n-1) * A.
```

It consequently loses a small middle term in a sequence such as `1E100, 1, -1E100`, even though the exact result is one.

The revised calculation uses a leading value and a correction. For each finite term it orders the two operands by magnitude and evaluates FastTwoSum:

```text
s = RN(a + b)
z = RN(s - a)
e = RN(b - z)
```

With `abs(a) >= abs(b)`, radix ten, half-even rounding, and no work-context range loss, `s+e` is the exact sum of the two inputs. The residual `e` is accumulated separately. A closing addition combines the leading and correction values.

The standard compensated-summation bound, using a conservative `gamma_(2n)` for the residual arithmetic, is

```text
abs(result - S) <= u_75*abs(S) + gamma_(2n)^2*A,
```

while `2n*u_75 < 1`. The first term is the closing p75 rounding. The condition-dependent term is second order in `u_75`, rather than first order as in the former recurrence. For `n=10000`, `gamma_(2n)^2` is about `1E-140`. Even a condition number `A/abs(S)` near `1E100` leaves about six decimal places between the error bound and a 34-digit half ulp.

NaN and infinity use ordinary p75 addition instead of FastTwoSum. This retains the established IEEE results, including NaN for opposite infinities. The infinity-sum stopping estimate uses the leading value plus its correction.

## Why the sum stays at 75 digits

No fixed context can certify 34 relative digits when `S` is arbitrarily close to zero. The purpose of the width selection is to preserve the useful cancellation range already supplied by this function.

At p51, the same compensated bound has a `gamma_(2n)^2` term near `1E-92` for ten thousand terms. Real34 terms can differ by far more than 92 decimal places, so p51 cannot establish a 34-digit result over the supported input range. P39 is weaker again. P75 is therefore the narrowest existing context with a defensible bound for the documented ten-thousand-term use and wide-dynamic-range cancellation.

The two components of a complex sum use the same analysis independently. A component close to zero remains ill-conditioned with respect to errors already present in the term program, but aggregation no longer discards a residual merely because another component is large.

## Scaled product

For finite nonzero real factors, sequential p75 multiplication has relative error bounded by `gamma_(n-1)`. The compensated complex-multiplication kernel contributes at most about `2*u_75` per multiplication before propagated input error, so its corresponding normwise accumulation is of order `gamma_(2n)`. A component arbitrarily close to an axis can still be ill-conditioned; this prevents a universal componentwise-relative claim.

P51 would give seventeen work digits beyond the result for a short, well-conditioned real product. The programmable count has no small fixed upper bound, and successive complex rotations can expose a much smaller component. Retaining p75 preserves the prior accuracy range and supplies forty-one work digits beyond Real34.

The former product kept its complete magnitude in one `real_t`. Enough large factors could exceed the p75 exponent interval, and later reciprocal factors could not recover a finite exact result. The revised representation is

```text
product = mantissa * 10^scale.
```

After every finite multiplication, the largest component exponent is removed from the mantissa and added to a signed 64-bit scale. Changing a decimal exponent is exact and does not alter the coefficient, so this transformation introduces no rounding. Before the next multiplication the largest mantissa component has adjusted exponent zero. Combining it with a finite Real34 term stays thousands of decimal places from the p75 range limits.

The common scale is reattached to each component before Real34 conversion. A value beyond the p75 interval is clamped to a representable value that is still beyond the Real34 interval, so the selected Real34 overflow or underflow mode supplies infinity, the largest finite value, zero, or the minimum subnormal as appropriate. The signed scale represents more than `1.4E15` maximum-exponent Real34 factors; exceeding that count reports a range error instead of overflowing the scale arithmetic.

Zero, infinity, and NaN are not normalised. Thus zero times infinity remains NaN, a finite nonzero value times infinity remains infinite, and signed zero is retained. The complex multiplication dependency supplies the corresponding component semantics.

## Range control and types

Start, end, and step stay at Real34 because they are public calculator values and each update is one correctly rounded Real34 addition. All three must be finite. A zero step, a step aimed away from the end, and a step that later rounds away from a growing counter are reported before an unreachable counter can repeat indefinitely.

After every programmed callback, the result type is checked anew. A real term following a complex term receives an exact zero imaginary component. A matrix, string, or other unsupported term is refused through the existing scalar conversion error. This also avoids accessing an imaginary component outside a real register allocation. There is no elementwise matrix route in these functions.

## Verification

The file-driven `pgm_solve_cov.txt` corpus now constructs four additional term programs and checks:

- `1E100 + 1 - 1E100 = 1`;
- 167 factors of `1E6000` paired with 167 factors of `1E-6000`;
- the same factor sequence through the complex-product route;
- unbalanced scale sequences that finish inside the Real34 range or cross its overflow and underflow boundaries;
- a complex term followed by a real term;
- a step that becomes smaller than the counter spacing;
- NaN and matrix range controls.

On the original implementation, the cancellation case returns zero and the scale-balanced product returns zero. The spacing case does not terminate. After the revision, all focused cases complete with their independently derived exact values and error codes.

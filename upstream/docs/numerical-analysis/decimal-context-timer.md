# Timer decimal-context analysis

## Scope

This analysis covers the decimal work in `src/c47/timer.c`: conversion of a
Real34 hour value or tagged time value to the unsigned millisecond counter, and
conversion of that counter to hours for the statistics commands.  The native
monotonic-clock and unsigned counter arithmetic is unchanged.  Long-integer
inputs are outside this audit.

## Context decisions

| Calculation | Context | Reason |
|---|---:|---|
| Real34 hours times 3600 | real39 | A 34-digit coefficient multiplied by the integer 3600 needs at most 38 coefficient positions.  Real39 therefore evaluates this product exactly. |
| Seconds-to-milliseconds exponent change | exact | Changing the decimal exponent by three does not round the coefficient. |
| Conversion to an integral millisecond count | real39 | This consumes the exact real39 product without narrowing it.  The integral operation is followed by exact GMP range classification. |
| Unsigned timer value divided by 3600 for statistics | real39 | The input has at most ten integer digits.  One correctly rounded division at real39 has five guard digits before Real34 sample storage. |

The former integral-conversion context was real75.  It cannot improve the
result: every accepted value is at most 4,294,967,295, while its source has at
most 38 coefficient positions.  Real39 is sufficient for every finite Real34
input to this route.

Real34 is not suitable for the hours product.  For

```
x = 1.388888888888888888888888888888889e-7 hours
```

the exact millisecond value is

```
0.50000000000000000000000000000000004
```

A real34 product rounds this to the exact midpoint `0.5`, which half-even
integral conversion maps to zero.  The exact real39 product maps to one.  This
also establishes real39 as the narrowest project context among real34, real39,
real51 and real75 for the conversion chain.

A single real34 operation is cost-neutral relative to real39.  The choice here
is not based on a claimed cost for that single operation: real39 is required by
the 38-position product.  Chained real34 calculations can additionally incur
Real34 unpacking and packing, so real34 is not treated as a speed shortcut for
the chain.

## Range and special values

The decimal integral value is reconstructed in GMP and classified against the
32-bit unsigned range without rounding.  Both signed representations of zero
denote a zero duration.  A finite negative value, NaN or either infinity is
outside the timer range and produces the existing out-of-range error.

The old code examined only the sign bit after coefficient extraction.  It
therefore rejected negative zero but accepted positive NaN and positive
infinity as zero.  Classification before coefficient extraction removes that
asymmetry and prevents special encodings from reaching the GMP reconstruction.

## Accuracy claim

For Real34 hours, the scaling product and exponent change are exact at real39;
the specified half-even conversion therefore selects the exact integer nearest
to the millisecond value.  Tagged time conversion uses the exact coefficient
and the specified truncation mode.  This route has no final real39-to-Real34
rounding question because its result is an integer no greater than ten digits.

The statistics conversion has relative work error at most `5e-39` from its one
real39 division before Real34 storage.  Differences confined to a final
real39-to-Real34 midpoint are outside the requested analysis.

## File-driven evidence

The additions to `mathmisc_cov.txt` cover half-millisecond boundaries in both
directions, both ends of the unsigned range, tagged time input, signed zero,
negative finite input, NaN and infinity.  With the old special classification,
52 of 56 focused cases succeed and the four signed-zero/special cases fail.
With the revised source, 56 of 56 succeed.  A deliberate real34 product
mutation succeeds in 54 of 56: it returns zero for the positive
half-millisecond discriminator and 100 rather than 99 for the negative-side
discriminator.

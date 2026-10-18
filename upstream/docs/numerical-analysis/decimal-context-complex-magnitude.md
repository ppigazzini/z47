# Decimal context analysis for complex magnitude

## Scope

This analysis covers the public scalar and complex-matrix Real34 result routes
through `magnitudeCplx`, `magnitudeCxma`, `complexMagnitude2` and
`complexMagnitude`. Solver and internal matrix callers are separate because
they can supply wider inputs and use the magnitude inside a larger algorithm.

The implementation evaluates

```
p = RN(a * a)
s = RN(b * b + p)
r = sqrt(s)
```

at 39 digits, then converts `r` to real34.

## Finite error bound

For a nearest-mode decimal context with `p` digits, use
`u = 0.5 * 10^(1-p)`.  Let the exact squared magnitude be
`S = a^2 + b^2`.  The rounded product changes `a^2` by at most `u*a^2`, and
the fused multiply-add rounds its complete sum once.  As all terms are
non-negative,

```
|s - S| / S <= 2*u + u^2 = E.
```

The exact square-root propagation is bounded by

```
|sqrt(s) - sqrt(S)| / sqrt(S) <= E / (1 + sqrt(1-E)).
```

The square-root operation adds at most one further `u` relative error.  At
39 digits, `u = 5E-39`; including the product between the two bounds gives a
total below `1.01E-38`.  This leaves almost five decimal guard digits before
the real34 conversion.

At 34 digits, the same bound approaches `1.01E-33`, so the two rounded
operations plus square root do not retain a complete 34-digit margin.  A
context narrower than 34 digits is also unable to represent all exact real34
magnitudes.  Among the established contexts, `ctxtReal39` is therefore the
narrowest suitable choice.

The accepted 39-to-34 double-rounding difference is outside this decision.

## Matrix result boundary

The scalar route rounds the p39 magnitude directly to the requested SDIGS.
The earlier matrix route instead called `real34RectangularToPolar`, which
packed the p39 magnitude into Real34 before the public SDIGS operation and
also calculated an unused angle. Besides the extra work, that intermediate
packing discarded information needed by a later reduced-precision result.

For the exact Real34 components

```text
a = 1.2345675
b = 1E-17,
```

an independent 120-digit calculation gives

```text
sqrt(a*a + b*b)
  = 1.2345675000000000000000000000000000405000131625042778...
```

This value is greater than the seven-digit midpoint. Direct half-down
rounding therefore gives `1.234568`. Packing it into Real34 first removes the
nonzero suffix and gives the exact midpoint `1.2345675`; a later half-down
operation then gives `1.234567`.

The revised matrix route retains the p39 value through one
`roundToSignificantDigits` operation and then packs the result into Real34.
P39 is sufficient for that exact result conversion and its wide exponent
range. The closing Real34 pack is one p34 result operation and is
cost-neutral. No p34 arithmetic chain is introduced.

## Range and special values

Finite real34 components have adjusted exponents from -6176 through 6144.
Their squares have adjusted exponents from -12352 through 12288, inside the
wide exponent range of `ctxtReal39`.  The working calculation therefore does
not overflow or underflow before the real34 conversion.  An exact zero pair
produces zero.

NaN and infinity results follow the existing multiply, fused multiply-add and
square-root wrapper semantics. No coefficient-width increase changes those
classifications. The matrix entry now applies the same `adjustResult` check as
the scalar entry, so an infinite element reports overflow when special results
are disabled and the saved input is reinstated. With special results enabled,
infinity and NaN remain in the result matrix.

## Decision

Keep `ctxtReal39` in both public complex routes. `ctxtReal51` and
`ctxtReal75` add no useful accuracy for a Real34 result, while `ctxtReal34`
lacks a proven final 34-digit margin for this three-operation route. The real
scalar and real-matrix absolute-value routes change a stored sign exactly and
need no work context.

## Verification

The existing `magnitude.txt` file covers scalar and matrix finite values,
Real34 exponent limits, reduced SDIGS under all seven rounding modes, signed
zero, NaN and infinity. With the matrix result changes removed, the combined
magnitude and rectangular-to-polar focus succeeds in 46 of 56 checks. The
revised source succeeds in all 56 checks.

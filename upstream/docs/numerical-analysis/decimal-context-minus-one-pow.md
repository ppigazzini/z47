# Decimal context analysis for `(-1)^x`

## Scope and selected contexts

This analysis covers the public Real34 and Complex34 entries in
`src/c47/mathematics/minusOnePow.c` and their elementwise matrix use. Short
and long integer arithmetic is outside this audit.

| Route | Selected work | Reason |
| --- | ---: | --- |
| real exponent reduction | p39 | the remainder modulo two is exact for a Real34 input |
| non-axis real phase and result | p39 | five guard digits protect phase formation and the two trigonometric components |
| complex phase and magnitude arguments | p51 with the p75 pi constant | p39 argument rounding can change result digit 34 near the Real34 range limits |
| exact half-integral phase | p39 sector selection, p51 magnitude | avoids a spurious nonzero component at a mathematical axis |
| matrices | the corresponding scalar entry | matrix dispatch adds no arithmetic |

The former p75 real multiply adds no accuracy because its pi operand has 39
digits and the result is immediately consumed at p39. The revised complex
route is narrower than p75 while also improving accuracy by selecting the p75
pi constant. P39 and p51 are the narrowest established contexts among 34, 39,
51, and 75 digits for their respective routes. Differences confined to the
accepted p39-to-p34 final conversion boundary are excluded.

## Arithmetic model and reduction

For normal p-digit arithmetic, let

```text
u_p = 0.5 * 10^(1-p).
```

For a finite decimal128 exponent `a`, reduction by the exact integer two is
performed with thousands of digits before conversion to p39. The exact
remainder has at most the 34 coefficient digits of `a`, so this conversion is
exact. Write the result as `r`, with `abs(r)<2`.

For a real exponent,

```text
(-1)^a = cos(pi r) + i sin(pi r).
```

The p39 pi constant and one correctly rounded p39 multiplication give

```text
abs(delta theta) < 2 pi (2 u39 + u39^2) < 6.3E-38.
```

The audited trigonometric dependency performs its main reduction at p12321,
retains the reduced angle at p75, and evaluates the series at p51. Combining
its conversion error with phase formation and the p39 result conversion gives
a conservative unit-vector norm error below `9E-38`. P39 therefore leaves
more than four decimal guard digits. P34 phase formation has no such margin;
a deliberate p34 substitution fails five of the seven digit-34 checks for
`a=0.3`.

Integral remainders zero and plus or minus one return exact real results.
Half-integral remainders use the exact axis route described below. Other
inputs use the p39 Euler-formula dependency.

## Complex exponent

For `z=a+ib`,

```text
(-1)^z = exp(-pi b) (cos(pi a) + i sin(pi a)).
```

The real component is reduced modulo two before phase formation. The revised
route multiplies both reduced `a` and unreduced `b` by the p75 pi constant in
p51 arithmetic. The constant error is below `u75`; each p51 product contributes
at most `u51` relative error.

For a result that converts to a finite nonzero Real34 value,
`abs(pi b)` is below 15,000. The magnitude-argument error is therefore below
`7.6E-47`. The audited exponential contributes at most one p51 unit, and the
trigonometric phase error is below `3.2E-50` radians before its series error.
Closing p51 products add at most `u51` each. A conservative normwise relative
error bound for the non-axis complex result is below `8E-47`, leaving more
than twelve decimal guard digits.

P39 is insufficient for this route. With

```text
b = 3761.751044149136135028268255,
```

p39 argument formation returns

```text
3.596054980265096478362269974449670E-5133
```

instead of the independently evaluated 34-digit value ending in `671`. The
former p75 arithmetic also cannot recover information absent from its p39 pi
operand. At

```text
b = 3963.379136779662610338866812,
```

that route returns a value ending in `472` instead of `473`. P51 with the p75
constant succeeds for both inputs; p75 arithmetic adds no required margin.

## Exact axes and special values

When `2r` is integral, the phase lies on a real or imaginary axis. The former
transcendental route approximated pi and left a small unwanted component. For
example, the real component of `(-1)^0.5` was about
`-1.4153E-39`, and the same defect appeared after complex magnitude scaling.

The revised route maps `2r` into the sector interval `[0,4)` and places the magnitude directly
on the selected axis. A real exponent uses the exact magnitude one. A complex
exponent computes `exp(-pi b)` at p51 and then applies the exact sector. This
also defines the axis limits for infinite `b` without multiplying infinity by
an approximate trigonometric zero. Both zero signs follow the selected axis.

NaN behavior is unchanged. An infinite real exponent still becomes NaN after
reduction. For a finite non-axis real component beside infinite `b`, the p51
Euler route supplies the limiting signed zeros or infinities. Real and complex
matrices apply these same paths to each element.

## File-driven evidence

All new cases are in `src/testSuite/tests/minusOnePow.txt`. They include all
seven output modes at digit 34, the two complex magnitude adversaries, exact
positive and negative half-integral axes, negative integral exponents, signed
zero and infinity axis limits, and existing matrix cases.

The earlier implementation succeeds in 64 of the final 73 focused checks.
Its nine failures cover negative integral handling, exact finite and infinite
axes, signed zero, and the p39-pi magnitude case. A deliberate p39 complex
substitution fails the separate `b=3761.751...` case, and a deliberate p34
real substitution fails five mode checks. The selected implementation succeeds
in all 73 focused checks.

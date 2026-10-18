# Linear interpolation decimal context

## Scope and result

This audit covers `linpol`, the public `LINPOL` entry, real and complex decimal128 coefficients, and the time, date, angle, and scalar combinations that
use the same numeric kernel. Finite scalar interpolation involving a long integer is evaluated as an exact scaled-integer polynomial before the final
decimal128 conversion. Other converted operands continue to use the existing wide conversion context.

The finite kernel retains `ctxtReal75`. Linear interpolation can cancel two exact 68-digit products to a decimal128-sized residue. P51 loses that
residue, so p75 is the narrowest established project context. The revised code also evaluates infinite endpoints according to their interpolation
weights and gives exact precedence to `p=0` and `p=1`.

| Route | Working context | Reason |
| --- | --- | --- |
| Finite same-sign endpoints | 75 | `a + p*(b-a)` can cancel during extrapolation |
| Finite opposite-sign endpoints | 75 | `(1-p)*a + p*b` can cancel two products containing up to 68 coefficient digits |
| Infinite endpoints | 75 for `1-p` | The exact sign is determined by the two finite weights; no magnitude arithmetic is attempted |
| Complex coefficients | 75 per component | The real and imaginary components use the same scalar kernel |
| Finite scalar route containing a long integer | Exact scaled integers | `a + p*(b-a)` is formed without an intermediate decimal conversion |
| Final decimal128 value | 34 | The selected calculator rounding mode is applied at conversion |

Differences confined to the accepted p39-to-p34 conversion boundary are outside this analysis.

## Wide integer operands

A long integer can contain more than 75 decimal digits. Converting it before interpolation can therefore discard a low-order difference between two
endpoints, or round a parameter before an otherwise identity operation. The finite scalar path converts each decimal operand to a signed integer
coefficient and decimal exponent, then forms the subtraction, product, and addition exactly. Only the completed value is converted to decimal128.

This route is selected only when at least one scalar operand is a long integer. Decimal128-only calculations retain the p75 kernel, while angle,
time, date, complex, NaN, and infinity behaviour is unchanged. Focused directed-rounding cases place two 81-digit endpoints one unit apart; their
midpoint now rounds to the correct adjacent decimal128 value. Identity cases also show that a wide endpoint or parameter is converted only once.
Exact endpoint selection preserves a signed zero, and the exact polynomial is rounded directly to the configured result precision.

## Finite arithmetic and the p51 rejection

For endpoints with different signs, the implementation uses two fused operations:

```text
x = fma(-p, a, a)
r = fma( p, b, x)
```

This is `(1-p)*a + p*b`. For decimal128 `a`, `b`, and `p` in the interpolation interval, each product has at most 68 coefficient digits. P75 can retain
each product and their cancellation before the final conversion. The same-sign path uses

```text
d = b - a
r = fma(d, p, a).
```

This form is monotone between finite same-sign endpoints and keeps the small endpoint difference before multiplication. Extrapolation can still be
ill-conditioned when the exact result is close to zero, which is why that path also uses p75.

The focused discriminator uses

```text
M = 10000000000000000000000000000000000
P = 3141592653589793238462643383279503
A = 1669324476710274429562172822101162
B = 3644300365144359323354466838840005

a = -A
b = B
p = P/M
```

These integers obey the exact identity

```text
P*(A+B) - A*M = 1.
```

Therefore the interpolation result is exactly `1/M = 1e-34`. The p75 kernel returns `1e-34`. A deliberate p51 substitution returns
`-1.0746206787082485e-18`, losing the residue and its sign. The p51 focused result is 24 successes from 25 checks. P39 and p34 provide still fewer
coefficient digits, and p34 also has insufficient exponent range for general finite products.

The condition number of the mathematical interpolation is unbounded when the result approaches zero. No fixed width can give a uniform relative
error bound for every extrapolation input. P75 is selected because it evaluates the complete 68-digit product cancellation for decimal128 operands,
not because a universal relative bound exists for arbitrary converted long integers.

## Infinite endpoints

For finite `p`, the defining weights are

```text
w[a] = 1-p
w[b] = p.
```

The former special-value path returned an infinite endpoint without considering its weight. It consequently returned the wrong endpoint for `p=0`
or `p=1`, and the wrong infinity sign when extrapolation made a weight negative.

The revised order is:

1. Propagate NaN and reject an infinite weight.
2. Return `a` exactly for `p=0` and `b` exactly for `p=1`.
3. Return identical endpoints exactly, including equal signed infinities.
4. For one infinite endpoint, multiply its sign by the sign of its weight.
5. For two opposite infinities, return their common signed infinity when the weighted contributions have the same sign, and NaN otherwise.

This gives, for example,

```text
LINPOL(+Infinity, 1, 2)       = -Infinity
LINPOL(1, +Infinity, -1)      = -Infinity
LINPOL(+Infinity, -Infinity, 2) = -Infinity.
```

Complex interpolation applies these rules independently to both components. The existing special-result flag controls whether the resulting
infinity can be placed in a calculator register.

## Verification

The final existing-file `LINPOL` set contains 33 checks and succeeds completely. The former source succeeds in 28 checks and fails the five
wide-integer accuracy cases. The p51 finite-kernel mutation succeeds in 24 of the earlier 25 checks and fails only the exact 67-place cancellation
discriminator. The additional cases cover configured result precision and signed-zero endpoint selection.

The tests cover exact endpoint selection, interpolation and extrapolation with one or two infinities, opposite infinities, NaN propagation, the exact
finite cancellation, real and complex coefficients, time/type dispatch already present in the file, and converted integer operands. No separate test
program is added.

The integrated repository run succeeds for all 16,228 checks with no GMP allocation left active. The changed source compiles without a diagnostic;
the existing macOS linker section-alignment message remains.

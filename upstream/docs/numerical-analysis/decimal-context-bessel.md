# Bessel J and Y decimal contexts

## Scope and result

This audit covers the public real Bessel J and Y entries, their real-to-complex continuation for a negative argument, and the shared series, recurrence,
Hankel, and Debye calculations in `bessel.c`. The entries do not accept matrix operands. Long and short integer behaviour is outside this audit.

Both public entries retain `ctxtReal75`. The alternating power series used through the order and argument transition can lose almost 39 decimal places.
A p51 candidate therefore has too little precision even for several existing cases. P75 is the narrowest established project context for the current
algorithm. A future p51 implementation would need a different calculation in the transition region, such as a backward recurrence with a proved
normalisation error or a uniform asymptotic expansion.

| Route | Working context | Reason |
| --- | --- | --- |
| J and integer-order Y power series | 75 | Alternating terms can exceed the result by nearly `1e39` in the selected region |
| Large-argument Hankel expansion | 75 | The two asymptotic sums and final phase can cancel near a zero |
| Large-order Debye expansion and recurrence | 75 | Polynomial sums, phase evaluation, and recurrence conditioning vary across the turning region |
| Negative-argument continuation | 75 | Uses the p75 magnitude and retains the phase and the additional J term for Y |
| Final decimal128 value | 34 | The selected calculator rounding mode is applied only at conversion |

Differences confined to the accepted p39-to-p34 conversion boundary are outside this analysis.

## Power-series cancellation

For integer order `n`, the J series has terms

```text
t[k] = (x/2)^(2k+n) / (k! (k+n)!)
J[n](x) = sum((-1)^k t[k], k >= 0).
```

Its summation condition is

```text
kappa = sum(abs(t[k])) / abs(J[n](x)).
```

At `n = 3`, `x = 90`, independently evaluated terms give

```text
max(t[k])                  = 4.11336608e36, at k = 43
sum(abs(t[k]))             = 4.88724374e37
abs(J[3](90))              = 8.103026409631476143...e-2
log10(kappa)               = 38.780416744185866...
```

Thus a p51 calculation has only about 12 decimal places after cancellation, before allowing for term generation and accumulation. The measured p51
value of J at this point agrees for 13 significant digits. Integer-order Y combines J with a finite factorial sum, a logarithmic term, and a second
alternating series. At order 3 and argument 90, the p51 Y value agrees for only 11 significant digits.

The transition examples at order 90 are also unsuitable for p51. At order 90 and argument 112.5, the J-series condition consumes about 33.56 decimal
places; the p51 candidate retains 18 significant digits. These losses explain all seven failures in the 126-case p51 experiment:

```text
J(3, 89.99), J(3, 90), J(90, 112.5)
Y(3, 89.99), Y(3, 90), Y(90.01, 90), Y(90, 112.5)
```

P39 and p34 cannot improve on p51 for this arithmetic graph. The p34 exponent range also permits premature range loss in intermediate powers even
when the final value is finite. P75 leaves about 36 decimal places after the largest measured cancellation before accumulation error. Exact
subtraction and scaling confirm the selected 34-digit J and Y values at `(n,x)=(3,90)` in every rounding mode.

This does not establish correct rounding for every decimal128 input. The relative condition is unbounded arbitrarily close to a zero, and the
asymptotic expansions have input-dependent truncation error. It establishes p75 as the narrowest available width that resolves the identified finite
cases with the current region selection.

## Other regions

For sufficiently large argument relative to order, the Hankel expansion accumulates separate even and odd sums and stops when both change by less
than `1e-73` relatively. The final sine-cosine combination can cancel near a Bessel zero, so a component-relative result cannot have a uniform bound.
The high-precision angle-reduction and trigonometric helpers retain the p75 request.

For order above 90, the code selects a hyperbolic Debye expansion below `0.75*order`, a trigonometric Debye expansion above `1.25*order`, and a
recurrence between them. The generated Debye-polynomial sums also use a `1e-73` relative termination target. The exponential, logarithmic,
trigonometric, Gamma, and complex product helpers are separately audited dependencies. The present evidence supports faithful 34-digit results on the
file-driven transition and exponent-range cases, not a uniform relative-error theorem through every recurrence or every zero.

## Integer-order and special-value repairs

For an integer `n`, the exact identities are

```text
J[-n](x) = (-1)^n J[n](x)
Y[-n](x) = (-1)^n Y[n](x).
```

The former J code replaced every negative integer order by its magnitude and omitted the parity sign. The former Y code applied the sign only in its
small-order series, not in the large-order routes. The revised helpers obtain the exact remainder modulo two in the supplied wide context, calculate
with the positive order, and apply the sign once to the completed value. This also gives `Y[-3](0) = +Infinity` from the positive-axis limit.

For finite order, both J and Y tend to zero as a positive real argument tends to positive infinity. The revised helpers return zero before starting an
asymptotic calculation. NaN inputs still propagate, and infinite order remains outside the finite-order algorithms.

## Verification

The final file-driven Bessel set contains 176 checks. The former source succeeds in 170; its six failures comprise two negative odd-order J values, one
large negative odd-order Y value, `Y[-3](0)`, and the two positive-infinite-argument limits. The revised source succeeds in all 176.

A clean repository test run succeeds for all 16,056 checks, with no GMP allocation left active. Compilation emits no diagnostic from the changed
source; the existing macOS linker section-alignment message remains.

Reference values for the integer-order cases were evaluated independently at 2048-bit precision. Added checks include orders -3 and -101, the zero
and infinity limits, and exact 34-digit residual checks for J(3,90) and Y(3,90) under all seven calculator rounding modes. All additions use the
existing file-driven test program.

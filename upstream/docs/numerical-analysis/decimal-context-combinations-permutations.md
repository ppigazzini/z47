# Combination and permutation decimal contexts

## Scope and result

This audit covers the public generalised combination and permutation functions
for real, complex, and matrix operands. Short- and long-integer implementations
are outside scope. Logarithm, exponential, Gamma, log-Gamma, log-Beta, and
complex arithmetic are treated as audited dependencies.

The former real and complex implementations subtracted two or three large
log-Gamma values. This is ill-conditioned when the selected quantity is small
beside the population. The revised finite nonnegative real route and the complex
right-half-plane route use a log-Beta identity. Other complex inputs retain the
analytic log-Gamma continuation at p75.

| Route | Context | Reason |
| --- | --- | --- |
| Real transformed arguments | p39 outer work, p75 logarithmic kernels | Five outer guard digits, stable p75 log-Beta and log-Gamma |
| Real exponential | p39 | The audited exponential bound needs five guard digits and the wide work exponent range |
| Complex right-half-plane route | p75 | Stable complex log-Beta, with small component cancellation |
| Other finite complex inputs | p75 | Three analytic log-Gamma values can cancel in either component |
| Real and complex matrices | Scalar contexts above | Elementwise dispatch uses the matching scalar callback |

The result claim is faithful 34-digit accuracy. Differences confined to the
accepted p39-to-p34 final conversion boundary are outside this analysis.

## Stable identities

For finite `0 <= x <= y`, set

```text
a = x + 1
b = y - x + 1.
```

Both transformed arguments are positive. The calculation uses

```text
log C(y,x) = -log(y+1) - log B(a,b),
log P(y,x) = log C(y,x) + log Gamma(a).
```

The p75 log-Beta dependency evaluates one rearranged Lanczos expression. It
does not form `log Gamma(y+1) - log Gamma(y-x+1)`, so `x` remains represented
when `y` is many decimal positions larger. The stable log-Beta audit leaves
about 58 useful digits after its measured coefficient cancellation.

Input formation and the two outer additions use p39. A decimal128 input has at
most 34 coefficient digits, so p39 retains five work digits in `a`, `b`, and the
outer combination. The logarithmic kernels themselves use p75. For a finite
decimal128 result, the final logarithm has magnitude below about 14222. The one
p39 closing addition therefore has absolute rounding error below `5e-35`.
The p75 kernel error is smaller by many decimal positions. The
audited p39 exponential contributes at most `1e-38` relative error before final
conversion, apart from the excluded conversion-boundary class.

The transformed complex route applies the same identities whenever both
transformed real parts are positive. Complex input outside that region may
cross Gamma poles, so it retains the existing analytic continuation, widened
from p39 to p75.

## Context rejection cases

A p34 real work chain is unsuitable. For

```text
y = 123.456
x = 10.1234
```

independent 2048-bit MPFR evaluation gives

```text
C(y,x) = 209053723016892.308468188826117863...
P(y,x) = 1014774104211425257920.723763419553...
```

The p34 candidate differs by four decimal128 units for the combination and
three units for the permutation. The p39 route produces the required digit 34.
In addition, p34 operations unpack and repack the decimal128 operands. They have
no arithmetic-speed advantage over p39 work and can make this multi-operation
chain slower. A deliberate p34 outer-work mutation passed 115 of the 124 focused
checks, with all nine context discriminators failing. P39 is therefore both the
accuracy floor and the performance floor for the outer real calculation.

P51 is insufficient for the general complex continuation. With

```text
y = 1e34 + 0i
x = -1.5 + 0i,
```

the independent references are

```text
C(y,x) = -2.820947917738781434740397257803862...e-52
P(y,x) =  9.999999999999999999999999999999998...e-52.
```

The p51 candidate retains about 15 significant digits in each small component.
It passed 120 of the 124 focused checks; the scalar complex cases and their
matrix equivalents failed. P75 agrees through digit 34 and is the narrowest
established project context for the unrestricted complex callback.

The previous real route also failed at wide scale separation:

```text
C(1e100, 1)   returned 1 instead of 1e100
C(1e100, 0.5) returned about 1.128 instead of
               1.128379167095512573896158903121545e50
P(1e100, 1)   returned 1 instead of 1e100
P(1e100, 0.5) returned 1 instead of 1e50.
```

These failures arise before the final decimal128 conversion and are unrelated
to the accepted p39-to-p34 boundary policy.

## Conditioning and range

For positive real inputs, both functions are positive and the exponential maps
logarithmic relative error into result relative error without an additional
condition factor. Very large results pass through the p39 work exponent range
before decimal128 overflow handling. Very small results similarly remain
available for directed underflow conversion.

Complex generalisations have zeros, poles, and branch cuts. Relative component
accuracy is unbounded arbitrarily close to those sets. P75 removes the identified
arithmetic cancellation and supplies 41 guard digits, but no fixed context can
guarantee 34 relative digits at every representable point next to a zero or pole.

With special results enabled, a finite nonnegative selection from positive
infinity gives positive infinity, while selection zero gives one. Unsupported
infinite or NaN combinations return NaN. With special results disabled, the
public real callback reports the existing range error. Matrix evaluation follows
these scalar rules for each element.

## Regression coverage

The existing `cyx.txt` and `pyx.txt` file-driven suites now cover:

- wide real scale separation;
- all seven output modes at result digit 34;
- p34 real and p51 complex context discriminators;
- complex right-half-plane and analytic-continuation cases;
- infinity and NaN behaviour under special-result control; and
- real and complex matrix dispatch.

The selected contexts pass all 124 focused checks with no GMP-owned bytes. The
clean repository suite passes all 17,673 checks.

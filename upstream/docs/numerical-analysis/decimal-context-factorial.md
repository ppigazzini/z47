# Decimal context analysis for factorial

## Scope and result

This analysis covers real and complex factorial and their elementwise matrix
routes. Short and long integers are outside the requested scope.

The implementation uses the identity

```text
x! = Gamma(x+1).
```

| Route | Selected outer context | Inner context | Reason |
| --- | ---: | ---: | --- |
| real integer `0 <= x <= 36` | 34 | 34 | every multiplication is exact after decimal trailing-zero reduction |
| other finite real values | 39 | 75 for Lanczos when required | the audited Gamma callback needs p39 around its p75 kernel |
| finite complex values | 39 | 75 for Lanczos | the audited complex Gamma callback and reflection arithmetic need p39 |
| real and complex matrices | same as each element | same as each element | matrix dispatch invokes the scalar callbacks |

P34 uses the selected calculator rounding mode. This does not alter the small
integer route because every arithmetic operation there is exact. The p39 and
p75 contexts use round-to-nearest, ties-to-even, and decimal128 conversion
applies the selected output mode. Differences caused solely by the accepted
p39-to-p34 boundary effect are outside this context choice.

## Exact integer route

For a non-negative integer `n`, the shared Gamma helper evaluates `n!` as a
descending product. An exhaustive integer calculation of every partial product
for `0 <= n <= 36` shows that its coefficient has at most 34 digits after
removing decimal trailing zeros. The largest endpoint is

```text
36! = 3719933267899012174679994481508352 * 10^8.
```

Its reduced coefficient has exactly 34 digits. If an intermediate decNumber
cohort contains additional trailing zeros, p34 discards zeros only, so the
operation remains exact. P34 is therefore sufficient through 36 in every
calculator rounding mode.

The next exact value has a 36-digit reduced coefficient:

```text
37! = 137637530912263450463159795815809024 * 10^8.
```

It no longer has a general exact-p34 proof. Integer arguments from 37 through
204 retain p39. There are at most 204 rounded multiplications, giving

```text
gamma(204) = 204*u39 / (1-204*u39) < 1.03e-36,
u39 = 5e-39.
```

This leaves more than two decimal guard places before output conversion. P34
is not suitable for this larger product route. When it was deliberately used
for all positive integers, the computed 38! differed from the exact
decimal128 result by three units in nearest mode and ceiling mode, and by four
units in toward-zero mode. The file-driven cases subtract the exact expected
values, so the ordinary comparison tolerance cannot hide those differences.

## Non-integral real route

The addition `x+1` is performed at p39. For every positive argument whose
factorial can remain finite in decimal128, adding one to a 34-digit input needs
at most 35 coefficient digits and is exact at p39. Near the poles at negative
integers, decimal128 `x` and one also cancel exactly at that width. At
magnitudes where one is lost at p39, factorial is already governed by Gamma
overflow, underflow, or pole handling.

P34 cannot replace this outer context for general non-integral input. Its
rounded `x+1` perturbation is amplified by

```text
d(log(Gamma(x+1)))/dx = psi(x+1).
```

Near the upper finite factorial range the resulting relative-error scale can
approach `7*x*u34`, which is several thousand decimal128 units. P39 makes the
argument addition exact in that range and supplies the established outer
Gamma margin.

The Gamma audit selects p39 for its public real callback and p75 for the
alternating Lanczos sum. The p75 kernel is required near the zeros of
log-Gamma and under reflection cancellation; p51 retains only about 15 useful
digits for an input adjacent to one. Factorial inherits that analysis after
the exact argument shift. Raising the factorial caller itself to p51 or p75
does not improve the p75 kernel or the final decimal128 value. P39 is retained
for every non-integral real input and for integers above the exact p34 range.

## Complex route

Complex factorial first forms `(Re(z)+1)+i Im(z)` at p39, then invokes the
audited complex Gamma callback. Near `Re(z)=-1`, the real addition is exact at
p39 and preserves the distance and side relative to a pole. The internal
Lanczos sum is evaluated at p75, while reflection, winding selection, and the
outer complex result use p39.

The complex Gamma analysis found that p34 lacks sufficient margin for its
reflection and closing complex arithmetic. P51 or p75 at the factorial entry
adds no benefit because the decisive Lanczos calculation is already p75 and
is narrowed to the audited p39 callback result. The complex factorial route
therefore remains p39.

## Special values and matrices

The existing Gamma rules are retained. Positive real infinity maps to positive
infinity when special results are enabled. Negative infinity and Gamma poles
map to NaN. Complex NaNs and infinities follow the complex Gamma classification.

Real and complex matrices are evaluated element by element. The added matrix
cases exercise both the p34 exact-integer selection and the p39 complex route;
there is no extra matrix arithmetic.

## Regression evidence

The existing file-driven factorial file contains 38 checks after this change.
The selected split succeeds for all 38. Extending p34 across the positive
integer product gives three exact-residual failures at 38!. The new cases also
cover the exact p34 endpoint, the first wider integer results under directed
rounding, positive and negative infinity with special results enabled, and
real and complex matrix dispatch. The repository-wide result is recorded with
the change commit.

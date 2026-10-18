# Riemann zeta decimal contexts

## Scope and result

This audit covers the public real and complex Riemann zeta key, `WP34S_Zeta`, `ComplexZeta`, and the elementwise real and complex matrix routes. The
Bernoulli and Student t callers of `WP34S_Zeta` retain their requested contexts. They now receive constants matching those contexts. The Jacobi zeta
function in `elliptic.c` is a separate function and is outside this audit. No Hurwitz zeta entry or helper is present in `zeta.c`, `wp34s.c`, or their
callers.

The public real and complex routes now use p75. A p51 calculation is inadequate close to either a trivial or non-trivial zero, where the result is much
smaller than the intermediate terms. P75 is therefore the narrowest established project context for both public routes. The matching p75 values of
`pi`, `pi/2`, `2*pi`, and `ln(2)` are selected whenever a caller requests more than 39 digits.

| Route | Working context | Reason |
| --- | --- | --- |
| Public finite real | 75 | Reflection close to a trivial zero loses more than the 17 p51 guard digits |
| Public finite complex | 75 | Eta cancellation close to zeta zeros and its removable quotient zeros needs more than p51 |
| Purely real complex | 75, through `WP34S_Zeta` | Gives the scalar value, pole sign, and exact trivial zeros |
| Real and complex matrices | Matching scalar callback | Each decimal128 element uses the same p75 calculation |
| Existing reusable helper callers | Caller-selected 39, 51, or 75 | Constants now match the supplied context; their function-specific accuracy remains the caller's responsibility |

Differences confined to the accepted p39-to-p34 conversion boundary are outside this analysis.

## Borwein eta approximation

Both implementations evaluate a Borwein approximation to the Dirichlet eta function and then use

```text
zeta(s) = eta(s) / (1 - 2^(1-s)).
```

For `Re(s) >= 1/2`, the approximation with `n` terms has the bound

```text
|eta(s) - eta_n(s)|
  <= 3 (1 + 2 |Im(s)|) exp(pi |Im(s)| / 2) / (3 + sqrt(8))^n.
```

The scalar helper uses `n = 60`. On the real axis its absolute eta truncation bound is

```text
3 / (3 + sqrt(8))^60 < 3.50e-46.
```

The complex helper sets

```text
F = (1 + 2 |t|) exp(pi |t| / 2)
k = ceil(log(3e10 F) / log(3 + sqrt(8)))
n = 4 k.
```

Consequently its eta truncation error is less than `3 F / (3e10 F)^4`, with a maximum below `4.04e-43` at `t = 0`. The bound decreases rapidly as
`|t|` increases. The functional equation maps `Re(s) < 1/2` to this bounded half-plane.

The eta quotient has removable zero-over-zero points at

```text
s = 1 + 2 pi i k / ln(2),  k != 0.
```

At these points numerator and denominator must use the same precision. Combining p75 arithmetic with a 39-digit `ln(2)` perturbs the denominator by
about five decimal guard digits and magnifies that perturbation after division. For

```text
s = 1 + 99.71192312019826381180902480576667 i
```

the p39 route returns a real component beginning `1.519137`, while the independently calculated value begins `1.525412789062534`. Selecting
`const75_ln2` makes the quotient consistent and agrees through digit 34. The reflected case with real component zero verifies the same correction on
the other side of the functional equation.

## Arithmetic error and context rejection

At p75 the unit roundoff is `u = 5e-75`. The Borwein recurrence forms positive weights, each no larger than the final normalising weight. In the direct
half-plane, the sum of absolute normalised term magnitudes is at most

```text
sum(k^(-Re(s)), k=1..n) <= 2 sqrt(n),  Re(s) >= 1/2.
```

A first-order allowance of `40 n^(3/2) u` covers the weight recurrence, complex powers, and accumulation before conditioning by the eta denominator.
The first non-trivial-zero case uses `n = 116`, giving less than `3e-70` before the quotient. The final real and imaginary components are about
`3.38e-35` and `-2.12e-34`; their decimal128 spacings are `1e-68` and `1e-67`. The measured p75 values agree with a 150-decimal-digit independent
calculation through digit 34.

P51 does not provide that margin. At the decimal128 neighbour

```text
s = -1.999999999999999999999999999999999
```

the value is

```text
-3.044845705839327078025153047115481e-35.
```

The p51 candidate returns `-3.044840218977656578212348816604970e-35`, retaining about six significant digits. At the decimal128 approximation to the
first non-trivial zero, p51 retains about fifteen significant digits. The p39 focused mutation fails seven of the then-current 64 zeta checks, including both zero
classes and both eta-quotient cases. P75 succeeds on those 64 and on the complete 67-case file.

Values arbitrarily close to a zero or a decimal rounding boundary remain table-maker cases for every fixed context. The result above establishes p75
as the narrowest available context that resolves the identified decimal128 cases. It does not claim a proof of correct rounding for every possible
decimal128 input.

## Range, special values, and work bound

The calculated complex term count is limited to 10,000. This corresponds to `|Im(s)|` up to about `2784.65`; the last complete integer input is 2784.
Larger finite imaginary components return complex NaN instead of starting a calculation whose running time and accumulated rounding error are outside
the analysed range. Infinite or NaN imaginary components also terminate before the recurrence.

Exact negative even real integers return zero before the functional equation. This preserves trivial zeros across the complete decimal128 exponent
range and avoids a zero multiplied by an overflowing Gamma factor. Very large positive real arguments tend to one and retain that value. The pole at
`s = 1` now has positive infinity rather than negative infinity. A purely real complex input uses the real helper, so the scalar and complex forms agree
at the pole and at every trivial zero.

For non-real special inputs, a positive infinite real component with finite imaginary component has the limit `1 + 0i`. A negative infinite real
component or an infinite imaginary component has no single limit and returns NaN. NaN inputs propagate.

The complex callback formerly saved Last X a second time. During elementwise complex-matrix evaluation this replaced the matrix snapshot with the last
scalar element. Removing the duplicate operation preserves the source matrix in Last X and does not alter scalar stack behaviour.

## Rounding and verification

Every work context retains half-even arithmetic. The selected calculator mode is applied only when each p75 component is converted to decimal128.
Exact subtraction and scaling verify all 34 digits of `zeta(2)` in all seven modes. Directed-away and ceiling produce the adjacent upper value;
nearest, toward-zero, and floor produce the lower value.

Further file-driven cases cover both decimal128 neighbours of `-2`, the first non-trivial zero, two eta removable-zero cases, `Im(s) = 1000`, both
matrix types, the signed pole, the 10,000-term bound, infinities, NaNs, and the decimal128 exponent limits. Reference values were calculated independently
with 150-decimal-digit arithmetic.

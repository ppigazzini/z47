# Decimal contexts for numerical integration

## Scope and result claim

This analysis covers the active `USE_NEW_DEI_INTEGRATION_CODE == 2` implementation in `src/c47/solver/integrate.c`. It includes the public formula and program entry,
the requested-accuracy adjustment, the tanh-sinh, exp-sinh and sinh-sinh formulae, the exp-sinh split-point search, nested evaluation, endpoint classes and final
Real34 conversion.

The selected contexts give each full-accuracy arithmetic operation a nominal five-digit margin over a Real34 sample. That margin is consumed by accumulation and is
not a proof that the quadrature error meets `ACC`. The claim is faithful Real34 accuracy for suitably conditioned, convergent integrals whose successive-level error
estimate is representative, not universal correct rounding. A discontinuity inside the interval, a highly oscillatory integrand or cancellation that makes the
integral much smaller than its sampled terms can dominate the arithmetic error at every available context. Differences caused only by the final p39-to-p34
conversion are outside this analysis.

## Context selection

| Route | Integrand context | Quadrature context | Reason |
|---|---:|---:|---|
| `ACC = 0` or more than ten requested digits | Real34 public arithmetic | p39 | Five nominal guard digits beyond each stored sample; extended exponent range |
| One through ten requested digits | `N + 3` digits | `N + 5` digits in a p39 allocation | Two to three sample digits and four to five quadrature digits beyond the request |
| Accuracy extraction | p39 | p39 | The logarithmic classification must not consume the requested margin |
| Exp-sinh split-point search | Real34 samples | caller p39, at most 39 digits | Its values feed the same p39 quadrature and require no wider storage |
| Final value and error | n/a | Real34 | The selected calculator rounding mode applies during result conversion |

For a finite positive tolerance `e`, the entry calculation obtains

```text
N = clamp(floor(-log10(e)), 1, 31).
```

An `ACC` value of zero selects `1E-32`. The sign of `ACC` does not describe an accuracy property, so entry uses its magnitude. This also prevents a negative
tolerance from producing a NaN logarithm and a negative termination threshold. A NaN `ACC` has no ordered convergence threshold, so it now returns NaN before
quadrature. Previously every tail comparison was unordered and the calculation did not terminate. For `N <= 10`, formula evaluation uses `N + 3` significant digits
and quadrature uses `N + 5`. The global p4, p34, p39, p51 and p75 digit settings are saved together and restored after the integral, including nested integration.

For `N = floor(-log10(e))`, nearest rounding of an `N + 3` digit sample has a relative unit below `0.05e`; a directed mode has a relative unit below `0.1e`.
The `N + 5` digit p39 quadrature context stays half-even and its operation unit is below `0.0005e`. These are per-operation margins; the integrand condition and
repeated accumulation can consume them. P51 and p75 appear in the saved settings because an arbitrary formula can dispatch shared mathematical functions that use
those contexts. The quadrature kernel itself does not use them.

A single p34 operation that implements a Real34 conversion or result semantic is appropriate and has no extra cost. P34 is not selected as a speed mechanism for
the dependent quadrature arithmetic: a p34 chain provides no guard digits and can require repeated Real34 packing between extended operations. P39 is the minimum
useful width for that chain. The user formula necessarily exchanges each node and value through Real34 registers; its reduced `N + 3` width implements the requested
low-accuracy semantic rather than a general performance claim.

The calculator rounding selection applies to Real34 integrand operations and the final Real34 conversions. The p39 quadrature arithmetic remains half-even, so its
forward bound is the same in all seven calculator modes. Directed modes can move a stored integrand sample by one full Real34 unit; the bounds above include that
factor. There is no mode-dependent branch in the quadrature kernel.

The removed `N == 6` case used a seven-digit p4 quadrature context even though formula evaluation used nine digits. Its decimal32 exponent range also excluded valid
Real34 intervals. For the whole-line Gaussian with `ACC = 1E-6`, that route returned `1.772459`, whose relative error from `sqrt(pi)` is about `2.9E-6`. It also
returned zero for the integral of one over `[1E-1000, 2E-1000]`. The general low-accuracy route uses eleven quadrature digits for this request and has the extended
p39 exponent limits.

## Transformation arithmetic

For finite limits, the implementation forms `c = (a+b)/2` and `d = (b-a)/2`. Its tanh-sinh parameterisation uses

```text
u = exp(1/t - t)
r = 2u/(1+u)
w = (t + 1/t)r/(1+u)
x = a + dr, b - dr.
```

For one infinite limit, exp-sinh uses

```text
r = exp(t - 1/(4t))
x = c + d/r, c + dr
w = r.
```

For two infinite limits, sinh-sinh replaces `r` and `w` by `(r-1/r)/2` and `(r+1/r)/2`, then evaluates `c-dr` and `c+dr`. Every transformation operation, weight,
partial sum and level estimate now uses at most p39. The exp-sinh optimiser first brackets the scale by decimal exponent when `d = 1` is unsuitable, then searches
powers of two; unsigned shifts make those powers defined C arithmetic before conversion to a real.

Each abscissa is converted to Real34 before the formula or program executes, and each function value returns through a Real34 register. Wider quadrature arithmetic
cannot recover information removed by those conversions. For correctly rounded elementary arithmetic at p39, the round-to-nearest unit roundoff is at most
`u39 = 5E-39`. A sequence of `m` rounded operations with `m*u39 < 1` has the usual first-order factor

```text
gamma_m = m*u39 / (1 - m*u39).
```

The rational maps do not amplify the relative error of their positive exponential by a large factor. For tanh-sinh, the logarithmic conditions of
`2u/(1+u)` and `u/(1+u)^2` with respect to `u` are at most one. In sinh-sinh, subtracting `1/r` from `r` is relatively ill-conditioned near `r = 1`, but the
resulting abscissa displacement is then near zero, so the absolute node error remains small. Endpoint cancellation is stopped when a generated node equals its
endpoint. The accuracy of the p39 exponential remains a direct dependency of these bounds.

The focused cases required fewer than 300 sampled terms at any displayed level. P39 begins five decimal positions beyond a Real34 sample, but a long accumulation can
consume much of that margin; there is no input-independent bound on the number of integrand evaluations. P51 and p75 reduce accumulator rounding, but add no
information to the Real34 samples and do not reduce quadrature truncation or sample perturbations in an ill-conditioned sum. They also use the same extended
`emax = 999999` and `emin = -999999` as p39, so they add no exponent range. P39 is the narrowest width established by the mutation and accuracy tests below. The
previous p75 selection for a small finite endpoint beside an infinite endpoint is removed.

P34 is too narrow for the full route. A deliberate p34 candidate returned `0.9999999999999999999999999999999960` for the integral of one over `[0,1]`; p39 returns
the exact Real34 value one. P39 is therefore the narrowest established full-accuracy context. Comparisons at p51 and p75 did not improve the checked Real34 results.

## Cancellation and convergence

Tanh-sinh adds the two function values before multiplying by the common weight. Sinh-sinh forms both weighted terms in the same partial sum. These pairings preserve
the exact zero of an odd function on a symmetric interval when the Real34 samples are opposites. The regression with `x` over `[-1,1]` checks that property; a second
whole-line case adds an odd term scaled by `1E4` to a Gaussian and checks the even result.

The tail repetition stops when `abs(q) <= e*abs(p)`. Refinement stops when `abs(s-p) <= 10e*abs(s+p)`, or after eight levels, and the returned estimate is
`abs(s-p)/(abs(s+p)+abs(s-p))`. The factor ten means `ACC` controls an error heuristic rather than a strict relative bound. Successive estimates can also agree before
the unsampled error is small. The method therefore has no unconditional 34-digit result claim, including when the zero-`ACC` default selects `1E-32`.

A nearly cancelled integral has a large relative condition number because its absolute sample errors are divided by a small result. Extra quadrature digits do not
repair the Real34 sample errors in that case. When the partial sum is zero, the relative tail threshold is also zero and requires the current contribution to become
exactly zero. The finite endpoint and extended exponent range normally make that happen; a NaN `ACC` formerly prevented every ordered stopping comparison and
produced an unbounded iteration. The entry guard now returns NaN for that case. The reported error, the level limit and knowledge of the integrand remain the
applicable diagnostics.

## Endpoints, types and nesting

Finite limits select tanh-sinh, one infinite limit selects exp-sinh, and two infinite limits select sinh-sinh. Reversed limits exchange the endpoints and negate the
result. Equal endpoints, including opposite signed zeros and equal infinities, return positive zero before quadrature; NaN endpoints return NaN. The undo snapshot is
now taken before the equal-limit exit because all completion routes invoke `fnUndo` and rebuild the result stack. The former route restored an unrelated earlier
snapshot and corrupted Z and T. Special abscissas contribute zero, and a special integrand value contributes zero as specified by the existing SPCRES integration
behaviour. Integrable singularities at zero are covered with `x^(-0.5)` and `ln(x)`. Constant-integrand checks at `1E6143`, `1E-6143` and `1E-6176` exercise the
finite Real34 exponent range through the extended p39 transformations.

`fnIntegrateYX` accepts real values and complex values with a zero imaginary component. It rejects nonreal complex values and matrices without modifying X. Formula
and program evaluation use the same quadrature entry. Each invocation increments both nesting counters, restores the solver flags on exit and has its own heap values.
The low-accuracy context snapshot makes an inner integral restore the outer integral's digit settings.

The main kernel has sixteen heap reals and the exp-sinh optimiser has ten. A p75 allocation occupies 60 bytes and a p39 allocation occupies 36 bytes, so matching the
storage to the maximum context reduces their combined peak by 624 bytes. Allocation failure, endpoint rejection, user interruption and normal completion all reach
`freeWork`; `REAL_T_FREE` releases every value on targets without automatic cleanup, while the cleanup attribute performs the equivalent action on supported hosts.

## Remaining scale and input audit

The exp-sinh map is covariant under a scale change only when its split value `d` changes with the integrand. Its local optimiser balances

```text
B(d) = |f(a + d/2)| - 4|f(a + 2d)|.
```

The factor four includes the far-node Jacobian. The former power-of-two search reached at most about five decimal positions from `d = 1`. If both starting samples
rounded to zero it returned `d = 1`; if both were nonzero but `B(1) < 0`, it could still leave `d` thousands of decimal positions below the useful scale. The
exp-sinh sum then either returned zero before sampling the integrand or reached the remote mass with an inadequately spaced grid.

Decimal-exponent bisection now precedes the local search in those two cases. It searches the Real34 adjusted-exponent intervals `[-6176, 0]` or `[0, 6144]`, requiring
at most 13 additional bisections. Powers of ten are formed exactly by changing the exponent of `+1` or `-1`. The selected lower side of the balance is within one
decimal position of a detected sign change and leaves finite headroom for the far sample; the existing power-of-two stage then refines it. For
`f(a+x) = exp(-x/S)`, the exact balance occurs at

```text
d/S = 2 ln(4) / 3 = 0.9241962407465937...
```

so the exponent bracket is a direct scale estimate for the regression family. General integrands need not have a monotone `B(d)`, and no finite sample method can
guarantee discovery of an isolated unsampled region. This remains a convergence limitation rather than a decimal-context issue.

The exponent search uses the caller's p39 arithmetic and Real34 formula samples. P51 or p75 would not recover information removed by those samples. Its one p34
comparison determines whether the minimum probe differs from the finite endpoint on the formula-storage lattice; this single conversion implements a public input
semantic and is cost-neutral. The dependent balance calculations remain p39, where five nominal working digits separate them from full-width Real34 samples.

Positive or negative infinite `ACC` has no finite ordered tolerance. Entry now returns NaN in both result and reported error, as already done for NaN `ACC`, before
logarithmic digit classification. Previously the whole-line Gaussian with infinite `ACC` selected a reduced context and returned approximately `1.64048`.

The integrand result now goes through `getRegisterAsReal`. Real-axis complex and integer values therefore retain the established conversion behaviour, while a
nonreal complex value, matrix or tagged value reports invalid type. Directly interpreting the result storage as Real34 formerly converted `1+i` to `1` and produced
the real integral one. An existing formula error also contributes zero rather than exposing stale Real34 storage; the public error remains available to the caller.

The scale regressions use the exact identities

```text
integral(0, infinity, exp(-x/S)) = S,
integral(-infinity, 0, exp(x/S)) = S.
```

At `S = 1E-6000`, the former implementation returned zero. At `S = 1E6000`, it returned about `1.4847724404E6001` under the full-accuracy setting. The new
file-driven checks cover both directions at `1E-6000` and the right tail at `1E6000` with `ACC = 1E-6`; their independent relative-error test accepts only an error at
or below the requested magnitude. The finite Real34 ceiling still limits an integral whose significant mass requires abscissas beyond `1E6144`; no wider internal
context repairs a formula input that has already become infinity.

## Verification

The verified references are exact elementary integrals, `sqrt(pi)`, and direct relative-error checks against the requested tolerance. Deliberately restoring the
seven-digit `ACC = 1E-6` route made three focused checks fail: the positive-accuracy Gaussian, the tiny constant interval and the corresponding negative-accuracy
Gaussian. A deliberate p34 full-accuracy candidate made the exact constant-integral discriminator fail.

Before the entry fixes, the expanded zero-width check returned X = 0, Y = 0, Z = 2 and T = 2 instead of retaining Z = 30 and T = 40. A NaN `ACC` calculation exceeded
62,398,894 evaluations before manual interruption. The selected implementation succeeds in all 43 expanded file-driven checks for finite, semi-infinite and
whole-line intervals, endpoint singularities, reversal, cancellation, directed modes, finite exponent extremes, reduced-context elementary functions, type
conversion, stack reconstruction, special accuracy and semi-infinite scale selection. The final clean repository suite succeeds in all 18,330 checks with zero
failures and zero GMP allocation.

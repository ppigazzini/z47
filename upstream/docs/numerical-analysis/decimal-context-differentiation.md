# Decimal context analysis for numerical differentiation

## Scope and result

This analysis covers first and second numerical derivatives of formulas and programs in `src/c47/solver/differentiate.c`. It includes automatic and user-supplied
steps, centred and one-sided stencils, domain boundaries, scalar input types, special values, and result rounding. Program state restoration is unchanged.

| Calculation | Selected context | Reason |
| --- | ---: | --- |
| Stencil point `x + k*h` | 34 | the callback receives a Real34 register value immediately afterward |
| Function callback input and output | Real34 | calculator programs and formulas operate through register X |
| Centred weighted sum | 39 | five guard digits put work rounding below sample quantisation |
| One-sided weighted sum | 39 | no symmetry identity removes its full coefficient sum |
| Division by the stencil denominator and `h^order` | 39 | the quotient shares the weighted-sum error budget |
| Estimate gap and selection | 39 | the fallback ranks gaps between p39 estimates |
| Step text | 2 | this value is informational and does not enter the derivative |
| Public result | Real34 | the selected calculator rounding mode applies here |

The p34 point calculation is narrower than the previous p39 calculation. Its next consumer is `_differentiatorIteration`, which converts the point to Real34 before
evaluating the callback. A correctly rounded p34 fused multiply-add therefore produces the required stored point directly. The accepted p39-to-p34 boundary
difference is the only distinction from the former route.

Graph evaluation temporarily assigns its requested digit count to `ctxtReal34` and three additional digits to `ctxtReal39`. The two contexts keep the same roles in
that mode: stored point precision and guarded stencil precision. `deriv_tolerance_digits` reduces the comparison target with the graph setting, so the ordinary
34/39 widths are not forced into a reduced-precision graph calculation.

## Error model and work width

For derivative order `m`, integer coefficients `c_i`, denominator `d`, and step `h`, one estimate is

```text
D_h = sum(c_i * f(x + i*h)) / (d * h^m).
```

Every callback value has already been rounded to 34 digits. If each sample perturbation is bounded by `epsilon_i`, the resulting estimate perturbation is bounded by

```text
sum(abs(c_i) * epsilon_i) / abs(d * h^m).
```

The first-derivative tables use coefficients up to 315315 and denominators up to 360360. The second-derivative tables use coefficients up to 228812298 and a maximum
denominator of 75675600. Those integers enlarge sample and arithmetic errors by the same condition factor; their raw digit count does not by itself require a p75
temporary.

Let `u_p` denote a conservative relative error scale of `10^(1-p)` for one p-digit elementary operation. At most fifteen products contribute to a stencil. A p39
weighted sum contributes roughly `15*u_39` times the absolute term sum before division. The unavoidable Real34 sample term has scale `u_34` times that same sum.
Consequently the p39 arithmetic term is more than three decimal orders below sample quantisation, including the factor for fifteen terms. P51 and p75 reduce only
the smaller term and cannot recover callback digits.

P34 arithmetic has no such separation. It also inherits the selected directed mode, while the guard contexts use half-even internally. In the retained focused
sequence, replacing p39 weighted arithmetic with p34 changes the positive zero derivative of `X^3` at zero to negative zero after a floor-mode case. Before the
centred-sum rewrite, a full p34 kernel also failed 13 of 33 accuracy checks and produced a second derivative near `-1.17E17` for `exp(x)+1E20`. P39 is therefore the
narrowest established context for weighted arithmetic and estimate selection.

## Centred-stencil conditioning

The former accumulator multiplied every sample by its coefficient and cancelled the large products afterward. Centred tables permit cancellation first. For a
first derivative with antisymmetric coefficients,

```text
sum(c_k*f(x+k*h) - c_k*f(x-k*h))
  = sum(c_k * (f(x+k*h) - f(x-k*h))).
```

For a second derivative, symmetric side coefficients and `c_0 = -2*sum(c_k)` give

```text
c_0*f(x) + sum(c_k * (f(x-k*h) + f(x+k*h)))
  = sum(c_k * ((f(x-k*h)-f(x)) + (f(x+k*h)-f(x)))).
```

The implementation verifies antisymmetry or symmetry and the second-derivative centre identity from the integer coefficient table. Other stencils retain their
ordered fused accumulation.

The second form removes constant offsets before coefficient multiplication. It also makes sampled odd symmetry cancel to zero. For `sin(x)` centred at zero, the
former order left `1.4535728821443107E-39`; multiplying that result by `1E40` exposed `14.535728821443...`. The paired form produces zero before division.

## Steps, cancellation, and boundaries

Without a named `delta_d`, the step sequence is `x*10^-s` for `s=1,...,16`. Zero uses `10^-s`. Scaling by a power of ten changes the decimal exponent without
rounding. Each step evaluates all fifteen positions. The first usable stencil in table order supplies the estimate, so a centred stencil has priority when both sides
are valid and a one-sided stencil remains available at a domain boundary.

Adjacent estimates from the same stencil are compared at p39. The relative tolerance accounts for one loss of `s` decimal places per derivative order. An agreeing
pair selects its coarser member, which has less sample cancellation. If no pair agrees, the smallest p39 gap selects the coarser member of that pair.

A finite, nonzero user step is used once. No truncation-versus-cancellation comparison is possible in that mode. A step smaller than the Real34 spacing can make
distinct mathematical samples identical; a generic engine cannot distinguish that case from a locally constant function.

At a domain boundary, undefined callback results become NaN samples and only stencils that avoid them qualify. The retained endpoint function `sqrt(x)^2` equals
`x` for `x>=0`; its first derivative at zero comes from a forward stencil and agrees with one. Offset and full-width scaled variants cover first- and
second-derivative one-sided sums.

Finite differences do not prove differentiability. A cusp, jump, pole, or infinite endpoint derivative can still yield a finite scale-dependent estimate. The step
sequence and user interface remain unchanged for those cases.

## Types, special values, and rounding modes

Real scalars, short integers, long integers, and complex scalars with zero imaginary component enter the real route. Integer-specific accuracy is outside this
analysis. A complex scalar with nonzero imaginary component, a real matrix, or a complex matrix produces `ERROR_INVALID_DATA_TYPE_FOR_OP`; numerical differentiation
has no elementwise matrix route and no complex-valued kernel.

If a callback produces a non-real or special result at one point, that point becomes NaN and the candidate stencil rejects it. If no stencil qualifies, the public
result is NaN. Infinite and NaN differentiation points return NaN without callback evaluation.

Formula and program samples use Real34 operations and thus the selected calculator rounding mode. Stencil arithmetic uses the p39 guard context. The completed result
is converted to Real34 under the selected mode. Ceiling and floor regressions with an integer-valued polynomial derivative cover the directed conversion path.

## Verification evidence

The focused file-driven set contains 53 checks after the endpoint, type, special-value, and directed-mode additions. All 53 succeed with the selected implementation.
Disabling centred pairing causes two failures: the offset second derivative changes in its sample-limited digits, and the independently zero scaled `sin(0)` case
becomes `14.535728821443...`. Replacing p39 weighted arithmetic with p34 causes the directed zero-sign failure described above.

The separate multivariable fixture adds 12 successful checks. After rebasing onto `fbeba9822b3b8e3a574ffc908f33ec4790f6d2c9`, a clean repository-wide run
completed 17,235 checks with zero failures.

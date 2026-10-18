# Lambert W decimal contexts

## Scope and result

This audit covers the principal and negative real branches of Lambert W, the principal complex branch, the inverse mapping `w exp(w)`, and the elementwise matrix
routes. The short-integer and long-integer conversions are outside the audit.

| Route | Working context | Reason |
| --- | ---: | --- |
| Principal real W | 75 | The closest decimal128 input to `-1/e` amplifies work error by about `7.52e16` |
| Negative real W | 75 | It has the same square-root branch point and amplification |
| Principal complex W | 75 | Complex inputs can approach the same branch point; p51 retains only about eighteen useful digits there |
| Real inverse W | 39 | One exponential and one multiplication have no subtractive cancellation |
| Complex inverse W | 75 | A component can cancel to approximately `1e-33` while its two terms are order one |
| Real and complex matrices | Matching scalar callback | Every decimal128 element uses the context above |

Every work context uses round-to-nearest, ties-to-even. The selected calculator mode is applied when the wide result is converted to decimal128. Differences confined
to the accepted p39-to-p34 conversion boundary are outside this analysis.

## Lambert W conditioning

For

```text
f(w) = w exp(w) = z,
```

implicit differentiation gives

```text
dw/dz = w / (z (1 + w)),
```

so the relative condition number is `1 / |1 + w|`. The real branches meet at `z = -1/e`, `w = -1`. The two nearest decimal128 real inputs are

```text
-0.3678794411714423215955237701614608
-0.3678794411714423215955237701614609.
```

For the upper input,

```text
1 + e z = 1.833367228031644596399675385054296...e-34,
W0(z) + 1 = 1.914871916359757244949087218841150...e-17.
```

For the lower input, the principal value is complex and `|W0(z) + 1|` begins `1.3303492777668582e-17`. These are the minimum branch-point distances available from
a decimal128 real component because `-1/e` is not representable. Adding an imaginary component cannot reduce the complex distance from the branch point.

The branch-point expansion forms `1 + e z`. A 39-digit value of `e` perturbs this cancellation by order `1e-39`; division by `|1+w|` then makes the W error order
`1e-22`. Selecting p75 without replacing that constant leaves the same defect. The revised helper calculates `e` in the supplied context, so its p75 contribution is
order `1e-58` after branch-point amplification.

The real Newton and Halley iterations perform one more update after an update falls below `1e-49`. This is fifteen decimal places below a normal result unit. Near
the closest branch point, a conservative allowance of 2,000 p75 operation errors divided by `1.33e-17` is below `8e-55`, so the termination threshold is the larger
local contribution. Away from the branch point, `|1+w|` grows and the conditioning improves.

P51 cannot provide the same result. Its unit roundoff divided by the minimum `|1+w|` is about `3.8e-34`, already comparable with a decimal128 result unit. Measured
p51 calculations retain about eighteen useful digits in the small imaginary branch-point component. P75 is the narrowest established project context for all public
W branches.

The principal complex helper uses Newton's update

```text
w[n+1] = w[n] - (w[n] exp(w[n]) - z) / (exp(w[n]) (1 + w[n])).
```

The complex convergence test applies a `1e-37` relative threshold to each component separately. A norm-based absolute test can stop while a small component still
has few correct digits because the other component is order one. The p75 work-error allowance near the branch point is below `8e-55` in absolute value, or below
`7e-38` relative to the minimum `1.33e-17` component. The component test therefore leaves three decimal guard digits.

The complex iteration is limited to 256 updates. The closest decimal128 branch-point cases need at most 66 updates from the existing starting value. The limit also
covers a p75 approximation to the branch point while making every failure finite in time. A calculation that does not meet the component thresholds returns complex
NaN. Exact negative imaginary zero selects the lower side of the negative-real cut and the closing sign correction applies conjugation symmetry on that axis.

## Inverse mapping

The scalar inverse is evaluated directly as `x exp(x)`. The audited exponential has relative error at most `1e-38` at p39, and correctly rounded multiplication adds
at most `5e-39` for a normal result. The combined first-order relative bound is therefore below `1.5e-38`, leaving more than three decimal guard digits. P34 has no
such margin, so p39 remains the narrowest established context.

For `z = x + i y`, the complex result is

```text
exp(x) (x cos(y) - y sin(y))
  + i exp(x) (x sin(y) + y cos(y)).
```

The compensated complex multiplication bounds its own component error relative to the exact component, but errors already present in sine and cosine remain absolute
errors in the two terms. The decimal128 input

```text
z = 1 + 2.028757838110434223576971124734714 i
```

is next to a zero of the imaginary component. Its independently calculated result is

```text
-6.148281423153994073113812051760701
 + 2.764430366604715101862999484306563e-33 i.
```

P39 retains about five useful digits in the imaginary component and p51 retains about seventeen. A p75 trigonometric request evaluates its reduced-angle series at
p75. Its completed bound is below `8.1e-71`; the p75 exponential and compensated multiplication are smaller contributions. This supplies more than three guard digits
for the approximately `1e-33` component's 34 significant digits. P75 is therefore selected for the complex inverse route.

## Range and special values

Finite W results for decimal128 inputs have modest magnitude: the principal value at `1e6144` is about `14137.53`, and the negative value at `-1e-6143` is about
`-14154.34`. The p75 exponent range therefore does not constrain the W iterations.

The inverse mapping can reach the decimal128 range boundaries. Solving `x + ln(|x|)` at those boundaries gives transitions near

```text
x = 14139.82864562744749357223336274119557...
x = -14231.02186101062278409468284203898277....
```

The p39 and p75 work contexts have much wider exponent limits, so finite intermediates reach the final decimal128 conversion. The existing exponential magnitude limit
of `2e6` is far beyond both transitions and maps only to final overflow or underflow.

The principal real branch preserves signed zero and maps positive infinity to positive infinity. Its complex extension maps a negative infinite real component with a
finite imaginary component to positive infinity and signed pi, a positive infinite real component to positive infinity and signed zero, and an infinite imaginary
component with finite real part to positive infinity and signed pi over two. Inputs with NaN components or two infinite components return NaN.

The negative real branch maps either zero sign to negative infinity. The inverse maps negative real infinity to negative zero. A purely real complex inverse delegates
to the scalar helper; other nonfinite complex inputs return NaN.

## Verification

All finite expected values were calculated independently with 180-decimal-digit arithmetic. Exact subtraction and scaling expose result digit 34 beside the branch
point, on the complex branch, and beside a zero component of the inverse mapping. The branch-point scalar cases exercise all seven output modes.

Further file-driven cases cover both real branches, large and tiny finite arguments, complex cut directions, signed zeros, infinities, NaNs, and real and complex
matrices.

With the original p39 entry contexts, 17 of 23 finite adversarial checks succeeded. The closest upper branch-point result had about 22 useful digits, and the lower
complex value had about five useful digits in its imaginary component. Selecting p75 without replacing the 39-digit `e` still left an approximately `5.3e-23`
error in the upper branch result. Before the context-aware constant and special-value changes, the negative-branch and inverse subset succeeded in 81 of 91 checks.

A deliberate p51 substitution with the revised algorithm succeeded in 143 of the then-current 149 focused checks. It retained only seventeen or eighteen useful
digits in the branch-point imaginary components and the small inverse component. The selected contexts succeed in all 154 focused checks, and all 16,042 repository
checks succeed.

# Decimal context analysis for arbitrary-base logarithm

## Result

`LogXY` evaluates `ln(y)/ln(x)`, where `x` is the base and `y` is the value. The selected contexts are:

| Calculation | Selected context | Reason |
| --- | ---: | --- |
| positive real inputs | 39 | the audited natural logarithm and the final division retain a sufficient margin beyond decimal128 |
| complex logarithm away from the unit circle | 39 | magnitude and angle are well-conditioned for the logarithm in norm |
| complex logarithm near the unit circle | 75 for the radial component, 39 for the angle | decimal128 component products can cancel through more than 51 digits |
| complex quotient | 75 | cancellation between the two products in either quotient component can expose every input-log digit |

The positive real route remains at 39 digits. Negative or complex operands now use a direct-input complex logarithm that preserves a small radial component near the unit circle, followed by complex division at 75 digits. Matrix evaluation inherits these decisions per element.

The fixed working contexts use round-to-nearest, ties-to-even. The user-selected mode is applied during conversion to decimal128. Differences caused only by the final 39-to-34-digit conversion are excluded from this analysis as requested.

## Positive real route

For finite positive inputs, the implementation computes

```text
A = WP34S_Ln(y)
B = WP34S_Ln(x)
q = A/B
```

at precision 39. The natural-logarithm audit bounds its reduced-series arithmetic by less than `9.1e-37` relative for nonzero results. The final correctly rounded division adds at most `u39=5e-39` relative error. Complex division is not used on this route.

Subtraction from one is exact at precision 39 for a decimal128 neighbour of one, so a tiny logarithm does not lose input digits before the series. Division by another logarithm has the usual mathematical conditioning when the base approaches one, but increasing the arithmetic width cannot repair uncertainty already present in the decimal128 base.

Precision 34 provides no forward-error margin. With base 10 and

```text
y = 1.000000000000000000000000000000001,
```

an independent high-precision calculation gives

```text
log_10(y) = 4.342944819032518276511289189166049...e-34.
```

A precision-34 mutation differs by two decimal128 units in the exact scaled-residual test. Precision 39 produces the expected 34 digits. Precision 51 or 75 adds no useful accuracy to this route, so 39 is the narrowest established project context.

## Direct complex logarithms

For `z=a+ib`, the real component of its principal logarithm is

```text
Re(ln(z)) = ln(a^2+b^2)/2.
```

Computing a rounded magnitude first is ill-conditioned near the unit circle. The old path could replace a nonzero radial component by zero. For exact decimal128 rectangular inputs with `1/2<|z|<2`, the new helper forms

```text
delta = (d-1)(d+1) + s^2,
Re(ln(z)) = WP34S_Ln1P(delta)/2,
```

where `d` is the component with greater absolute value and `s` is the other component. Choosing `d` retains `s^2` when one component is exactly `+1` or `-1`.

Each decimal128 product has at most 68 coefficient digits. The product `(d-1)(d+1)` can require 70 because either sum can gain one digit. Precision 75 retains these products and their cancellation before the `ln1p` evaluation. Precision 51 cannot do so for all inputs. For

```text
a = 0.7
b = 0.7141428428542849997999399811367265,
```

an independent calculation gives

```text
Re(log_10(a+ib)) = -8.645885295160813263664278022663993...e-36.
```

Using precision 51 for the radial calculation loses accuracy from result digit 18. Precision 75 produces the expected decimal128 value. Away from the selected annulus, the real logarithm has magnitude at least approximately `ln(2)`, and the precision-39 magnitude-first calculation is well-conditioned.

The imaginary component is the audited precision-39 `atan2(b,a)` result. Its error bound is absolute near a branch endpoint and relative in the zero-centred cell. Together with the radial calculation, this gives a faithful 34-digit complex logarithm in norm. A componentwise relative guarantee is impossible when one exact component approaches zero.

The direct helper is limited to exact register components. The older `lnComplex` helper remains available to algorithms whose inputs are correlated approximations; exposing cancellation in such inputs may amplify error introduced by their enclosing calculation.

## Complex quotient

Let `A=ln(y)` and `B=ln(x)`. The quotient uses

```text
D   = Br^2 + Bi^2
Nr  = Ar*Br + Ai*Bi
Ni  = Ai*Br - Ar*Bi
q   = (Nr+i*Ni)/D.
```

Unlike public complex division of two decimal128 operands, the logarithm components are working values with as many as 75 digits. Their products therefore need not be exact at precision 75. With `u=u75=5e-75`, the nonnegative denominator has relative arithmetic error below `2u+u^2`. A conservative normwise bound for the two rounded numerator products and their fused additions is below `4u|A||B|`. The two final divisions add at most `u` each. Thus the division arithmetic contributes less than `8u=4e-74` relative error in complex norm, apart from second-order terms.

This bound is normwise. A component numerator can be arbitrarily small through cancellation, so no fixed context provides a uniform componentwise relative bound. Precision 75 nevertheless retains more than 39 decimal orders beyond the required output width and avoids discarding useful digits produced by the direct logarithms. Precision 51 fails the radial cancellation example above, while precision 75 succeeds. No wider fixed context is needed for decimal128 inputs.

The map `(A,B) -> A/B` has first-order relative condition one in each complex operand when neither is zero. A base at the singular value one makes `B=0`; the existing special-result and domain behavior applies there.

## Range and special values

A finite decimal128 component has adjusted exponent from `-6176` through `6144`. Component products used to form a squared radius can reach approximately twice this range, far inside the precision-75 exponent limits of plus or minus 999999. Natural logarithm components are modest for large and small finite values. A radial logarithm beside the unit circle can be as small as approximately `1e-12352`, which also remains normal in the wide context.

The rewrite does not change the existing zero-domain table: base zero and value zero produce positive infinity when special results are enabled; nonzero base with zero value produces negative infinity; zero base with nonzero value produces NaN. Negative real operands continue through the principal complex logarithm when complex results are enabled. NaNs, infinities, signed branch sides and the base-one singularity retain the established public behavior.

## Verification

The final file-driven focus contains 138 `logxy` checks. The former source succeeds for 136 of them and loses both newly added complex radial values. A precision-34 scalar mutation succeeds for 137 of 138 and misses the base-ten neighbour case. A precision-51 complex mutation succeeds for 137 of 138 and misses the 68-digit cancellation case. The selected contexts succeed for all 138.

The shared-log focus contains 407 checks from `ln.txt`, `log10.txt`, `log2.txt` and `logxy.txt`; all succeed after extracting the direct complex-log helper. The added cases use subtraction and scaling inside the existing file-driven test program to make a digit-34 error visible despite the ordinary comparison tolerance.

A clean repository test run succeeds for all 15,370 cases with zero failures and no GMP-owned bytes at exit. Compilation emits no diagnostic from the changed source; the existing Mach-O section-alignment warning remains.

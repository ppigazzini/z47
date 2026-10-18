# Percent and statistical-transform decimal contexts

## Scope and result

This audit covers `%T`, `%Σ`, `Δ%x̄₁`, the combined `%Σ,Δ%x̄₁` entry, the shared scalar helpers, and the elementwise real-matrix `%Σ` route. Statistical accumulation already uses p75 and is treated as input to these transformations.

| Public calculation | Work context | Reason |
| --- | ---: | --- |
| `%T = 100*x/y` | 34 | Exact decimal scaling followed by one correctly rounded division |
| `%Σ = 100*x/Σx` | 34 | Exact decimal scaling followed by one correctly rounded division |
| `Δ%x̄₁` centring | 39 | One fused `N*x-Σx` needs five guard digits |
| `Δ%x̄₁` division | 34 | The p39 centred numerator is scaled exactly before one result division |
| Combined `%Σ,Δ%x̄₁` | 34 and 39 as above | Each component uses its direct calculation |

The p34 divisions use the selected calculator rounding mode. The p39 fused calculation uses round-to-nearest, ties-to-even. Differences confined to the accepted p39-to-p34 boundary are outside this analysis.

## `%T`

`%T` evaluates

```text
100*x/y.
```

Increasing the exponent of the local copy of `x` by two is exact. The following p34 division is therefore the only rounded arithmetic operation, so the assumption that division is correctly rounded proves p34 is sufficient and minimal. Scaling before division also gives the division the final exponent. For example, the largest finite decimal128 value divided by 100 remains finite after the scale, and `1e-6176` divided by 100 returns the minimum subnormal after the scale.

That argument assumes exact Real34 inputs. Converting a wider LongInteger to p75 first can discard digits which determine the Real34 result. When either scalar input is a LongInteger, the revised path unpacks any Real34 operand to its integer coefficient and decimal exponent, applies the factor of 100 as an exact exponent adjustment, and performs one correctly rounded quotient. It therefore retains every LongInteger digit without adding a chained p34 calculation.

The former special-result branches constructed infinity from the numerator sign alone. They therefore returned positive infinity for `10/(-0)` and negative infinity for `-10/(-0)`. Decimal division now produces NaN, infinity, and signed zero directly. The existing domain error remains when special results are disabled.

The error derivation applies to all seven result modes. The file-driven cases verify `100/7` through digit 34 and cover both signs over a negative-zero denominator.

## `%Σ`

Let `S=Σx`, including every digit retained by the p75 statistical accumulator. The revised calculation is

```text
scaledX = 100*x                 exact exponent change
result  = RN34(scaledX/S).
```

There is one rounded arithmetic operation. P34 is therefore sufficient for the scalar and every real-matrix element. The former p39 quotient added two to the result exponent afterwards. Retaining that order while narrowing to p34 would underflow `x/S` before a representable scaled result was formed. Scaling the numerator first avoids that range defect; `x=1e-6176` and `S=100` returns `1e-6176`.

For a zero statistical sum with special results enabled, the former code replaced the denominator by positive infinity and then divided by it. It returned zero for finite numerators and zero instead of NaN for `0/0`. The revised route keeps the zero denominator and delegates the special value and its sign to decimal division. With special results disabled, the established domain error remains.

The error derivation applies to all seven result modes. The file-driven cases verify digit 34, the minimum-subnormal boundary, signed finite numerators over a zero sum, and `0/0`.

## `Δ%x̄₁`

With `N>0` and `S=Σx`, the mathematical definition can be rearranged without approximation:

```text
100 * (x-S/N)/(S/N) = 100 * (N*x-S)/S.
```

The former route first calculated `RN39(S/N)`. Its absolute mean error is then subtracted from `x`. The relative error in the centred value is amplified by

```text
(abs(x) + abs(S/N)) / abs(x-S/N),
```

which has no finite upper bound near the mean. Two accumulated values

```text
2
1.234567890123456789012345678901234e-40
```

give a p75 sum whose small term is representable in full. For `x=1`, the independently evaluated result is

```text
-6.172839450617283945061728394506170e-39.
```

The mean-first implementation returned zero.

The revised route computes `RN39(N*x-S)` with one fused multiply-add. For a normal nonzero centred result, this introduces relative error at most `5e-39`. The factor of 100 is an exact exponent change, then p34 division applies the selected result mode. This leaves five decimal guard digits before the accepted p39-to-p34 boundary. The p39 exponent range also keeps every difference formed from decimal128 samples and the stored p75 sum away from its work-context underflow boundary.

P34 is not sufficient for the fused centring. For the two accumulated values

```text
2.033280971048666087721175310280454
9.615283548985539697959878206546683e-34
```

and `x=7.401472794762299660552999531601163`, the independently evaluated nearest result is

```text
628.0324657683669633219879272851033.
```

A p34 fused numerator changes digit 34 and fails five of the seven exact mode checks. P39 returns the independently rounded value in every mode. P51 and p75 add no justified accuracy after the stable rearrangement, so p39 is the narrowest established centring context.

When `S` is zero, the same fused numerator and p34 division produce the required signed infinity or NaN under special-result mode. The domain error remains otherwise. Both the separate and combined public entries use this helper.

## Verification

The initial implementation fails 11 of the new focused checks: three `%Σ` zero-sum values, two `%T` negative-zero signs, the tiny centred value through both public entries and their exactness scaling, and the zero-mean signs through both public entries. A p34 centring experiment fails five exact digit-34 checks.

The settled p39/p34 implementation succeeds on all 168 focused checks with no GMP-owned bytes.

Final clean repository verification is recorded with the commit evidence.

# Decimal context analysis for mean rate of return

## Scope and result

`%MRR` evaluates

```text
100 * ((x/y)^(1/z) - 1).
```

The positive finite-ratio route now uses a stable logarithmic formula at p51.
The former p75 power route is retained when `x/y` is non-positive because that
case depends on the real-power domain and integral-exponent rules.

| Route | Former context | Selected context | Reason |
| --- | ---: | ---: | --- |
| positive `x/y` | 75 | 51 | stable `log1p` and `expm1` remove both subtractions; p51 covers worst-case exponential sensitivity |
| non-positive `x/y` | 75 | 75 | the existing real-power domain and exceptional-value behaviour is retained |

The p51 work context uses round-to-nearest, ties-to-even. Conversion to
decimal128 applies the selected user mode. Differences caused solely by the
accepted p39-to-p34 boundary effect are outside this context choice.

## Stable positive formula

For `r=x/y>0`, define

```text
d = r - 1,
l = log(r),
w = l/z,
R = 100 * expm1(w).
```

When `1/2<r<2`, the implementation forms

```text
d = (x-y)/y,
l = log1p(d).
```

The operands have the same sign in this interval. Finite Real34 and integer
registers are unpacked into exact scaled integers, so both `x-y` and the ratio
retain digits beyond a fixed decimal input context. The division contributes
at most `u51=5e-52` relative error. The relative condition number of `log1p(d)`
with respect to `d` is

```text
|d / ((1+d) log(1+d))| <= 1/log(2) < 1.443.
```

Outside this interval the code evaluates `log(r)` directly. The p51 division
has relative error at most `u51`, and the logarithm condition number with
respect to a relative error in `r` is at most `1/log(2)`. This split is
important when `r` is tiny: forming `(x-y)/y` alone can round to exactly `-1`
and turn a finite logarithm into negative infinity.

The audited logarithm arithmetic count scales to less than `9.1e-49` at p51.
Including ratio formation and the closing division gives a conservative
relative perturbation in `w` below `1.0e-48`.

The sensitivity of `expm1(w)` to `w` is

```text
K(w) = |w exp(w) / expm1(w)|.
```

It tends to one at zero and is below one for negative `w`. A finite decimal128
`%MRR` result requires positive `w` below approximately 14,145, hence
`K(w)<14,146`. The propagated relative error is consequently below
`1.42e-44`. The p51 `WP34S_ExpM1` arithmetic adds less than `1.1e-48` relative
error. This leaves about ten decimal guard digits before the final 34-digit
conversion.

The same conservative calculation at p39 permits an error near `1.42e-32` at
the positive finite-range limit. Although sampled p39 evaluations agreed with
high-precision references, that bound cannot support a global 34-digit claim.
P34 also applies the user's directed mode during intermediate work and has the
decimal128 exponent limits. In a deliberate p34 build, the focused file had six
failures, including premature overflow for `x=1e6140`, `y=1e-6140`, `z=2`.
P51 is therefore the narrowest established project context for the positive
route. P75 adds no useful final-format margin after the stable reformulation.

## Former cancellation

The former calculation rounded `r^(1/z)` before subtracting one. For

```text
x = 1.000000000000000000000000000000001
y = 1
z = 9.999999999999999999999999999999999e6144,
```

the exact percentage is positive and slightly below `1e-6176`. The p75 power
rounded to one, so the subtraction returned zero. The revised formula retains
the small value until decimal128 conversion. The file-driven checks cover all
seven output modes: modes 0, 1, 2, 3, and 5 produce `1e-6176`; modes 4 and 6
produce zero.

A second case uses `x=1e-100`, `y=1`, and `z=1e100`. Its independently
evaluated result is

```text
-2.3025850929940456840179914546843642076...e-96.
```

The former p75 power also rounded to one in this case. The direct-logarithm
branch now produces the 34-digit value.

## Domain and special values

`y=0` retains the existing domain or special-result handling. A zero period
count has no defined reciprocal exponent. With special results disabled,
`z=0` now reports the function-domain error against register Z. With special
results enabled it returns NaN. The former route divided one by zero and could
report overflow or positive infinity instead.

Positive zero ratios continue through the retained power route, preserving its
zero-base and exponent-sign behaviour. Negative ratios normally retain the p75
real-power route, including its integral-exponent decisions and NaN results for
unsupported real roots. When the reciprocal period is an integral exponent
within the supported bound and the ratio magnitude is near one, an exact
scaled-integer difference feeds the same p51 `log1p` and `expm1` calculation.
Exponent parity supplies the sign. This avoids losing a small difference before
the negative-base power. NaNs and infinities continue through the same branch
classification and final conversion.

## Regression evidence

The file-driven `%MRR` file contains 39 successful checks after this change.
They include the small positive rate, wide positive and negative ratios,
negative-base parity, the unsupported-root policy, signed zero divisors and
both zero-period policies. A deliberate p34 substitution in the original
positive-route review demonstrated both internal underflow distortion and
premature overflow. The repository-wide result is recorded with the change
commit.

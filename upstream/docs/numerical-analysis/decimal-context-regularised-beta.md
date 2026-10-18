# Regularised incomplete-beta decimal contexts

## Scope and result

This audit covers the public `I_x(y,z)` command in
`src/c47/mathematics/ixyz.c`. Its inputs and result are Real34. The revised
entry targets faithful 34-digit accuracy; it does not claim universal correct
rounding for transcendental calculations. Differences caused only by the
final conversion from a half-even work context to Real34 are outside this
audit.

| Calculation | Selected context | Reason |
| --- | ---: | --- |
| moderate shapes | 51 | the stable log-Beta prefix and continued fraction retain a three-digit margin |
| both shapes at least `1e5` | 75 | a scaled-density integral avoids central-fraction exhaustion and needs wider logarithms |
| final conversion | Real34 | the calculator rounding mode is applied here |

## Probability-pair formation

For `0<x<1`, shape parameters `a>0` and `b>0`, the revised entry forms

```text
z = 1-x;
l = log(x)-log(z);
P = I_x(a,b);
Q = I_z(b,a).
```

The subtraction forming `z` is exact by Sterbenz's lemma. The logarithmic odds
`l` then lets the shared beta kernel retain the smaller input component without
recovering it from a rounded complement. The kernel evaluates the smaller
probability directly and obtains the larger member only after that calculation.

The former route used the older `WP34S_betai` fraction at p39. It stopped after
500 updates without a truncation check. Increasing its context to p75 did not
repair the termination error. For

```text
x = 0.5001
a = b = 1000000
```

the independent value is

```text
0.6113512821376898981392889860554324158431...
```

Both the p39 and p75 legacy variants retain only 19 significant digits. The
scaled-density route gives the displayed Real34 result.

## Moderate shapes

Below the large-shape threshold, the shared calculation combines a rearranged
Lanczos log-Beta prefix with a modified Lentz fraction. The integrated Gamma
analysis bounds the sampled Lanczos coefficient-sum condition factor by
`9.5e13`. A conservative allowance of 100 p51 operations is below `5e-35`
after that factor. The fraction change criterion is `1e-42`, eleven decimal
orders below the public target before the coefficient factor. This establishes
p51 as a suitable work context for the moderate route.

P39 has no comparable margin. At

```text
x = 1e-20
a = 0.25
b = 100000
```

the independent result is

```text
0.0001961907417418197147331102579060176839764...
```

The stable p39 variant first differs at result digit 28, while p51 produces the
correct Real34 value under every calculator rounding mode. P51 is therefore the
narrowest established project context for this route.

## Large shapes

Near the beta mode, the number of continued-fraction terms grows with the
square root of the shapes. A fixed maximum cannot cover the complete Real34
parameter range. When both shapes are at least `1e5`, the shared calculation
instead integrates the density in a scaled logit coordinate. A positive
series avoids cancellation in the density exponent near its mode. The
double-exponential quadrature reaches 15 scaled units on the remote side
and extends the requested-tail side when necessary. Its retained error analysis
and spacing comparison are in `decimal-context-f-distribution.md`.

P75 is needed for the concentrated route. For

```text
x = 0.5000000000000000000000000000000002
a = b = 5e39
```

the symmetric density identity

```text
f(1/2) = 2*Gamma(a+1/2)/(sqrt(pi)*Gamma(a))
```

and its large-`a` expansion give

```text
I_x(a,a) = 0.5000000000000159576912160573071175978424...
```

The p51 scaled calculation gives
`0.5000000000000159576912160573073209`; p75 gives the correct Real34 value.
Thus p75 is the narrowest established project context for both-large-shape
inputs.

## Endpoints, range, and reduced builds

The endpoints `x=0` and `x=1` return zero and one without logarithms. For a
finite interior input, a work result rounded to zero or one is moved to the
adjacent work value on the mathematical side. This preserves directed Real34
results for probabilities beyond its exponent range or nearer unity than
its precision permits. NaN and infinity inputs, nonpositive shapes, and
non-scalar data retain the established domain or type errors.

Some size-reduced firmware profiles omit `OPTION_DIST_C`, which contains the
shared paired-tail kernel. Those profiles use the legacy fraction at p75. That
fallback improves its arithmetic width but does not establish full accuracy
for large balanced shapes; the public build analysed here includes the paired
kernel.

## Verification

All new checks reside in the existing `ixyz.txt` file. Independent references
come from 120-digit continued fractions for moderate cases, the symmetric
large-shape expansion above, and the paired-tail integration already verified
with the F distribution. The cases cover all seven rounding modes, p39 and p51
discriminators, large balanced shapes, both direct tails, exact endpoints,
directed Real34 boundaries, invalid special parameters, and matrix rejection.

Against the initial added cases, the former p39 implementation succeeds for 28
of 35 checks and the p75 legacy variant succeeds for 29. A deliberate p39
change in the stable route succeeds for 33 of 35. A deliberate p51 change in
the large-shape route misses the retained concentrated result. The selected
implementation succeeds for all 63 focused checks. The clean repository-wide
result is 16,996 checks with zero failures and zero GMP-owned bytes.

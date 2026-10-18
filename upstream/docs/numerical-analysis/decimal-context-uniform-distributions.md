# Decimal context analysis for uniform distributions

## Scope and result

This analysis covers the continuous and discrete uniform density or mass,
lower cumulative probability, upper cumulative probability, and inverse in
`src/c47/distributions/uniform.c`. Both variants accept finite Real34 limits in
M and N. Reversed limits are exchanged before evaluation.

| Route | Working context | Reason |
| --- | --- | --- |
| Continuous density and direct tails | p39 | At most two subtractions and one division need five guard digits |
| Continuous inverse | p75 | The audited interpolation kernel can cancel two 68-digit products |
| Discrete mass and direct tails | p39 | Inclusive counts are formed before division |
| Discrete inverse | p75 | The rank product and endpoint terms can require more than p51 |
| Final Real34 conversion | p34 | The selected calculator rounding mode is applied here |

Differences confined to the accepted p39-to-p34 conversion boundary are
outside this analysis.

## Continuous forward functions

For ordered limits `a < b`, width `d = b-a`, and an interior abscissa, the
functions evaluate

```text
f(x) = 1/d,
L(x) = (x-a)/d,
U(x) = (b-x)/d.
```

The p39 context has `u39 = 5e-39`. Each nonzero subtraction is correctly
rounded relative to its mathematical result. Density therefore has relative
arithmetic error below `(1+u39)/(1-u39)-1`, which is less than `1.01e-38`.
Either direct tail adds one rounded subtraction and has relative arithmetic
error below `1.51e-38`. The p39 exponent range contains every difference and
ratio formed from finite Real34 inputs.

Repeating the bound at p34 gives about `1.51e-33`, with no complete Real34
margin. A file-driven discriminator uses

```text
a = -6.575137786851784350247730901e-14
b = -9.801611154926538605335969414e-29
x = -5.498707302233816802111167600799912e-14.
```

The correctly rounded lower probability is
`0.1637122322775490556665982648000000`. P34 forward work gives the adjacent
lower result; subtraction and scaling expose a residual of one. The complete
p34 mutation succeeds for 74 of the 75 checks in the initial focused set.

An interior direct tail can be nearer to one than p39 can distinguish. When
the p39 quotient becomes one even though the abscissa is strictly interior,
the implementation moves one p39 value towards zero. Nearest final rounding
still produces one, while directed rounding towards zero or negative infinity
produces the adjacent Real34 value. For example, `U(1e-6176)` on
`[0,1e6144]` is strictly below one and rounds to the adjacent lower Real34
value under rounding towards zero.

## Continuous inverse

The continuous inverse is

```text
Q(p) = (1-p)a + p b,  0 <= p <= 1.
```

It now delegates directly to the audited p75 linear-interpolation kernel.
The earlier implementation added one to the upper limit, interpolated, and
then rounded down to an integer. That was the discrete algorithm and gave
`Q(0.75)=2` on `[1,2]`, instead of `1.75`.

P75 is needed when opposite-sign limits make the inverse small. The retained
case has 34-digit integers `A`, `B`, and `P` satisfying

```text
P(A+B) - A*10^34 = 1.
```

With `a=-A`, `b=B`, and `p=P/10^34`, the inverse is `1e-34`. P51 loses the
67-place cancellation, as detailed in
`decimal-context-linear-interpolation.md`. The exact endpoints `p=0` and
`p=1` copy their corresponding limits without arithmetic.

## Discrete forward functions

For integer limits `a <= b`, define `N=b-a+1`. The direct functions are

```text
P(X=x) = 1/N              for integral x in the support,
L(x)   = (floor(x)-a+1)/N,
U(x)   = (b-ceil(x)+1)/N.
```

The earlier lower-tail code formed `floor(x)+1` before subtracting `a`, and
the upper-tail code formed `ceil(x)-1` before subtracting from `b`. At a large
endpoint the unit was discarded even when the final count was one. With
`a=1e40` and `b=a+1e7`, both endpoint counts became zero. The revised order
forms the endpoint difference first and then adds the inclusive unit.

P39 retains at least five digits beyond the final Real34 requirement. If a
large count discards the inclusive unit at p39, its relative contribution is
below `1e-39`; endpoint counts of one are formed without that loss. The same
strict-interior marker used by the continuous tails preserves the side below
one for directed final rounding.

## Discrete inverse

For `0 < p < 1`, the lower quantile is

```text
Q(p) = a + ceil(p*N) - 1.
```

The former `floor(a+p*N)` expression selected the next integer when `p*N`
was integral. On the three-point support `[0,2]`, it gave one rather than zero
at `p=1/3`.

The revised route forms `N`, the product, its ceiling, and the translated rank
at p75. Consider `N=10^34-1` and `p=1-10^-34`:

```text
p*N = 10^34 - 2 + 10^-34.
```

P51 discards the positive fractional part and selects the preceding integer;
p75 retains it. The deliberate p51 rank mutation succeeds for 74 of 75
focused checks. Forming `N` at p75 also fixes `a=-1`, `b=1e40`, and
`p=1e-40`, where p39 count formation loses both added units and gives `-1`
instead of zero.

There is no fixed-width guarantee for every discrete Real34 support. For
example, `a=-1`, `b=1e75`, and `p=1e-75` need more than 75 places to retain
the terms that distinguish adjacent ranks near zero. Precision proportional
to the endpoint exponent separation, or an integer coefficient algorithm,
would be required for that class. P75 is the narrowest existing fixed context
that evaluates every 68-digit product and materially extends reliable rank
classification without a multi-kilobyte dynamic real.

## Domain and special values

The continuous distribution now requires unequal finite limits. A one-point
discrete distribution remains valid, while fractional discrete limits produce
the invalid-parameter error. NaN abscissas and non-finite limits raise the
existing domain or invalid-parameter errors, while real matrices continue to
be rejected by scalar conversion. Finite-support forward functions accept
infinite abscissas and produce their mathematical endpoint values. Inverse
probabilities include zero and one and reject values outside that closed
interval.

## Verification

The final existing-file set in `dist_cov.txt` contains 83 checks and succeeds
completely. A replay of the former source against the initial 75-check set
succeeds for 67 checks. Its eight failures cover large endpoint counts, the
continuous inverse, the interpolation cancellation, infinite abscissas, and
an equal-limit continuous density. The final clean repository run succeeds for
all 16,735 checks, with no failed checks and no GMP-owned bytes. Compilation
emits only the existing linker section-alignment diagnostic.

# Decimal context analysis for general polynomial roots

## Scope and decisions

This analysis covers `fnSlvp` in `slvp.c`. It includes finite Real34 and
Complex34 coefficient vectors, the degree-specific routes, the companion
matrix construction, and conversion of the roots to Real34 components.
Short and long integers are outside scope.

| Route | Context | Reason |
| --- | ---: | --- |
| finite real linear polynomial | 34 | one correctly rounded division is the final operation |
| finite real `x^d=w` | 39 | five work digits cover the bounded angular conditioning for every feasible degree |
| finite complex linear polynomial | 75 | quotient components can cancel across 68-digit products |
| finite complex `x^d=w` | 75 | complex normalisation and small root components need the full input-product width |
| companion matrix | 75 | normalisation and eigenvalue conditioning exclude p39 and p51 |

The companion eigenvalue dependency continues at p75. Its analytic degree-two
and degree-three routes use p159 temporaries when the build enables them. The
QR route for higher degrees uses p75 matrix arithmetic. No context in
`slvp.c` is wider than the precision required by that dependency.

## Linear polynomials

For real finite coefficients, the root of

```text
a1*x + a0 = 0
```

is one correctly rounded division `(-a0)/a1`. Negation occurs before the
division so ceiling and floor apply to the mathematical result rather than to
its negative. The p34 operation therefore gives the requested Real34 result
directly under half-even, half-up, half-down, away from zero, toward zero,
ceiling, or floor. A wider intermediate adds no accuracy.

The complex calculation is different. For `a+ib` divided by `c+id`, each
component numerator is a sum or difference of two products. Real34 products
can contain 68 digits, and the final component can expose any of them after
cancellation. P75 is the narrowest established context that represents both
products exactly before their fused sum.

The stored linear discriminator has root

```text
-1.246153835007479286640426085275563E-35 + i
```

from two ordinary Complex34 coefficients. A p51 trial returns only 16 correct
digits in the small real component. P75 agrees with an independent p180
decimal evaluation through all 34 result digits.

## Real binomials

For a finite real polynomial with no middle coefficients, the calculation is

```text
w = -a0 / ad
rho = abs(w)^(1/d)
angle[k] = (arg(w) + 2*pi*k) / d.
```

The p39 division contributes at most `u39=5E-39` relatively. The decNumber
power implementation documents a result within one p39 unit in its rare
non-correctly-rounded cases. The root sensitivity to `w` is `1/d`, so the
magnitude calculation retains far more than 34 digits before rectangular
conversion.

The workspace allocation consumes 60 memory blocks per input coefficient, so
the new-hardware pool bounds this route by `d<1092`, with a smaller limit once
normal calculator state is present. A nonzero component of a real binomial
root is separated from an axis by at least `pi/(2d)`. With `d<1092`, the
relative amplification of absolute angle error is below 700. The three p39
angle operations contribute less than `1E-37` radians in total; amplification
is therefore below `7E-35` relative in the smallest possible nonzero
component. The p39 magnitude error is below `2E-38` relative. The p51
trigonometric kernel contributes less than either term. This leaves a margin
at Real34 precision after the five p39 work digits. Exact axes receive exact
zero from the retained binomial cleanup.

P34 has no guard digit for the power and angle calculation. In a deliberate
p34 trial, three stored components of the roots of `x^5=32` differed from
independent Real34 values by three to eleven units after scaling by `1E40`.
P39 gives every asserted digit and is the narrowest tested established
context for this route.

## Complex binomials

Complex `w=-a0/ad` retains p75 because its quotient components have the same
68-digit cancellation issue as the linear route. Magnitude, argument, power,
and rectangular conversion then use p75. The audited magnitude, atan2,
general-power, and trigonometric helpers are dependencies of this route.

No fixed context gives a uniform component-relative guarantee arbitrarily
close to a root axis. P75 nevertheless preserves all input-product digits and
provides 41 work digits beyond a normal Real34 component. P51 cannot provide
that result when coefficient normalisation first exposes a component below
its retained product width.

## Companion matrix

The monic companion coefficients are `-ai/ad`. Real finite coefficients now
use one p75 real division per matrix entry. Complex coefficients use the p75
complex division kernel, whose componentwise relative bound for Real34 inputs
is below `1.51E-74`. The diagonal similarity used for the existing complex
circulant-screen case also remains at p75.

P75 is the narrowest established matrix width. A perturbation of size
`epsilon` in a coefficient can move a root of multiplicity `m` by order
`epsilon^(1/m)`. P51 normalisation can therefore leave about 25 digits at a
double root, before eigenvalue iteration error. P39 is weaker. P75 can leave
about 37 digits for a double root and is the only established width with a
margin above the Real34 target in that case.

There is no uniform 34-digit result for every polynomial. Triple and higher
multiplicities, nearly defective companion matrices, and tightly clustered
roots can consume more than the 41 extra p75 positions. The result is then
conditioning-limited. The existing fourth-power case records this limitation
as an approximately 18-digit cluster.

## Genuine small components

The former post-processing erased every component more than 36 exponent
orders below the other component for a real-coefficient polynomial. Real34
coefficients do not imply such a bound because cancellation among coefficient
combinations can encode a much smaller root separation.

For exact Real34 `t=1E-72`, consider

```text
P(x) = x^3 - 1.5*x^2 + t*x + 0.5
     = (x-1)^2*(x+0.5) + t*x.
```

Writing `x=1+s` gives

```text
(1.5+s)*s^2 + t*(1+s) = 0,
s = -t/9 +/- i*sqrt(2*t/3) + O(t^(3/2)).
```

The conjugate pair therefore has imaginary components

```text
+/-8.164965809277260327324280249019638E-37
```

to Real34 precision. The old exponent test replaced both components by zero
and returned a real matrix. The revised route retains the eigenvalue
components. Exact-axis cleanup remains only in the real binomial route, where
the root angles prove which components are zero.

## Special values and result modes

The narrower real routes require finite coefficients. Any NaN or infinity
continues through the prior p75 complex calculation, preserving its special
value classification. Leading exact zeros are discarded, trailing exact
zeros are returned as roots, and a constant polynomial reports the existing
domain error.

P39 and p75 work use half-even arithmetic. Conversion of their components to
Real34 applies the selected calculator mode. The real linear route instead
applies that mode in its sole p34 division. The accepted p39-to-p34 boundary
difference is outside this analysis.

## Verification

The existing `slvp.txt` file now includes:

- the cancelled complex linear root with exact subtraction and scaling;
- `1/7` from a real linear polynomial in all seven result modes;
- all components of the fifth roots of 32 through digit 34;
- both square roots of 2 in all seven result modes;
- all components of the square roots of `i` in all seven result modes;
- the real-coefficient cubic with a genuine `8.16E-37` conjugate separation.

Before the component fix, the cubic returned a real matrix. A p34 real
binomial trial failed the scaled fifth-root case, while p39 succeeds. A p51
complex linear trial retained only 16 correct digits in the small component.
The selected contexts satisfy all focused cases.

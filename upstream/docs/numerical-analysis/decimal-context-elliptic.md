# Elliptic-function decimal contexts

## Scope and result

This audit covers ellipse-axis conversion, complete elliptic K, E and Pi, incomplete F and E, Jacobi sn, cn, dn and amplitude, Jacobi zeta, and the direct helper graph in `elliptic.c`. Parameter conversions delegate to the audited square, square-root, sine and arcsine functions. Short and long integer arithmetic is outside the audit.

| Public route | Working context | Reason |
| --- | ---: | --- |
| Ellipse axes to parameter, including real-matrix elements | 39 | The factorised identity has no squared-ratio cancellation |
| Complete K for every finite real parameter | 39 | Positive-real AGM evaluations replace the complex AGM for `m>1` |
| Complete E for `m<=1` | 39 | Positive-real AGM with about three guard digits |
| Complete E for `m>1` | 75 | Its imaginary component can be approximately `1e-34` while the real component is order one |
| Complete Pi for real `n` and `0<=m<1` | 39 | Carlson RF/RJ formulae remove the former parameter-transform cancellation |
| Incomplete F and E for real amplitude and `m<=1` | 39 | Real Carlson RF/RD formulae avoid cancellation near zero and the quarter period |
| Incomplete F and E for complex amplitude or `m>1` | 75 | Component cancellation has no uniform relative bound |
| Jacobi sn, cn, dn and amplitude, real or complex | 75 | A decimal128 argument can be adjacent to a component zero |
| Jacobi zeta, real or complex | 75 | The defining E/F subtraction and complex continuation can cancel by 34 decimal places |
| Other matrix inputs | Rejected | These entry points accept a scalar real parameter and a scalar real or complex argument |

Every fixed work context uses round-to-nearest, ties-to-even. Conversion to decimal128 applies the selected calculator mode. Differences confined to the accepted 39-to-34-digit conversion boundary are outside this analysis.

## AGM calculations

The AGM helpers previously stopped when their components differed by `1e-37`, irrespective of the supplied context. This leaves approximately nine useful digits in a Jacobi component adjacent to zero even when its caller selects p75. The termination level is now `1e-37`, `1e-49` or `1e-71` for p39, p51 or p75 respectively.

For positive inputs, one AGM update maps the ratio `r=a/b` to

```text
r' = (r+1)/(2 sqrt(r)) <= sqrt(r).
```

Once `r=1+e` is moderate, `e'<=e^2/8`. The transformed elliptic inputs reach the p75 termination level within 23 updates across the decimal128 exponent range. The stored step count is therefore 24 values. For example, Jacobi zeta at `m=-1e6000` stopped after the former 15 updates and returned

```text
-8.773845408583406297805127318402394e2999
```

instead of the independently calculated decimal128 value

```text
-8.773849755838889515095876946788550e2999.
```

The p75 update error is many orders below the `1e-71` stopping level. The trigonometric phase and the backward substitutions then have more than three decimal guard digits for a normal component of decimal128 scale.

P51 is not enough for Jacobi functions. With

```text
u = 3.141592653589793238462643383279503
m = 9.999999999999999999999999999999999e-33,
```

the independently calculated sn value is

```text
7.7381788033738582019775834027911084...e-33.
```

P51 returns `7.738178803373858205820974944592327e-33`, which has an error near `3.84e-51`. P75 gives the correct decimal128 result in all seven output modes. Exact comparisons use subtraction followed by multiplication by `1e70`, so the checks expose digit 34.

The former `m<1e-32` and `abs(m-1)<1e-32` shortcuts also discarded representable corrections. Only exact zero and exact one now select the trigonometric and hyperbolic limits. At `u=10` and `m=0.999999999999999999999999999999999`, the former cn and dn results agreed with their references for only about 25 digits.

## Complete K and E

For `m<=1`, K and E use the positive-real AGM. At p39 the `1e-37` component separation and rounded arithmetic leave about three digits beyond the result width. Decimal128 values below one limit `sqrt(1-m)` to at least approximately `1e-17`, so the iteration count is small.

For `m>1`, K now uses

```text
K(m) = (K(1/m) - i K(1-1/m)) / sqrt(m).
```

Both dependent K values have parameters in `[0,1]`; p39 therefore remains sufficient. This also avoids complex square-root selection in the complete-K route.

E for `m>1` retains the complex AGM and p75. At

```text
m = 1.000000000000000000000000000000001,
```

the expected result is

```text
0.9999999999999999999999999999999806
  + 7.853981633974483096156608458198754e-34 i.
```

P39 gives about five useful digits in the imaginary component. P51 gives about seventeen. Context-dependent AGM termination and p75 arithmetic recover all 34 result digits. Pi constants now match the selected work width, so a p75 route does not reintroduce a p39 phase error.

## Carlson duplication and complete Pi

Each RF, RD or RJ duplication divides every pairwise argument difference by four. The RF terminal approximation has an error quadratic in the relative differences. In RD and RJ, the terminal multiplier and relative differences both decrease geometrically, so omitting the correction polynomial also gives a quadratic terminal error. The implemented stopping levels are `1e-37` at p39 and `1e-49` at wider contexts. Rounded square roots, products and positive sums at p39 remain below the guard margin for the bounded real arguments used here.

For `n<1`, the revised complete third-kind calculation is

```text
Pi(n,m) = RF(0,1-m,1) + n RJ(0,1-m,1,1-n)/3.
```

This formula contains only real Carlson values with a positive fourth argument. It remains stable when `n=m`, when both parameters are small, and when `n` approaches one. The prior transformed formula at

```text
n = 0.5000000000000000000000000000000001
m = 0.5
```

retained about 20 useful digits. The direct p39 formula returns `2.701287762095351005040349470677452` through digit 34.

For the Cauchy principal value at `n>1`, put `q=m/n`. The former subtraction is replaced exactly by

```text
K(m) - Pi(q,m) = -q RJ(0,1-m,1,1-q)/3.
```

At `n=1e70`, `m=0.5`, p75 subtraction retained four useful digits. The direct p39 result is `-5.034307962536964159136756118565342e-71`.

For `n<-1`, the first characteristic transform maps `q=m/n` into `(-1,0)`:

```text
h = n(1-n)(n-m)
Pi(n,m) = -q RJ(0,1-m,1,1-q)/3 - n*pi/(2 sqrt(h)).
```

Its Carlson arguments stay bounded even for the largest finite negative characteristic. The former negative-characteristic formula was also algebraically wrong away from `m=0.5`: it returned `0.4980494432708521821083227760218992` for `Pi(-1,0.2)`, whose independently calculated value is `1.162385973778144728007667274469706`. It produced NaN at `n=-1e100`; the bounded transform gives `1.570796326794896619231321691639751e-50`.

NaN characteristics now return NaN without entering duplication. Negative infinity returns positive zero for `0<m<1`; positive infinity returns negative zero under the established principal-value convention.

## Incomplete F and E

For a real reduced amplitude,

```text
F(phi,m) = s RF(c^2,1-m s^2,1)
E(phi,m) = s RF(c^2,1-m s^2,1) - (m s^3/3) RD(c^2,1-m s^2,1).
```

The same real Carlson evaluation now covers negative `m`. The former negative-parameter F transform calculated `K-F(pi/2-phi)` and lost almost all digits when `phi` was tiny. At `phi=1e-34`, `m=-1`, it returned `9.999904099540155090076740968886775e-35`; the direct formula rounds to `1e-34`.

Real incomplete E uses its Carlson identity directly instead of deriving E from Jacobi zeta. Period extension adds an integral number of complete E values. The p39 route is appropriate for real `phi` and `m<=1`; complex amplitude formulae and real amplitudes with `m>1` retain p75. Near-axis complex checks verify the approximately `1e-34` real components of both F and E.

## Jacobi zeta and ellipse conversion

The real Carlson zeta formula subtracts two order-one values. Two local expansions cover its most severe cancellations. For `m<1e-37`,

```text
Z(phi,m) = m sin(phi) cos(phi)/2 + O(m^2).
```

The relative omitted term is below order `1e-37`. Near `phi=pi/2`, with `d=phi-pi/2` and `q=1-m`,

```text
Z(phi,m) = d (q-E(m)/K(m))/sqrt(q) + O(d^3/q^(3/2)).
```

The local formula is selected when `d^2<q*1e-37`, which bounds the relative cubic term at order `1e-37`. The general and complex routes retain p75. The `m>2` continuation is now reachable; the former outer condition made its inner branch unreachable and returned NaN for finite values such as `Z(0.5,3)`.

For ellipse semiaxes `a<=b`, the parameter is evaluated as

```text
m = ((b-a)/b) (1+a/b).
```

This is algebraically equal to `1-(a/b)^2` without subtracting two rounded values near one. Axis magnitudes are used, consistent with semiaxis lengths. Scalar subtraction and scaling verify a result near `2e-30`, and a real-matrix check covers the elementwise route.

## Verification

Independent references use 100-decimal-digit elliptic integrals. Deliberate p39 and p51 substitutions establish the context failures described above. File-driven comparisons expose digit 34 for Jacobi sn in every output mode, complete K and E next to the branch point, complete Pi across each transformed region, negative-parameter F and E, small and quarter-period zeta, the extreme negative-parameter AGM history, and ellipse conversion.

The focused existing-file set contains 565 checks after these additions. Final clean repository verification is recorded with the commit evidence.

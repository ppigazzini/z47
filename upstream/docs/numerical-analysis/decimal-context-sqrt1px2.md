# Decimal context for real `sqrt(1+x^2)`

## Scope and result

This first analysis covers the real34 input route in `sqrt1Px2Real`. The complex route is analysed separately below. A 39-digit fused multiply-add computes `1+x^2`, and a 39-digit square root produces the working result before conversion to real34.

The 39-digit working result has relative error below `7.51e-39` for every finite real34 input. This is more than the required 34-digit accuracy margin. The analysis does not claim universal correctly rounded real34 output after the final 39-to-34-digit conversion.

## Conditioning and range

For

\[
f(x)=\sqrt{1+x^2},
\]

the relative condition number is

\[
\kappa(x)=\left|\frac{x f'(x)}{f(x)}\right|=\frac{x^2}{1+x^2}\leq 1.
\]

The function is well-conditioned over the complete finite input range. A finite real34 input has adjusted exponent between `-6176` and `6144`. Its square therefore remains well inside the `-999999` to `999999` exponent range configured for `ctxtReal39`. Since `1+x^2 >= 1`, neither operation needs scaling to prevent intermediate overflow or underflow.

## Forward error at 39 digits

Let `p=39`, `u=0.5*10^(1-p)=5e-39`, and `s=1+x^2`. The working context uses round-to-nearest-even. A correctly rounded fused multiply-add gives

\[
\widehat{s}=s(1+\delta_1),\qquad |\delta_1|\leq u.
\]

The exact square root of `widehat(s)` differs from `sqrt(s)` by at most

\[
\left|\sqrt{1+\delta_1}-1\right|\leq\frac{u}{1+\sqrt{1-u}}.
\]

The correctly rounded square root contributes one further relative error of at most `u`. Including the product of these two errors gives

\[
\frac{|\widehat{f}-f|}{|f|}<7.51\mathbin{\cdot}10^{-39}.
\]

The bound is uniform because the conditioning never exceeds one and the exponent range prevents exceptional intermediate rounding.

## Context selection

Repeating the bound at 34 digits gives approximately `7.5e-34` relative error. That does not leave a complete 34-digit accuracy margin across two rounded operations. The 39-digit context reduces the bound by five decimal orders and is the narrowest established working context above 34 digits. The 51-digit context therefore uses twelve unnecessary working digits for this real route.

## Verification

The ordinary `sqrt1Px2.txt` cases include the smallest real34 subnormal, `x=1`, and the largest finite real34 value. These cover the lower input exponent, a representative conditioned value, and the upper input exponent without relying on final-digit equality.

The complex function has separate cancellation and branch behaviour, analysed in the following sections.

## Complex scope and result

The public complex34 and complex-matrix routes now use `ctxtReal39`, reduced from `ctxtReal75`. The finite kernel forms

```text
X = 1 + a^2 - b^2,
Y = 2ab,
rho = sqrt(X^2 + Y^2)
```

and evaluates the principal square root without polar conversion. The rewritten kernel has componentwise relative error below `5E-38` whenever the corresponding
exact component is nonzero. It retains a representable component beside the negative real axis even when the component ratio spans the complete Real34 exponent
range. The real route above is unchanged.

The result is faithful to 34 digits under all seven final rounding modes outside the accepted 39-to-34 boundary intervals. It is not claimed to be universally
correctly rounded.

For a finite real input, the exact value is strictly greater than `abs(x)`. If the p39 calculation loses the positive contribution and returns `abs(x)` exactly, the scalar route replaces that boundary value by its next p39 neighbour towards positive infinity. This interior marker is far below a Real34 unit, so it leaves all three nearest modes and downward modes unchanged while making round-away and round-towards-positive-infinity select the required upper Real34 neighbour. At the largest finite Real34 input those directed modes correctly produce infinity when special results are enabled and the established overflow error otherwise.

## Forming `1+z^2`

Let `u=5E-39` be the p39 unit roundoff, let `W=X+iY=1+z^2`, and let `rho=|W|`. The two identities

```text
rho^2 - (1-b^2)^2 = a^2(a^2 + 2 + 2b^2),
rho^2 - a^4         = (1-b^2)^2 + 2a^2(1+b^2)
```

give `|1-b^2| <= rho` and `a^2 <= rho`. The fused multiply-add first calculates `1-b^2`, then the second fused multiply-add adds `a^2`. If `X_hat` is the computed
real component, correctly rounded arithmetic therefore gives

```text
|X_hat-X| <= u|1-b^2| + u(|X|+u|1-b^2|)
          <= (2u+u^2)rho.
```

The kernel doubles the 34-digit input `a` before multiplying by `b`. The double has at most 35 significant digits and is exact at p39, so

```text
|Y_hat-Y| <= u|Y| <= u rho.
```

Consequently the norm of the perturbation in `W` is below `2.24u rho`. This bound remains proportional to `|W|` when the terms in `X` cancel. An exact zero in
`1-b^2`, `a`, or `b` does not weaken the bound.

## Cancellation-free principal square root

The previous kernel converted `W` to polar form, halved its argument, and converted it back. For `X<0` and tiny nonzero `Y`, rounding an angle close to `+/-pi`
discards the distance from the cut. No practical fixed angular precision can cover a component ratio exceeding 6,000 decimal orders.

The revised finite non-axis route uses

```text
X_hat >= 0:  U = sqrt((rho_hat + X_hat)/2),  V = Y_hat/(2U),
X_hat <  0:  V = sign(Y_hat)sqrt((rho_hat - X_hat)/2),  U = Y_hat/(2V).
```

The square-root argument is always the sum of the magnitude and the absolute value of the selected real component. The smaller component comes from division, so
the kernel never subtracts nearly equal values. The identities

```text
Y^2 = (rho-X)(rho+X),
U^2-V^2 = X,
2UV = Y
```

establish the formula and its branch sign.

The p39 complex-magnitude analysis bounds its arithmetic error below `2.02u` relative to the supplied vector. Combining that bound with the input perturbation gives
`|rho_hat-rho| < 4.27u rho`. If the rounded sign of `X_hat` differs from the sign of `X`, then `|X| <= (2u+u^2)rho`; either selected sum is still at least
`(1-2.01u)rho`. Accounting for the addition, division by two and square root bounds the relative error of the larger component below `6u`. The multiplication error
in `Y_hat`, division by that component, and final division by two bound the smaller component below `10u=5E-38`.

When `Y_hat` is exact zero, `sqrtComplex` takes its algebraic axis branch and performs no polar conversion. This preserves the earlier choice of the positive
imaginary root on the negative real axis and avoids division by zero.

## Exponent range and context selection

Finite Real34 inputs have adjusted exponents from `-6176` through `6144`. `X` and `Y` can reach adjusted exponent `12290`; the squared-magnitude work can reach
`24580`; and the final working components can reach `6145`. All are inside the `+/-999999` exponent range of `ctxtReal39`. The final conversion alone applies
Real34 underflow or overflow.

At p34 the same conservative component bound is `5E-33`, with no 34-digit accuracy margin. `ctxtReal34` also follows the selected user mode rather than the
half-even rounding assumed in the error calculation. Its Decimal128 exponent range creates a separate failure: squaring the largest finite imaginary component
overflows even though the p39 calculation has a finite value before the final conversion. Among the established 34, 39, 51 and 75 digit contexts, p39 is therefore
the narrowest suitable choice. P51 and p75 add digits without repairing the polar loss because the stable formula removes that loss directly.

No finite relative guarantee exists after conversion for a nonzero component below the Real34 subnormal range. Nearest modes have absolute conversion error at most
`0.5E-6176`, and directed modes have absolute conversion error below `1E-6176`. An exact-zero component stays exact.

## Branches, callers and verification

The zero-imaginary input route retains its real square-and-root formula. A real infinity with zero imaginary component returns positive infinity and zero. A NaN real
component with zero imaginary component returns NaN and zero. If the imaginary component is nonzero, any NaN or infinity component returns two NaNs, matching the
previous classifications.

Complex matrices use the same public route once per element. `ArcsinComplex` and `arccosCplx` already request p39 from `sqrt1Px2Complex`; they gain the algebraic
kernel, but the accuracy of their following logarithmic formulae is outside this analysis.

Independent 200-digit decimal evaluation gives

```text
sqrt(1 + (-0.00004485256281376128640488382974
          - 7.251778431785372233108258235E-15 i)^2)
  = 1.0000000010058761949753074229432292196718255...
    + 3.2526084729596058069891687423939803844386621...E-19 i.
```

The file-driven cases assert all 34 digits of this value under all seven rounding modes by scaling the subtraction residual. They also cover both sides of the
negative-real cut at the minimum subnormal input, the maximum finite input exponent, and matrix dispatch.

For `z=1E-6176+2i`, the exact real result is `1.1547005383792515290182975610039149...E-6176`. The previous p75 polar kernel instead returned
`5.377150543940885196474998824038380E-75`, which is the trigonometric residual after its angle rounded to pi. With unchanged source, 55 of the 59 focused checks
succeeded and four failed. A temporary p34 selection in the algebraic kernel succeeded in 53 checks and failed six, including five full-digit cases and the maximum
finite exponent. The p39 algebraic kernel succeeds in all 59 focused checks.

A clean simulator build followed by the complete integrated suite succeeds in all 15,166 checks with no failures in 233.70 seconds.

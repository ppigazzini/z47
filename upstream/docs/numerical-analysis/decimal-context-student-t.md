# Decimal context analysis for the Student t distribution

## Scope and accuracy claim

This analysis covers `WP34S_Pdf_T`, `WP34S_Cdf_T`, `WP34S_Cdfu_T`,
`WP34S_Qf_T`, and their calculator entry functions in
`src/c47/distributions/t.c`. The output type is Real34. Differences caused
only by rounding a 39-digit value to Real34 are outside this audit.

The revised routines target faithful 34-digit results throughout the finite
Real34 domain. They do not claim universal correct rounding. The final digit
can depend on approximation error and on the selected decNumber rounding
mode.

For the bounds below, let

```
U(p) = 10^(1-p)
```

be a conservative relative error for one p-digit basic operation in any of
the seven rounding modes. Round-to-nearest has half this bound. Thus p39 has
four decimal guard digits beyond Real34, while p51 has sixteen.

## Density

Put `z = nu/2`, `x = z-1`, and `R = x+g+1/2` for the N=30 Lanczos
approximation. If `A(x)` is its rational sum, the logarithm of the density
normalising factor is evaluated as

```
log C(nu) = log(A(x+1/2)/A(x))
          + z log1p(1/(2R)) - 1/2
          + (1/2) log(R/(pi nu)).
```

This identity replaces
`logGamma(z+1/2)-logGamma(z)-log(pi*nu)/2`. The latter subtracts quantities
of size `z log z` to obtain an O(1) result and loses all useful digits when
`nu` is large.

The integrated Lanczos coefficient storage has 75 digits. Its alternating
rational sum is ill-conditioned for intermediate positive arguments. Direct
high-precision evaluation of the source coefficients gives a condition number
about `9.48e13` near `z=398`. A p39 sum can therefore lose about fourteen
digits and is unsuitable for a Real34 result. With p51 arithmetic, a
conservative `60 U(51)` accumulation allowance multiplied by this condition
number is below `6e-35`. This is the limiting error in `log C` and establishes
p51 as the narrowest existing context for this kernel. The extra cancellation
near zeros of `logGamma`, which requires p75 in the general Gamma kernel, is
absent from this stable half-step ratio.

The remaining expression

```
log f(x;nu) = log C(nu)
            - ((nu+1)/2) log1p(x^2/nu)
```

also uses p51. Near the Real34 underflow edge, its magnitude can exceed
`1.4e4`; p39 would spend almost all five of its extra digits when the product
is rounded. P51 keeps more than eleven decimal digits of margin even there.
One final operation rounds to the caller context.

For `a=nu/2<=1e-12`, subtracting one from `a` would erase `a` once it is
smaller than the p51 unit roundoff. This range instead uses

```
log C(nu) = (1/2)log(nu) - log(2) - log(A),
A = a B(a,1/2),
```

with the small-`a` series given in the inverse section below. This also keeps
finite densities valid at the least positive Real34 degree of freedom.

## Lower and upper probabilities

For nonnegative `x`, define

```
q = x^2/(nu+x^2),       z = nu/(nu+x^2),
D = F(x)-1/2 = (1/2) I_q(1/2,nu/2),
Q = 1-F(x)   = (1/2) I_z(nu/2,1/2).
```

The beta prefix is formed from `rho=x^2/nu` as

```
L = (1/2)(log(rho)-log1p(rho))
  - (nu/2)log1p(rho) - log B(1/2,nu/2).
```

This formulation remains usable when `q` rounds to one, when `z` is tiny,
and when `x^2` and `nu` differ by thousands of decimal exponents. A modified
Lentz fraction uses p51. Its acceptance threshold is `1e-37`, chosen for the
p39 consumer. For `nu>=1`, inverse sensitivity does not magnify that error by
a large factor. The threshold leaves about three decimal digits beyond the
Real34 target. This successive-change test is a faithful-accuracy criterion,
not a rigorous continued-fraction remainder bound.

The same p51 half-gamma kernel supplies `log B`. P39 is not suitable because
of the Lanczos conditioning described above. The 75-digit coefficient storage
prevents coefficient rounding from being limiting, but p75 arithmetic is not
needed for this stable ratio.

For `nu>=1e17`, a four-term large-degree expansion is used:

```
Q_nu(x) = Q_normal(x) - phi(x) sum(k=1..4, Qk(x)/nu^k) + R5.
```

The code evaluates each polynomial by fused multiply-add. A nonzero Real34
normal tail has `|x|<169`; at the selected degree threshold,
`x^4/nu < 8.2e-9`. The leading fifth-order relative scale is then below
`4e-41`. Values beyond that range have a positive exact tail below the
Real34 range. A tiny positive internal value preserves directed underflow
behaviour.

Negative arguments use symmetry. Zero gives one half. Finite infinities give
the exact probability endpoints. Positive infinite `nu` selects the normal
distribution. NaN and nonpositive `nu` produce a domain result.

## Inverse, `nu >= 1`

The inverse works on the smaller tail probability and applies its sign once
at the end. A factor-of-two search creates a bracket. Refinement uses the
Halley step for

```
R(t) = Q_nu(t)-p,
step = R/f,
t_new = t + step / (1-step*(nu+1)*t/(2*(nu+t^2))).
```

`R>0` moves the lower endpoint and `R<0` moves the upper endpoint. Any
nonfinite or out-of-bracket proposal is replaced by the midpoint. After 24
Halley attempts, midpoint refinement is mandatory. The remaining 136
iterations reduce an initial factor-of-two bracket by more than `1e40`, so
the p39 `1e-37` bracket target has a finite convergence guarantee.

When `t<1`, the residual is instead

```
R(t) = (1/2-p) - D(t).
```

`D` is computed directly with the lower-beta fraction. This avoids forming
`0.5-D` and retains a Real34 probability one unit below one half. For the
large-degree expansion, the corresponding direct expression is

```
D = erf(t/sqrt(2))/2 + phi(t) sum(k=1..4, Qk(t)/nu^k).
```

The solver variables and bracket use p39. The beta and half-gamma kernels use
p51. Around the median, `D/(t f(t))` tends to one. In a heavy tail,
`|d log(t)/d log(p)|` tends to `1/nu`. These conditions are O(1) for
`nu>=1`, so p39 retains its four extra digits. P34 has no error margin for
the bracket or Halley arithmetic.

## Inverse, `0 < nu < 1`

Unscaled inversion is ill-conditioned in this region. In a far tail,
`|d log(t)/d log(p)|` approaches `1/nu`; near the median, forming
`0.5-D` loses the entire central probability. Increasing an unscaled context
does not remove either effect.

The revised p51 algorithm sets `a=nu/2` and `A=a B(a,1/2)`. For
`q=r^2<=1/4`, it solves

```
r K(r^2) = (1/2-p) A/a,
K(q) = 2F1(1/2,1-a;3/2;q).
```

All series terms are positive, and the derivative of `r K` is at least one.
Also `d log(t)/d log(r)=1/(1-q)<=4/3` for
`t=sqrt(nu)*r/sqrt(1-r^2)`. This branch is well-conditioned.
The interval refinement permits 300 midpoint steps. For `0<a<1/2`,
`B(a,1/2)>=pi` and `K<=atanh(r)/r<=log(3)`. At the closest non-median
Real34 probability this gives `r>=pi*1e-34/log(3)`. After 244 midpoint steps,
the relative width is already below `6.2e-41`; 300 has ample margin.

For the tail branch put `z=exp(-s)<=3/4` and

```
H(z) = 2F1(a,1/2;a+1;z) = 1+a J(z),
G(s) = s + log(A)/a - log(H)/a + log(2p)/a.
```

`log(H)/a` is evaluated as `log1p(a J)/a`, and probabilities near one half
use `log1p(-2(1/2-p))/a`. The derivative implemented with the weighted series
is at least one. Since
`d log(t)/ds = 1/(2(1-exp(-s))) <= 2`, the transformed root has bounded
sensitivity. The result is recovered with `sqrt(nu*expm1(s))`.
After 24 Newton attempts, midpoint refinement is mandatory. The finite-output
precheck bounds the initial `s` interval by about `3e4`; the remaining 176
steps reduce its width below `4e-49`.

For `a<=1e-12`, cancellation in `log(a)+log B(a,1/2)` is removed by

```
log(A)/a = 2 log(2) - zeta(2)a + 2 zeta(3)a^2
         - (7/2) zeta(4)a^3 + O(a^4).
```

The first omitted term is `6 zeta(5)a^4`, below `6.3e-48` at the cutoff.
Above the cutoff, p51 evaluation of the generic expression loses at most
about twelve digits through division by `a`, leaving at least p39 quality.
P39 is not defensible below the cutoff because the cancellation and division
can consume its entire Real34 margin. P51 is therefore the narrowest
established context for this transformed branch. P75 is unnecessary.

## Special values and rounding modes

The exported routines reject NaN probabilities, probabilities outside
`(0,1)`, NaN degrees of freedom, negative degrees of freedom, and zero degrees
of freedom. Positive infinite degrees of freedom select the normal density,
tails, or quantile; negative infinity is a domain value. The median quantile
is positive zero. The inverse applies its sign before rounding to the caller
context, which is required for directed modes. Finite density and tail
underflow use a positive internal sentinel, allowing each directed rounding
mode to choose zero or the least positive Real34 value. Finite inverse
overflow uses the same idea before the final sign is applied.

The p39 and p51 work contexts use half-even; the final Real34 conversion uses
the calculator rounding selection. Replacing half an ulp by the conservative
`U(p)` bound above covers the final conversion in all seven modes. Branch
inequalities depend on quantities separated by far more than the p39 or p51
error bounds, except at equivalent formula boundaries where either branch has
the same mathematical value. As specified for this audit, a difference caused
only by the p39-to-Real34 conversion is not treated as a kernel error.

## Regression evidence

The pre-change implementation produced, among other failures:

- `PDF(0,nu=1e40) = 5.641895...e-21` instead of the normal-limit value
  `0.3989422804...`.
- At `nu=1e38,x=1`, the density was `177.419...`, the lower probability was
  `444.116...`, and the upper probability was negative.
- Inversion reported no root for `nu=.001,p=.49`, `nu=.01,p=.25`,
  `nu=.1,p=.25`, and `nu=.5,p=.01`.
- `nu=1,p=0.5-1e-34` lost several central digits.
- `nu=1e100,p=1e-6176` returned about `-148.779` instead of
  `-168.6103138625217570827013625786623`.

The file-driven tests now include the large-degree density and both tails,
positive infinite degrees of freedom, tiny degrees of freedom, the scaled
series boundary, central probabilities one Real34 unit below one half,
finite overflow, very small tail probabilities, and invalid NaN inputs.
Independent high-precision beta evaluation supplied the numerical values.

# Weibull distribution decimal contexts

## Scope and result

This audit covers the Weibull density, lower probability, upper probability,
inverse, and calculator entries in `src/c47/distributions/weibull.c`. With
scale `b>0` and shape `t>0`, write

```text
A = t log(x/b),  a = exp(A).
```

For `x>0`, the four calculations are

```text
f(x) = (t/x) a exp(-a),
L(x) = 1-exp(-a),
R(x) = exp(-a),
Q(p) = b [-log(1-p)]^(1/t).
```

The public result type is Real34. Differences caused only by conversion from
p39 to Real34 are outside this audit.

| Calculation | Selected context | Reason |
| --- | ---: | --- |
| density | 51 | the large scaled-power sensitivity exceeds the five p39 guard digits |
| lower probability | 39 | the compensated ratio and `expm1` retain small differences |
| upper probability | 39 | the outer exponential can amplify error in `A` by about four decimal places |
| inverse | 39 | two logarithms, a division, and an addition need guard digits |
| exact support values | caller context | zero, one, reciprocal scale, and infinity need no wider work |
| final result | caller context, then Real34 | calculator rounding is applied after the complete result is available |

The revised calculations target faithful 34-digit results. They do not claim
universal correct rounding. P51 is needed only by the density; p75 provides
no useful accuracy gain for these conditioned formulae.

## Scaled power

Forming `x/b` directly can lose the entire scaled power. The ratio can
underflow or overflow even when multiplication by `t` brings its logarithm
back into the useful range. A ratio close to one can also round to one before
a large shape magnifies its difference.

The revised helper evaluates `log(x/b)` in two regions. When

```text
delta = (x-b)/b >= -1/2,
```

it uses `log1p(delta)`. For `x` and `b` within a factor of two, the initial
subtraction is exact by Sterbenz's lemma. The relative condition factor for
the logarithm through `delta` is at most `1/log(2)` in this region. When the
ratio is below one half, it uses `log(x)-log(b)` instead. This avoids a
`delta` which rounds to negative one and keeps both logarithm arguments away
from the sensitive end of `log1p`.

Two retained cases exercise the two regions. For adjacent Real34 inputs,

```text
x = 1.234567890123456789012345678901235
b = 1.234567890123456789012345678901234
t = 1e33,
```

independent 180-digit Decimal arithmetic gives

```text
a    = 2.247908003063720850906...
f(x) = 1.923133861415989654059502563544037e32...
L(x) = 0.8943800497850706410852388209743220...
R(x) = 0.1056199502149293589147611790256780...
```

For a ratio far below one,

```text
x = 1e-40,  b = 1,  t = 0.025,
```

the exact scaled power is `a=0.1`. Using `log1p` on a rounded negative-one
`delta` gives endpoint results, while separate logarithms retain

```text
f(x) = 2.262093545089898932910622648616092e37...
L(x) = 0.09516258196404042683575094055356338...
R(x) = 0.9048374180359595731642490594464366...
```

The more extreme values `x=1e-6144`, `b=1e6144`, and `t=0.5` have
`a=1e-6144`. Direct division underflows, but the logarithmic calculation
returns a density of `0.5` and a lower probability of `1e-6144`.

## Probabilities

The probability routes evaluate

```text
L(x) = -expm1(-a),
R(x) = exp(-a).
```

The lower route therefore avoids subtracting an upper probability close to
one. Its relative condition factor with respect to `A` is

```text
a exp(-a) / (1-exp(-a)) <= 1.
```

For an upper probability which can affect a Real34 digit,

```text
a < log(10^6177) < 14223.
```

The relative condition factor of the upper probability with respect to `A`
is `a`. Here `A=log(a)` is at most about `9.6`. Its p39 absolute rounding
error is below about `5e-39`; amplification by `a` consumes fewer than 4.2 of
the five guard digits. P39 therefore retains a margin beyond Real34. P34 has
no such margin.

A deliberate p34 substitution changes six retained results across the four
routes. The lower extreme case becomes
`9.9999999999999999999999999999369e-6145`, and a directed upper result near
one becomes `0.9999999999999999900000000000000000`. These measured changes
establish p39 as the narrowest tested probability context.

## Density

The density is evaluated through

```text
log(f(x)) = log(t)-log(x)+A-exp(A),
f(x) = exp(log(f(x))).
```

This form avoids an early underflow or overflow in `a` followed by a scaling
operation in the opposite direction. It also avoids division by a ratio
which has rounded to zero.

For a density inside the Real34 exponent range, `log(f(x))` has magnitude
below about 14223. The largest possible `log(t/x)` is below about 28370.
Consequently, a relevant `a` is below about 42600; beyond that point the
negative `a` term forces the density below the result range. The sensitivity
of `log(f)` to `A` is `1-a`. Since `A=log(a)` is near 10 at this outer bound,
a p39 rounding of `A` can produce about `2e-33` error in `log(f)`. This is
insufficient for a 34-digit result. P51 reduces the corresponding bound below
`3e-45` and leaves more than ten guard digits.

The retained p39 discriminator is

```text
x = 1.000000000000000000000000000000001e-6143
b = 1e-6143
t = 1.016370519767229819295101392885817e34
a = 25944.24775821438819379790680931993...
```

Independent arithmetic gives

```text
f(x) = 9.494117874160681850261189195514096e-5087...
```

P39 returns a Real34 value ending in `...4109`; p51 returns `...4096`. After
subtraction from the expected Real34 value and scaling by `1e5150`, the p39
residual has magnitude `1.3e31`, while the p51 residual is zero.

At p34, an existing large-argument density retains only about 29 correct
digits. The underflow-recovery density also becomes
`0.499999999999999999999999999940883`, rather than the Real34 value `0.5`.
P51 is the narrowest tested density context.

The endpoint is treated from the limiting density:

| Argument and shape | Density |
| --- | ---: |
| `x<0`, including negative infinity | 0 |
| `x=0`, `0<t<1` | positive infinity |
| `x=0`, `t=1` | `1/b` |
| `x=0`, `t>1` | 0 |
| positive infinity | 0 |

## Inverse

The inverse uses the logarithmic form

```text
u = -log1p(-p),
log(Q(p)) = log(b) + log(u)/t,
Q(p) = exp(log(Q(p))).
```

This avoids an early underflow in `u^(1/t)` followed by multiplication by a
large scale. For example,

```text
p = 1e-6144,  b = 1e6144,  t = 0.5
```

has the Real34 quantile `1e-6144`; the direct power route returns zero.

For an interior Real34 probability, `log(u)` is bounded below by about
`-14223` and above by about `4.4`. If `log(u)/t` can contribute to a finite
Real34 result after adding `log(b)`, its magnitude is below about 28446.
P39 division and addition errors at this magnitude remain at the 34-digit
scale. A p34 substitution changes the recovery case to
`1.00000000000000000000000000001369e-6144`, with about 28 correct digits.
P39 is the narrowest tested inverse context.

The exported kernel defines `p=0` as zero and `p=1` as positive infinity.
The calculator entry retains the existing strict `0<p<1` interface.

## Directed rounding and exponent endpoints

For finite positive `x`, `b`, and `t`, both probabilities are strictly
between zero and one and the density is positive. Every interior inverse is
also positive. A p39 exponential can nevertheless round one of these values
to zero or one at its own exponent or precision boundary.

The revised kernels move such a rounded endpoint by one p39 unit toward the
interior before Real34 conversion. Under nearest conversion the marker can
still become the exact Real34 endpoint. Under upward or toward-positive
conversion, a positive underflow becomes `1e-6176`; under downward or
toward-negative conversion, a finite value below one becomes the Real34
predecessor of one. Exact support values are not adjusted.

## Domains, special values, and matrices

The scale and shape must be finite and positive. Zero, negative, infinite,
and NaN parameters are distribution-parameter errors. NaN arguments are
argument-domain errors. With special-result mode set, either condition
returns NaN without a retained diagnostic code.

The three forward functions extend across the whole real line by their
distribution values:

| Argument | density | lower | upper |
| --- | ---: | ---: | ---: |
| `x<0`, including negative infinity | 0 | 0 | 1 |
| `x=0` | shape-dependent limit | 0 | 1 |
| positive infinity | 0 | 1 | 0 |

Real and complex matrices are rejected by `getRegisterAsReal`; no elementwise
Weibull operation is defined. File-driven cases assert this interface
behaviour for all four public functions.

## Regression evidence

Expected numeric values were computed independently with 180-digit Decimal
arithmetic. The focused files contain 201 cases. With p51 for the density and
p39 for the other routes, all 201 complete successfully. P39 for the density
fails its scaled-residual discriminator. Changing every public route to p34
causes six earlier discriminators to fail. Replacing the two-region
logarithmic ratio with the sensitive `log1p` region for all finite deltas also
causes six failures, including all three `x=1e-40` discriminators.

The clean complete file-driven suite on integration base `4178623` completes
all 17,183 cases.

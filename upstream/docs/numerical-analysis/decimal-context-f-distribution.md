# F-distribution decimal contexts

## Scope and result

This audit covers the F density, lower probability, upper probability, inverse,
and calculator entry functions in `src/c47/distributions/f.c`. The public result
type is Real34. The register interface requires positive integral degrees of
freedom. Matrix arguments have no elementwise distribution route and produce
the established type error.

The revised routines target faithful 34-digit results. They do not claim
universal correct rounding. Differences caused only by conversion from p39 to
Real34 are outside this audit.

| Calculation | Selected context | Reason |
| --- | ---: | --- |
| density and beta tails, degrees below 200000 | 51 | stable Lanczos form and direct-tail fraction leave at least three guard digits |
| density and beta tails, both degrees at least 200000 | 75 | concentrated beta probabilities amplify an error in `log(x)` and require scaled integration |
| inverse state, degrees below 200000 | 51 | logarithmic conditioning is at most two for positive integral degrees |
| inverse state, both degrees at least 200000 | 75 | it shares the scaled probability evaluation |
| final public result | caller context, then Real34 | calculator rounding is applied once after the sign and reciprocal are known |

## Density and beta prefix

Put

```text
a = d1/2,  b = d2/2,
y = d1*x/(d1*x+d2),  z = d2/(d1*x+d2).
```

The density is evaluated through its derivative in logarithmic coordinates,

```text
x*f(x) = y^a z^b / B(a,b).
```

The former density expanded this identity into terms proportional to `d1` and
`d2`, then subtracted them. At `d1=d2=1e40` it returned one instead of
`1.994711402007163389699730299671909e19`. No fixed width in p39, p51, or p75
repairs that formula over the full Real34 parameter range.

For moderate arguments, log-Beta is one rearranged Lanczos expression. If
`R_a=a+g-1/2`, `R_b=b+g-1/2`, `R_s=a+b+g-1/2`, and `A` is the 30-term Lanczos
sum, then

```text
log B(a,b) = log A(a) + log A(b) - log A(a+b)
             + 1 - gammaR
             - (a-1/2) log1p(b/R_a)
             - (b-1/2) log1p(a/R_b)
             - (1/2) log(R_s).
```

Arguments below one are shifted by the beta recurrence. The powers use the
logit `log(y/z)`, so a component much smaller than one is never recovered by
subtracting its complement from one.

When both shapes are large, the prefix groups its logarithms around the beta
mode. This replaces cancellation proportional to `a+b` by `log1p` arguments
proportional to the distance from the mode. The integrated Gamma audit found a
Lanczos-sum condition factor below `9.5e13`. A conservative 100-operation p51
bound is below `5e-35` after this factor, which leaves about three decimal guard
digits. P39 can retain only about 25 useful digits and is unsuitable. The
75-digit coefficient storage remains the source for both work widths.

The exact density endpoints are

```text
f(0) = +Infinity for d1<2,
f(0) = 1         for d1=2,
f(0) = 0         for d1>2,
f(+Infinity) = 0.
```

## Lower and upper probabilities

Both `y` and `z` are formed from their logit, without a rounded subtraction.
The lower and upper probabilities are

```text
P = I_y(a,b),        Q = I_z(b,a).
```

The smaller direct side uses a modified Lentz fraction at p51. Its successive
change criterion is `1e-42`, with a 1000-iteration maximum and an explicit
failure result. This criterion is a faithful-accuracy test, not a formal
continued-fraction remainder bound. It has eleven decimal orders beyond the
Real34 target before Lanczos conditioning. Symmetry gives exactly one half
when `a=b` and `y=z`.

Central large-shape fractions need a number of terms proportional to the square
root of the shapes. Increasing the old 500-term maximum is therefore not a
finite solution. For `a,b>=1e5`, the revised route integrates the logit density
in a scaled coordinate

```text
v = log(x) / sqrt((a+b)/(a*b)).
```

The mode is `x=1`. At an integration point, the density relative to its mode is
formed from the nonnegative divergence

```text
D = (a+b) [p log(p/y) + q log(q/z)],
p=a/(a+b), q=b/(a+b).
```

Near the mode, a positive power series beginning with
`(a+b)*(y-p)^2*(1/p+1/q)/2` avoids subtracting the two linear terms. Elsewhere,
direct `log1p` terms have ample separation. A double-exponential map with
spacing `1/32` integrates the scaled density. The finite interval reaches 15
mode scales on the remote side; deeper requested tails extend the endpoint by
`50/abs(v)`. Log-concavity makes the omitted endpoint contribution smaller
than the representable probability range in the deep-tail branch. Repeating
the discriminator calculations at spacing `1/64` produced identical Real34
values.

P51 is insufficient for this route. At

```text
d1=d2=1e40, x=1.000000000000000000000000000000001
```

the p51 candidate differed in the 32nd decimal place, while p75 gives

```text
P = 0.5000000000000199471140200716338970.
```

P75 is therefore the narrowest established project context for concentrated
probabilities. It also permits a p75 logarithm of the exact Real34 input before
the probability density magnifies its error.

## Inverse

The inverse solves only a probability at most one half. The identity

```text
F_inverse(d1,d2,p) = 1 / F_inverse(d2,d1,1-p)
```

handles the upper half without evaluating a lower CDF close to one. The solver
variable is `w=log(x)`, and its derivative is the stable beta prefix

```text
dP/dw = x*f(x) = y^a z^b/B(a,b).
```

For a lower-tail probability `p`,

```text
d log(x) / d log(p) = p/(x*f(x)) -> 1/a = 2/d1.
```

The upper-tail limit is `2/d2`. Positive integral degrees therefore give a
condition number no greater than two. P51 state has sixteen digits beyond the
public result and is sufficient for the moderate route. P34 has no error
margin.

Newton proposals are accepted only inside a finite bracket. After 24 proposals,
midpoint refinement is mandatory. The fixed log interval is wider than the
finite Real34 output interval; a mathematical root beyond it already rounds to
zero or infinity. The `1e-40` bracket target bounds relative uncertainty in a
finite result, and a change below `1e-38` is an additional p51 certificate.

The shared `WP34S_Qf_Newton` midpoint was changed in prior commit `79a488f`
from `2*(low+high)` to `(low+high)/2`. This audit verifies that correction. F no
longer depends on the shared solver because its zero-based relative bracket,
rounded lower CDF, zero-density exit, and 100-iteration maximum are unsuitable
for continuous deep tails. Discrete distribution callers remain unchanged.

## Domains, matrices, and rounding modes

Both degree parameters must be positive finite integers. The former Boolean
test rejected them only when both were nonintegral; one fractional or NaN
parameter could enter the kernels. NaN `x` and NaN inverse probability now
produce the domain result. Infinite `x` has the exact support endpoint, while
infinite degrees are rejected because this interface defines a finite-degree F
distribution.

Real and complex matrices are rejected by `getRegisterAsReal`; no matrix
calculation calls an F kernel. File-driven cases now make that interface
decision explicit.

Internal contexts use round-to-nearest, ties-to-even. Conversion to Real34
applies each of the seven calculator modes. All finite F values are positive.
The inverse keeps a positive extended value through reciprocal selection, so
toward-positive and away-from-zero conversion of a mathematical value below the
least Real34 subnormal produces that subnormal. Nearest, toward-zero, floor,
and ties-to-zero produce positive zero in the retained underflow case.

## Regression evidence

Before this change:

- `d1=d2=1e40, x=1` gave density one and NaN for both probabilities;
- `d1=1, d2=1e40, x=1` gave density one and lower probability about
  `2.82e-20`, instead of the chi-square limits;
- F(1,1) inverse at `p=1e-21` gave about `3.37e-39` instead of
  `2.467401100272339654708622749969038e-42`;
- F(1,1) inverse at `p=1-1e-34` reported no root;
- equal degrees `1e10` produced negative lower and upper probabilities;
- a fractional degree paired with an integer was accepted.

Independent values used 160-decimal-digit regularised-beta evaluation,
closed forms for F(1,1) and F(2,2), and direct high-precision integration of
the scaled logit density. The existing `f_p.txt`, `f_l.txt`, `f_r.txt`, and
`f_i.txt` files contain the retained cases. They cover density range,
concentrated and one-sided degrees, both tails, inverse tail symmetry,
underflow rounding, exact endpoints, invalid parameters, and matrix rejection.

# Decimal context analysis for Fibonacci

## Scope and result

This analysis covers the real and complex continuation of Fibonacci in
`src/c47/mathematics/fib.c` and elementwise real and complex matrix evaluation.
Short and long integer Fibonacci calculations use separate integer algorithms
and are outside this analysis.

| Calculation | Selected context | Reason |
| --- | ---: | --- |
| real `abs(x) < 0.1` | 39 | a cancellation-free identity retains more than two decimal guard digits |
| real `x >= 0.1` | 51 | multiplication by a large exponent magnifies the error in `log(phi)` |
| real `x <= -0.1` | 75 | the real continuation has additional zeros, so its Binet terms can nearly cancel |
| complex with nonzero imaginary part | 75 | either component can nearly vanish after cancellation of order-one terms |
| real or complex matrix | same as each element | matrix dispatch invokes the scalar entry for every element |

These are the narrowest established choices among 34, 39, 51, and 75 digits.
The work contexts use round-to-nearest, ties-to-even. Conversion to decimal128
applies the selected user mode. Differences caused only by an accepted
39-to-34-digit boundary effect are outside this choice.

## Formula and computed constants

Write

```text
L = log(phi),
u = L z,
F(z) = (exp(u) - exp(-u) cos(pi z)) / sqrt(5).
```

The former code used a 39-digit stored `phi` in every context. The revised code
computes `sqrt(5)`, `phi=(1+sqrt(5))/2`, and `L=log(phi)` in the selected work
context. This is required for the p51 and p75 routes. A p75 calculation based on
a p39 `phi` would retain only the p39 constant error.

The separate square-root, logarithm, exponential, sine/cosine, hyperbolic, and
complex-multiplication analyses apply to these operations. The elementary
arithmetic is correctly rounded at the supplied width.

## Stable region around zero

Direct Binet subtraction loses the result as `z` approaches zero. The revised
real and complex routes use

```text
F(z) = exp(-u) [expm1(2u) + 2 sin(pi z/2)^2] / sqrt(5).
```

Both small factors are formed without subtracting rounded values near one. For
real `abs(x) <= 0.1`, `abs(u) <= 0.048122`. On the positive side the bracketed
terms have the same sign. On the negative side,

```text
2 sin(pi x/2)^2 / abs(expm1(2Lx)) <= 0.534.
```

The condition factor of their closing addition is therefore below 3.29. The
completed p39 `expm1` bound, the p75 reduced-angle sine calculation, the
correctly rounded products, and this bounded addition retain more than two
guard digits for a Real34 result. A p34 experiment fails all seven exact
rounding-mode checks for `F(1e-35)`; the p39 route succeeds in every mode.

For a complex input in the same componentwise square, `expM1Complex` and the
half-angle sine run at p75. This protects both the linear component and the
quadratic component. Independent 180-digit decimal arithmetic gives

```text
F(i 1e-35).real
  = -2.2069106351866905310343849242580125864...e-70,
F(i 1e-35).imag
  =  4.3040894096400403888943323295060542542...e-36.
```

The former direct formula returned a zero real component. The new test scales
the real-component error by `1e105`, so the file-driven comparison checks all
34 significant digits.

## Positive real inputs

For `x >= 0.1`, rewrite the numerator for conditioning analysis as

```text
exp(-u) [exp(2u) - cos(pi x)].
```

It is positive and its subtraction condition is bounded by

```text
(exp(2u)+1)/(exp(2u)-1) <= 20.80.
```

For every input with a finite decimal128 result, `u` is below approximately
14,150. An error in `L` is magnified by this factor before exponentiation. The
p51 logarithm arithmetic bound is below `1e-48` at this width, giving less than
`2e-44` absolute error in `u` over the finite output range. Even after the
subtraction condition and closing operations, at least eight decimal guard
digits remain.

P39 has no corresponding global margin because the factor 14,150 consumes more
than four of its five nominal guard digits. A deliberate p39 selection gives

```text
x = 29000.12345678901234567890123456789

p39 result = 2.079137397847174997931099442900046e6060
reference  = 2.079137397847174997931099442900047e6060.
```

The p51 result agrees with the independently evaluated decimal128 reference.
The test scales the one-ulp difference to one.

## Negative real inputs

The continuation has zeros other than zero on the negative real axis. Near
one of them, the two Binet terms are comparable and their subtraction has no
finite relative condition bound. The input

```text
x = -1.570776468203954722263371109084745
```

is the nearest decimal128 value on one side of a root independently located at

```text
-1.5707764682039547222633711090847454864456773730701...
```

and

```text
F(x) = 1.5178571604177142529999836936252107881...e-33.
```

A p51 substitution leaves a scaled error of
`-7.26719026220250690960685938e30` after multiplication by `1e70`. P75 agrees
through digit 34 and is the narrowest established context that does so.

No fixed context can promise an arbitrary relative error at a zero. P75 instead
gives a small absolute error relative to the magnitudes of the two terms and
about 40 work digits beyond a typical decimal128 displacement from a zero.
Exact phase zeros receive the symbolic treatment in the next section.

## Complex cancellation

Each complex component is a subtraction. Its componentwise relative condition
is unbounded where that component is zero, even when the complex norm is far
from zero. For

```text
z = -0.5664481561808904398554053145161438 + 0.7 i,
```

independent 180-digit arithmetic gives

```text
Re(F(z)) = -5.2663347834419609369670346530062117380...e-35,
Im(F(z)) = -2.4859874358643953383967904199893943872...
```

The former p39 route returns a real component beginning
`-5.262899...e-35`. A p51 substitution still leaves a scaled error of
`-1.78763244375914522921925210119e31` after multiplication by `1e70`. P75
agrees through digit 34. As on the negative real route, the meaningful global
claim at an exact component zero is an absolute error bound; arbitrary relative
accuracy is impossible there.

## Phase reduction and exponent range

The former real route formed `pi*x` at p39 before trigonometric reduction. A
large decimal128 `x` can therefore lose its exact integer or half-integer phase
before the high-precision radian reducer receives it. The complex route had the
same defect in its real phase.

The revised real route sends `x` directly to the trigonometric helper in
multiple-of-pi mode. The complex route reduces its real component in that mode
and forms only `pi*Im(z)` for the hyperbolic factor. It uses `const75_pi` at
p75. Modulo two is exact for a decimal128 coefficient at these work widths.

For example,

```text
x = -999999999999999999999999999999999.5
```

has `cos(pi*x)=0`. The first exponential underflows to zero and the correct
Real34 result is zero. The former route rounded the phase, multiplied an
infinite reciprocal by a nonzero cosine, and reported overflow. The revised
product helper recognises an exact trigonometric zero before multiplication, so
the infinite factor cannot turn it into NaN or infinity.

The p39, p51, and p75 contexts all use exponent limits of plus or minus 999,999.
Products needed for a finite decimal128 result fit inside those limits. The
existing explicit exponential input limit maps larger magnitudes into the
corresponding zero or infinity region.

## Special values and matrices

Real positive infinity now returns positive infinity: `exp(u)` dominates,
while the zero `exp(-u)` factor suppresses the undefined cosine. Real negative
infinity has no limiting value and returns NaN. NaN maps to NaN. Both input zero
signs retain the existing positive-zero result.

A complex input with an exact zero imaginary component uses the conditional
real context and returns a zero imaginary component. A nonzero complex input
uses p75. A special nonzero imaginary component produces NaN components through
the exponential and hyperbolic dependencies.

`processIntRealComplexMonadicFunction` sends real matrices to `elementwiseRema`
and complex matrices to `elementwiseCxma`. Each element therefore uses the same
context selection and formula as a scalar input; there is no matrix arithmetic
inside Fibonacci.

## Regression evidence

The focused file contains 56 checks. With the former implementation, 42
succeeded and 14 failed. The failures include all seven modes near zero, the
negative real root, the exact large half-integer phase, positive infinity, both
matrix types, the complex component root, and the small quadratic complex
component. The revised implementation succeeds in all 56.

The complete integrated suite contains 15,270 checks; all 15,270 succeed with
the revised implementation.

Three context substitutions distinguish the selected widths:

* p34 in the stable real region succeeds in 49 of 56 checks and fails all seven
  output modes for `F(1e-35)`;
* p39 on the positive real region succeeds in 55 of 56 and misses the large
  finite result by one ulp;
* p51 on either cancellation-capable p75 route fails its independently derived
  near-root check.

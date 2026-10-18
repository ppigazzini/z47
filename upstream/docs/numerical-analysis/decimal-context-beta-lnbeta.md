# Beta and log-Beta decimal contexts

## Scope and result

This audit covers the public Beta and log-Beta keys, their real and complex
callbacks, the `LnBeta` helper used by probability distributions, and elementwise
real and complex matrix evaluation. Short and long integer arithmetic is outside
the scope. Gamma, log-Gamma, logarithm, log1p, exponential, complex arithmetic,
and angle reduction are treated as audited dependencies.

The former real Beta route used three Gamma values at p39. The complex route used
the same quotient at p75. Both can overflow or underflow before a finite quotient
is formed. Log-Beta used three p39 log-Gamma values and formed `x+y` directly, so
it can lose the smaller argument and all of the gamma-ratio contribution.

The revised positive-real-half-plane calculation evaluates log-Beta as one p75
Lanczos expression. Beta then uses one p75 exponential. General complex log-Beta
outside that half-plane uses p75 complex log-Gamma values while preserving the
previous winding convention. The final conversion to decimal128 applies the
selected calculator rounding mode.

| Route | Context | Reason |
| --- | --- | --- |
| Positive finite real log-Beta | 75 | Lanczos coefficient cancellation and a possible small final result |
| Positive-real-half-plane complex log-Beta | 75 | The same coefficient issue in both components, plus complex products and quotients |
| Positive integer argument up to 205 | 75 | A short recurrence avoids Lanczos approximation cancellation near `Beta(x,y)=1` |
| General finite complex log-Beta | 75 | Three p75 complex log-Gamma results are combined; p39 only selects the winding integer |
| Real or complex Beta | 75 log-Beta, then 75 exponential | Avoids intermediate Gamma range failure |
| Real and complex matrices | Same scalar callbacks | Each decimal128 element follows the matching scalar route |

Differences confined to the accepted p39-to-p34 conversion boundary are outside
this analysis.

## Rearranged Lanczos expression

The audited Gamma calculation writes, with `h = g - 1/2`,

```text
L(x) = log(A(x)) + (x - 1/2) log(x + h) - (x + h)
A(x) = c0 + sum(c[k] / (x + k), k = 0..28)
```

Let `a` be the argument with smaller magnitude and let `b` be the other argument.
For positive reals this is simply `a <= b`. With `s = a+b`, direct substitution
and `log(b+h+a) = log(b+h) + log1p(a/(b+h))` give

```text
log B(a,b) = log(A(a)) + log(A(b)/A(s))
             + (a - 1/2) log(a+h)
             - a log(b+h)
             - (s - 1/2) log1p(a/(b+h)) - h.
```

No subtraction between `log Gamma(b)` and `log Gamma(a+b)` remains. The Lanczos
quotient is also formed without subtracting its two nearly equal sums:

```text
A(b) - A(a+b)
  = sum(c[k] * a / ((b+k) * (a+b+k)), k = 0..28),
log(A(b)/A(a+b))
  = log1p((A(b)-A(a+b)) / A(a+b)).
```

These identities remain valid when p75 addition rounds `a+b` to `b`; the
numerator still contains `a`. The complex route uses the same identities with
complex division, multiplication, logarithm, and log1p. The right half-plane is
free of Gamma poles. A p39 evaluation of the previous expression is used only to
choose the integer multiple of `2*pi` required by the existing continuous
log-Gamma convention.

## Precision bound and p51 rejection

At p75 the unit roundoff is `u = 5e-75`. Each Lanczos quotient-difference term has
three rounded arithmetic operations, and the 29-term accumulation has a usual
first-order factor below `100u` before coefficient cancellation. The coefficient
magnitudes sum to about `3.02e17`. A dense positive-real scan, supplemented by
the limits at zero and infinity, found a largest Lanczos-sum cancellation factor
below `9.5e13`. This leaves roughly 58 useful digits in an individual real sum at
p75. Complex conditioning depends on both components; the retained 24 digits
over p51 provide the same guard margin used by the audited complex Gamma kernel.

p51 is too narrow when the final log-Beta value is small. For

```text
x = y = 1.000000000000000000000000000000001
```

the 1024-bit MPFR value is

```text
-1.999999999999999999999999999999999644934...e-33.
```

The p51 candidate differs from the decimal128 result by `2.05e-47`, so only about
14 significant digits of this small result remain. The p75 calculation rounds to
`-2.000000000000000000000000000000000e-33`. A p39 candidate also changes the
ordinary value `log B(15,50)` in its 30th digit. Therefore p39 and p51 are both
unsuitable, and p75 is the narrowest established project context.

For a positive integral argument `n <= 205`, the calculation instead uses

```text
log B(n,z) = log Gamma(n) - n log(z)
             - sum(log1p(k/z), k = 1..n-1).
```

This form uses at most 204 terms and preserves small results near `B(n,z)=1`.
For the decimal128 number adjacent to the positive root of `B(2,z)=1`, the result
is `3.962381590835922936132875797982839e-35` and agrees through digit 34.

As with every finite-precision log-Beta implementation, inputs arbitrarily close
to the nonintegral level curve `B(x,y)=1` can make relative accuracy arbitrarily
ill-conditioned. The p75 margin and the integer recurrence cover the identified
decimal128 failures without introducing a wider project context.

## Range, branches, and special values

Computing Beta as `exp(logBeta)` removes the internal Gamma range failure. The
former implementation reported an out-of-range error for

```text
Beta(15.12345, 654321.1234).
```

The finite result is now

```text
1.346241433669422832130922754637401e-77.
```

The same change evaluates `Beta(0.75+0.5i, 1e100+2i)` without forming enormous
Gamma values. A 2048-bit Spouge calculation verifies both components through
digit 34.

For finite complex values outside the positive-real half-plane, reflection and
branch selection remain properties of complex log-Gamma. The p75 result is moved
by an integral multiple of `2*pi` to retain the earlier winding. A case adjacent
to `-41` checks both the p75 reflection accuracy and that winding.

The established Beta domain requires positive real parts. Signed real zero and
negative real arguments therefore retain their domain errors. NaN propagates to
the existing out-of-range result. With special results enabled, a positive real
infinity paired with another positive real has the limits `Beta = 0` and
`logBeta = -Infinity`; without that flag the prior error policy remains. Complex
nonfinite values with nonzero imaginary components have no unique limiting phase
and produce NaN. Purely real complex inputs use the same infinity limits when
special results are enabled.

## Rounding and verification

All work contexts retain half-even arithmetic. The decimal128 conversion is the
only operation using the selected result mode. File-driven cases verify all seven
modes with `logBeta(1,1e6144) = -6144*log(10)`. The discarded digits are nonzero,
so away-from-zero and floor differ from nearest, toward-zero, and ceiling in the
expected direction.

Independent references used 1024-bit MPFR for real values and a 2048-bit,
200-term Spouge calculation for complex values. Scaled subtraction cases expose
digit 34 for the real range failure, two small log-Beta results, a large complex
ratio, and a reflected complex value. Matrix cases cover real-matrix pairs and a
complex scalar paired with a complex matrix.

# Decimal context analysis for scalar dot product

## Scope

This analysis covers the scalar routes in `dot.c`: multiplication of two `real34_t` values and the real dot product of two `real34_t` complex values. Matrix dot
products contain length-dependent sums and remain a separate lower-priority task. ShortInteger mixed routes retain their existing 39-digit work context.

## Recommendation

Use `ctxtReal34` for two scalar real inputs. Their dot product is one multiplication, which is correctly rounded at the supplied context, so direct evaluation
applies the selected user mode once and needs no guard digits.

Keep `ctxtReal39` for two-component complex inputs. The existing compensated sum of two products has a relative error bound of `1E-38` at that width. A 34-digit
work context is too narrow for the bound and can lose exponent range before final conversion; 51 and 75 digits add no output-format benefit.

For NaN or infinite components, return the result of the initial multiply/FMA expression without evaluating the finite residual correction. This avoids a false
NaN from a correction such as `infinity - infinity` when the mathematical dot product is a signed infinity.

## Scalar real route

For two finite `real34_t` inputs, the exact coefficient of `x*y` has at most 68 digits. Correct rounding of multiplication at `ctxtReal34` gives the required final
value directly. Decimal128 underflow and overflow also occur at the output operation, so the selected mode returns zero or the minimum subnormal at the lower
boundary, and infinity or the maximum finite value at the upper boundary.

The implementation selects 34 digits only when both source registers have type `dtReal34`. Integer conversion can produce a wider working operand, so those mixed
routes cannot in general use a fixed decNumber context. When either real scalar is a LongInteger, the revised path multiplies exact integer coefficients and decimal
exponents, then converts the product to Real34 once. This avoids the former LongInteger-to-p75-to-Real34 double rounding. A single Real34 multiplication still uses
p34 and has no unpacking overhead.

## Complex finite route

For

```text
g = x_real * y_real + x_imag * y_imag,
```

the kernel evaluates

```text
q = RN_p(x_real * y_real)
t = RN_p(q + x_imag * y_imag)
e = RN_p(x_real * y_real - q) = x_real * y_real - q
r = RN_p(t + e).
```

Each expression containing a product and addition uses fused multiply-add. A product of two 34-digit inputs has at most 68 significant digits. At `p = 39`, the
residual after the rounded product has at most 29 significant digits, which proves that `e` is exact in the work context.

This is Kahan's compensated sum-of-two-products calculation. For an even radix, half-even work rounding and no work-context range loss, Jeannerod, Kornerup,
Louvet and Muller's [Error bounds on complex floating-point multiplication with an FMA](https://doi.org/10.1090/mcom/3123) gives

```text
|r - g| <= 2 u_p |g|,       u_p = 0.5 * 10^(1-p).
```

Thus at 39 digits,

```text
|r - g| <= 1E-38 |g|.
```

Cancellation between the two products does not weaken this bound. An exact zero is computed exactly. The work context's exponent limits of `+/-999999` also
contain every product and sum formed from decimal128 components before the result is converted back to decimal128.

The 39-digit result uses half-even work rounding, followed by conversion under the selected user mode. Its error is at most `2E-5` of the normal 34-digit unit
roundoff. The accepted 39-to-34 boundary differences are excluded as requested. Conversion near the decimal128 zero boundary has an absolute error at most
`0.5E-6176` for nearest modes and below `1E-6176` for directed modes.

## Why 34 digits are too narrow for the complex route

At 34 digits the compensated theorem permits relative error up to `2u_34 = 1E-33`, more than one half ulp at the output precision. The decimal128 exponent limits
can also underflow or overflow intermediate products that a wider work context can evaluate before final conversion.

The test inputs include the exact integer determinant

```text
9794374625685484555019278584798515 * 2158311863293504418674139665661578
- 6230319616471174524125468311303272 * 3280603533994713103317582709347623
= 700106396445937355923888811976254533744983978007127169067281634214.
```

The 39-digit compensated value has enough guard digits for the expected 34-digit results under all seven modes, apart from the excluded boundary intervals.

## Special values

The finite compensation computes `x_real*y_real - q` after `q` has already become infinity. That expression is NaN even when the initial expression has the
unambiguous value `infinity`. The revised branch returns the initial expression whenever any component is special. It preserves NaN for indeterminate forms such
as `infinity + (-infinity)`, while `dot(infinity + 0i, 1 + 0i)` now returns positive infinity and the negative case returns negative infinity.

## Tests

`dot.txt` checks the 68-digit finite result under all seven modes, cancellation to an exact one, direct real underflow and overflow, NaN propagation, and signed
infinities. Expected values are subtracted and scaled where needed to make a final-digit error visible to the file-driven test program.

Before the special-value repair, the focused file has 58 successes from 60 cases: both signed-infinity cases return NaN. The revised code succeeds in all 60 cases.

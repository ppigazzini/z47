# Decimal context analysis for complex multiplication

## Scope

This analysis covers `mulCplxCplx`, the `mulComplexComplex` dispatcher and its `mulComplexComplex75` kernel for two `real34_t` complex inputs. Scalar real
multiplication is a correctly rounded primitive and needs no change. Integer and matrix routes, the 159-digit solver kernel, complex division, square, cube and
magnitude need separate analyses. Callers which hand wider intermediate values to the public kernel must select a context for their own accuracy requirement.

## Recommendation

Keep `ctxtReal39` in `mulCplxCplx`. It is sufficient for a 34-digit result and is the narrowest suitable established context among 34, 39, 51 and 75 digits.
`ctxtReal34` permits an output error of one ulp in ordinary finite cases and its decimal128 exponent range can overflow before the result conversion. Widths of 51
and 75 digits reduce an already adequate error bound without changing the final format.

The special-value branch needs a separate repair when exactly one factor has an infinite component. The compensated correction otherwise evaluates an expression
such as `infinity - infinity` and returns a NaN. Normalising the infinite factor to components from `{-1, 0, 1}` determines the limiting direction without performing
arithmetic on infinity. Each non-zero direction component then becomes a signed infinity, while an exact zero stays zero.

## Finite compensated kernel

For either exact component, write

```text
g = xy + sv,       s is +1 or -1.
```

At a `p`-digit half-even context the kernel evaluates

```text
q = RN_p(xy)
t = RN_p(q + sv)
e = RN_p(xy - q) = xy - q
r = RN_p(t + e).
```

Both expressions containing a product use a fused multiply-add, so each has one rounding. For two 34-digit input components the exact product has at most 68
significant digits. At `p = 39`, its residual after a 39-digit product has at most 29 significant digits, which proves the equality in the expression for `e`.

This is Kahan's compensated sum-of-two-products algorithm. For an even radix, half-even rounding, and no work-context underflow or overflow, its sharp bound is

```text
|r - g| <= 2 u_p |g|,       u_p = 0.5 * 10^(1-p).
```

The bound is established for this algorithm in Jeannerod, Kornerup, Louvet and Muller's
[Error bounds on complex floating-point multiplication with an FMA](https://doi.org/10.1090/mcom/3123). Decimal radix 10 satisfies the even-radix condition.

For `p = 39`, `u_39 = 5E-39`, hence

```text
|r_real - R| <= 1E-38 |R|,
|r_imag - I| <= 1E-38 |I|,
|r_complex - Z| <= 1E-38 |Z|.
```

The first two are componentwise absolute bounds. Squaring and adding them gives the complex norm bound. Severe cancellation between the two products does not
introduce their much larger magnitudes into these bounds. When a component is exactly zero, the absolute bound forces the computed component to be exactly zero.
The ratio used for relative error is undefined at that exact zero, despite the exact result.

The work contexts have exponent limits of `+/-999999`. Products of decimal128 inputs and their sums fit well inside that range: an input component can be as small
as `1E-6176` and as large as `9.999999999999999999999999999999999E+6144`. The kernel therefore meets the theorem's range condition even when the later decimal128
conversion underflows or overflows.

## Final 34-digit rounding

The 39-digit contexts retain half-even rounding, while only `ctxtReal34` tracks the selected user mode. The conversion of each component therefore applies any of the
seven modes to the same compensated result. Since `u_34 = 5E-34`, the kernel's `1E-38` relative bound is `2E-5` of the normal 34-digit unit roundoff.

A 39-digit perturbation can change final rounding only when the exact component is correspondingly close to a 34-digit rounding boundary. Those accepted
39-to-34 boundary differences are excluded from this analysis. Outside those intervals, half-even, half-up, half-down, up, down, ceiling and floor return the
directly rounded 34-digit value.

An arbitrary relative guarantee is impossible after conversion near the decimal128 zero boundary. A non-zero exact component below `1E-6176` can round to zero,
which has relative error one, or to the minimum subnormal, whose relative error grows without a finite bound as the exact value approaches zero. Nearest modes have
an absolute conversion error at most `0.5E-6176`; directed modes have an absolute conversion error below `1E-6176`. An exact zero component remains exact.

## Why `ctxtReal34` is too narrow

With half-even arithmetic at 34 digits, the compensated theorem permits `2u_34 = 1E-33` relative error before storage. That is larger than one half ulp at the output
precision, so it cannot ensure the correctly rounded result. In the implementation, `ctxtReal34` also changes with the user mode, while the theorem requires nearest
rounding for the internal compensation.

An independently constructed four-component case demonstrates the loss. Integer arithmetic gives the exact values before rounding:

```text
a = 9794374625685484555019278584798515
b = 6230319616471174524125468311303272
c = 2158311863293504418674139665661578
d = 3280603533994713103317582709347623

R = ac - bd
  = 700106396445937355923888811976254533744983978007127169067281634214

I = ad + bc
  = 45578432750631918467133612914582806236603711717625188866299825263061
```

At 39 digits the real component is `7.00106396445937355923888811976254533745E+65`, which rounds half-even to
`7.001063964459373559238888119762545E+65`. Running the kernel directly at 34 digits instead returns
`7.001063964459373559238888119762546E+65`, one ulp high. Down and floor can make both components one ulp too low. The test subtracts the full expected complex value
and multiplies by `1E-32`, turning one real-component ulp into one, so the normal 30-digit comparison tolerance cannot conceal the error.

The 34-digit context also retains decimal128 exponent limits. Multiplying the maximum finite component by ten overflows inside the compensated correction and can
produce NaN before the public result conversion. The 39-digit context computes the finite wide intermediate and lets `ctxtReal34` apply the selected overflow result.

## Special values

The kernel applies these rules before finite compensation:

* any NaN component returns NaN in both result components;
* a zero complex factor multiplied by an infinite factor returns NaN in both components;
* two infinite factors use the existing eight-sector angle sum;
* one infinite factor is normalised to its axis or diagonal direction, multiplied by the finite factor, and expanded to signed infinities and exact zeros.

The last rule makes the route symmetric again. For example, both `(infinity + 0i)(1 + i)` and `(1 + i)(infinity + 0i)` return
`infinity + infinity*i`, while `(infinity + infinity*i)(1 - i)` returns `infinity + 0i`.

## Tests

`multiplication_complex.txt` checks the independently calculated result under all seven rounding modes, a determinant-like component equal to one after cancellation
of 68-digit products, an exact-zero component at the minimum input exponent, final underflow and overflow, NaN propagation, and the repaired one-infinite-factor
cases. Temporarily selecting `ctxtReal34` makes six of these tests fail, including one-ulp finite errors and a NaN from premature overflow. Disabling the infinity
normalisation makes all three new one-infinite-factor cases fail.

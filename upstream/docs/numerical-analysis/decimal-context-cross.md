# Decimal context analysis for cross products

## Scope

This analysis covers the scalar `crossCplx` determinant and the real and complex matrix-vector cross products. Each public result is a Real34 value or a three-element
Real34 matrix.

## Recommendation

Use the compensated sum of two products in `ctxtReal39` for the scalar determinant and each real matrix component. Use compensated four-product component sums in
`ctxtReal39` for an ordinary complex matrix component, with a `ctxtReal75` replay when cancellation removes more than twenty decimal places. The wider replay is also
selected when the p39 result is zero and the magnitude sum is nonzero.

A single p34 operation is cost-neutral. These kernels contain chained products, additions and residual corrections, so p34 gives no execution-time advantage and can
add Real34 unpack and repack work between operations. P39 is the minimum useful chained width. P51 cannot provide a 34-digit worst-case bound for the four-product
component; p75 is the narrowest project context that covers cancellation between full 68-digit product coefficients.

Inputs containing NaN or infinity use the established complex multiplication special-value route at p39. Residual correction is finite-only because a residual such
as `infinity - infinity` is NaN.

## Scalar and real matrix calculation

For

```text
g = y_real * x_imag - x_real * y_imag,
```

the compensated kernel evaluates

```text
q = RN_p(x_real * y_imag)
t = RN_p(y_real * x_imag - q)
e = RN_p(x_real * y_imag - q) = x_real * y_imag - q
r = RN_p(t - e).
```

The two expressions containing multiplication and addition use fused multiply-add. A product of two 34-digit inputs has at most 68 coefficient digits. After a p39
product, its residual has at most 29 coefficient digits and is exact at p39.

This is Kahan's compensated sum-of-two-products calculation. For an even radix, half-even work rounding and no work-context range loss, its component bound is

```text
|r - g| <= 2 u_p |g|,       u_p = 0.5 * 10^(1-p).
```

The bound is given for this calculation in Jeannerod, Kornerup, Louvet and Muller's
[Error bounds on complex floating-point multiplication with an FMA](https://doi.org/10.1090/mcom/3123). Decimal radix 10 meets the even-radix condition. At p39,
`u_39 = 5E-39`, hence

```text
|r - g| <= 1E-38 |g|.
```

Cancellation between the two products does not introduce their magnitudes into this bound. An exact zero is therefore returned as zero. The same kernel evaluates
each real matrix cross-product component.

## Complex matrix calculation

For two complex products, one output component is a signed sum of four real products:

```text
real = ac - bd - eg + fh
imag = ad + bc - eh - fg.
```

Each p39 product is split into its rounded value and its exact fused residual. Magnitude-ordered FastTwoSum steps accumulate those values in a main sum and a separate
correction. For four products, write `A` for the sum of their magnitudes and `S` for the exact component. A conservative compensated-summation bound has the form

```text
|result - S| <= u_p |S| + gamma_16^2 A,
gamma_16 = 16 u_p / (1 - 16 u_p).
```

When `A/|S| <= 1E20`, the p39 second-order term is below `6.5E-55 |S|`; the leading term is `5E-39 |S|`. The exponent comparison therefore keeps p39 for an
ordinary component and selects p75 before the second-order term can affect a 34-digit result.

Cancellation between 68-digit product coefficients can give `A/|S|` near `1E68`. At p51, the second-order bound can then approach `6.5E-31 |S|`, so p51 is not an
established 34-digit context. At p75 the corresponding term is below `6.5E-79 |S|`; products with a common decimal scale and their four-term sum are exact because
the result has at most 69 coefficient digits.

No fixed 75-digit context gives a relative guarantee for every possible exponent-separated cancellation down to the minimum Real34 subnormal. The selected replay
does provide exact common-scale coefficient cancellation and a much wider bound for the remaining cases. Results arbitrarily close to zero retain an absolute-error
qualification.

## Range and final conversion

The p39 and p75 contexts have exponent limits of `+/-999999`. Products of decimal128 inputs have adjusted exponents between roughly `-12352` and `+12289`, so the
working products remain within range. Final conversion to Real34 applies the selected user mode. Accepted p39-to-p34 boundary differences are outside this analysis.

Near the Real34 zero boundary, conversion has an absolute rather than relative guarantee: at most `0.5E-6176` for nearest modes and less than `1E-6176` for directed
modes. At the upper boundary, the final context selects infinity or the maximum finite number according to the user mode.

## Why narrower alternatives fail

At p34 the two-product bound is `2u_34 = 1E-33`, which is larger than one half ulp at the output precision. Its decimal128 exponent range can also underflow or overflow
a product before cancellation. Chaining p34 operations supplies neither an accuracy bound nor a speed benefit.

Changing only an uncompensated product from p75 to p39 is also insufficient. For

```text
y_real = 9999999999999999999999999999999998
y_imag = 9999999999999999999999999999999997
x_real = 9999999999999999999999999999999999
x_imag = 9999999999999999999999999999999998
```

integer arithmetic gives the determinant `1`. An uncompensated p39 product route returns `4`; the compensated p39 calculation returns the exact result.

## Tests

`cross.txt` checks a separately calculated scalar determinant in all seven user modes, exact scalar and matrix cancellation, final underflow and overflow, and NaN and
infinity behaviour. The expected scalar value is subtracted and scaled where a last-digit error would otherwise evade the test program's usual comparison threshold.

With the new matrix cases, the earlier matrix implementation succeeds in 57 of 59 checks: the real cross product loses an exact result of one, and the complex cross
product loses an exact imaginary result of two. The revised kernels succeed in all 60 checks. A Pell identity exercises the cancellation-triggered p75 complex replay
and returns an exact real component of one.

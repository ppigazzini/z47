# Decimal context analysis for complex square

## Scope

This analysis covers the public complex34 route in `squareCplx` and its finite helper `squareComplex`. Scalar real square already uses a correctly rounded
34-digit multiplication. Short integers, long integers, matrices, the 159-digit routes and other callers of complex multiplication need separate analyses.

## Recommendation

Keep `ctxtReal39` for complex square. It is sufficient for a 34-digit result and is the narrowest suitable established context among 34, 39, 51 and 75 digits.
The 34-digit context produces ordinary finite errors and can overflow during work on finite decimal128 inputs. Widths of 51 and 75 digits reduce an already
adequate error bound without changing the final format.

Use a square-specific finite kernel. The real component keeps the compensated difference of squares, while the imaginary component evaluates `2ab` through an
exact 39-digit doubling and one multiplication. This reduces the finite route from eight arithmetic operations in general complex multiplication to six. It also
reduces the imaginary component's work error from at most two 39-digit unit roundoffs to one. NaN and infinity inputs continue through `mulComplexComplex`, which
defines the public special-value directions.

## Finite real component

For `z = a + bi`, the exact real component is

```text
R = a^2 - b^2.
```

At a `p`-digit half-even context the helper evaluates

```text
q = RN_p(a^2)
t = RN_p(q - b^2)
e = FMA(a, a, -q) = a^2 - q
r = RN_p(t + e).
```

The fused multiply-add computes each product expression with one rounding. A square of a 34-digit input has at most 68 significant digits. At `p = 39`, the
residual after rounding `a^2` has at most 29 significant digits, so `e` is exact.

This is the compensated sum-of-two-products algorithm analysed by Jeannerod, Kornerup, Louvet and Muller in
[Error bounds on complex floating-point multiplication with an FMA](https://doi.org/10.1090/mcom/3123). For even radix, half-even rounding and no work-context
range loss, its sharp componentwise bound is

```text
|r - R| <= 2 u_p |R|,       u_p = 0.5 * 10^(1-p).
```

Decimal radix 10 meets the even-radix condition. At 39 digits this becomes

```text
|r - R| <= 1E-38 |R|.
```

The error is proportional to the cancelled result rather than to either square. Severe cancellation therefore does not amplify the two work errors. If `a = b`
or `a = -b`, the right side is zero and the computed real component is exact zero.

## Finite imaginary component

The exact imaginary component is `I = 2ab`. The helper evaluates

```text
d = RN_39(a + a) = 2a
j = RN_39(db) = RN_39(2ab).
```

Doubling a 34-digit decimal produces at most 35 significant digits, and the wide exponent range contains the doubled value. The first equality is therefore exact.
The multiplication is the only rounded operation in `j`, giving

```text
|j - I| <= u_39 |I| = 5E-39 |I|.
```

Combining the real and imaginary bounds gives the normwise result

```text
|computed(z^2) - z^2| <= 1E-38 |z^2|.
```

An exact zero is normalised to positive zero, matching the previous public complex-square result.

## Cancellation and exponent range

The 39-digit work contexts use exponent limits of `+/-999999`. Decimal128 components range from `1E-6176` to
`9.999999999999999999999999999999999E+6144`. Their squares reach adjusted exponents from `-12352` to `12289`, and `2ab` reaches at most `12290`. Every finite
intermediate therefore stays within the work range. The later decimal128 conversion may still underflow or overflow according to the selected user mode.

For example, consecutive 34-digit components

```text
a = 4999999999999999999999999999999999
b = 4999999999999999999999999999999998
```

give

```text
a^2 - b^2 = 9999999999999999999999999999999997,
2ab = 49999999999999999999999999999999970000000000000000000000000000000004.
```

The real component remains exact despite cancellation of two 68-digit squares. Equal components exercise an exact-zero real result. At the minimum input exponent,
`(1E-6176 + i*1E-6176)^2` has an exact imaginary component `2E-12352`; final nearest rounding produces zero, while round-away produces `1E-6176`.

## Final 34-digit rounding modes

The 39-digit contexts retain half-even rounding. Only `ctxtReal34` tracks the selected user mode, so conversion applies half-even, half-up, half-down, up, down,
ceiling or floor to both work components. Since `u_34 = 5E-34`, the real bound is `2E-5` of the normal 34-digit unit roundoff and the imaginary bound is `1E-5`.

A work perturbation can affect final rounding when the exact component is close to a 34-digit rounding boundary. Differences confined to those accepted
39-to-34 boundary intervals are outside this analysis. Away from them, the guard margin gives the directly rounded 34-digit result under every user mode.

No finite relative guarantee exists after conversion near decimal128 zero. A non-zero exact component below `1E-6176` can map to zero or the minimum subnormal.
Nearest modes have absolute conversion error at most `0.5E-6176`; directed modes have absolute conversion error below `1E-6176`. Exact-zero components stay exact.

## Why 34 digits are insufficient

The compensated real formula at 34 digits has the bound `2u_34 = 1E-33`, which is larger than one half ulp at the output precision. The bound also assumes nearest
internal arithmetic, while `ctxtReal34` changes with the user mode. For the specialised imaginary formula, `a + a` may require 35 digits, followed by another
rounding in the multiplication.

The five-operation factorisation

```text
R = (a - b)(a + b)
```

does not make 34 digits sufficient. Three correctly rounded operations give a relative bound of `(1 + u_34)^3 - 1`, approximately `3u_34`, when the result is
non-zero. An exact-zero sum or difference remains exact, so the formula is resistant to cancellation, but the finite non-zero error bound is wider than the
compensated formula. At 39 digits it would save one further operation while weakening the established real-component bound, so the six-operation kernel retains
compensation.

An independently constructed input demonstrates the 34-digit loss:

```text
a = 7866868866749651037551212805774434
b = -5748313405152136204588222861964362

R = 28844518762783191578450689092815486542218717458364599029165129953312
I = -90442455526622026819216681584232720476981802947031947143875837442216
```

The half-even 34-digit result is

```text
2.884451876278319157845068909281549E+67
  - i*9.044245552662202681921668158423272E+67.
```

Running the specialised kernel at `ctxtReal34` instead makes the imaginary component one ulp too negative under all three nearest modes. Other user modes produce
errors of up to five ulps, and every one of the seven mode cases fails its exact scaled-residual test. The factorised real formula at 34 digits also returns a real
component one ulp too high under half-even rounding.

The decimal128 exponent range is a separate obstruction. Squaring equal maximum finite components should produce an exact-zero real component and an overflowing
imaginary component. At `ctxtReal34`, the intermediate doubling overflows; the finite real calculation can also encounter infinity multiplied by zero and produce
NaN. The wide 39-digit context computes both finite work components before final conversion.

## Special values and tests

NaN and infinity inputs use the established `mulComplexComplex` rules. Any NaN component produces NaN in both result components. An infinite axis squares to the
corresponding real axis, and doubling an infinite diagonal's eight-sector angle produces the imaginary axis. The focused cases cover these directions with `SPCRES`
enabled.

`square.txt` also checks the independently calculated finite result under all seven modes with a scaled residual, severe cancellation, exact zero, the minimum and
maximum decimal128 exponents, final underflow and overflow, and all relevant special-value directions. A temporary `ctxtReal34` selection fails eight of the 57
focused cases: all seven finite mode cases and the equal-maximum overflow case.

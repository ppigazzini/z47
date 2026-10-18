# Decimal context analysis for hyperbolic tangent

## Scope

This analysis covers `WP34S_Tanh`, the public scalar, complex, and matrix paths, and the uses of `TanhComplex` in the elliptic functions. It relies on the separate `WP34S_ExpM1`, sine/cosine, and tangent analyses.

The accepted 39-to-34-digit boundary effect is outside this analysis.

## Recommendations

Retain 39 digits for public scalar and complex results. This is the narrowest established existing context above the final 34-digit format. Preserve any wider context supplied to `WP34S_Tanh` or `TanhComplex`; the former complex code instead forced all of its operations to 39 digits.

A single p34 operation has no extra cost. The real and complex formulas contain chained arithmetic and can add unpack and repack work at p34. More importantly, the directed-mode experiments and bounds exclude p34 on accuracy grounds. P39 is the minimum useful direct working width.

## Stable real formula

For `y=|x|`, set

```text
t = exp(-2y)
m = 1 - t = -expm1(-2y).
```

Then

```text
tanh(x) = sign(x) m / (2-m).
```

The revised helper evaluates this formula. Its exponential argument is never positive, so a finite or infinite input cannot create a positive exponential overflow. `expm1` supplies `m` without subtracting nearby working values when `x` is small. Since `0 <= m <= 1`, the denominator `2-m=1+t` lies in `[1,2]` and its subtraction is well-conditioned.

The previous helper used `(exp(2x)-1)/(exp(2x)+1)` and a fixed `|x|>47` shortcut. The shortcut was suitable for a half-even 39-digit result but erased digits requested by 51- or 75-digit callers. The new expression adapts to the supplied context and reaches its limiting value only when the negative exponential becomes insignificant at that context.

Outside `WP34S_ExpM1`, the helper performs three rounded elementary operations: doubling, subtracting from two, and division. For directed rounding at 39 digits,

```text
gamma_3 = 3E-38 / (1-3E-38) < 3.01E-38.
```

The map `m -> m/(2-m)` has relative condition `2/(2-m)`, which lies in `[1,2]`. The complete scalar bound is therefore at most twice the `expm1` relative bound plus this fixed arithmetic contribution and second-order products. The `expm1` audit establishes the needed guard margin at 39 digits. At 34 digits the fixed operations and helper error have no complete decimal128 margin; a deliberate 34-digit public mutation fails four of the new rounding-mode checks.

The sign is saved before evaluation, so source/result aliasing remains safe. Signed zero and signed infinity follow directly from the same formula.

## Stable complex formula

The identity

```text
tanh(z) = -i tan(iz)
```

maps `z=a+ib` to a tangent input `-b+ia`. The revised `TanhComplex` uses the audited stable tangent kernel and then exchanges and signs its two outputs. Those final copy and sign operations are exact.

Equivalently, with `t=exp(-2|a|)` and `m=1-t`, the components are

```text
D  = m^2 + 4t cos(b)^2
Re = sign(a) m(1+t) / D
Im = 4t sin(b) cos(b) / D.
```

The denominator is a sum of nonnegative terms. This avoids forming `tanh(a)` before the imaginary component is known. In the former quotient, rounding `tanh(a)` to one could erase the factor `1-tanh(a)^2` even while the final imaginary component remained representable.

For example,

```text
tanh(47+i) = 1.000... + 2.729321264492904590777293425576722...E-41 i.
```

The former path returns an exact zero imaginary component. The new path retains the decimal128 value.

The complex error bounds are those of `TanComplex`: 13 p39 elementary operations contribute less than `1.31E-37`, in addition to the audited trigonometric and exponential helpers and `WP34S_ExpM1`. No cancellation is introduced by the final exchange. No uniform componentwise-relative bound exists at a mathematical component zero; an absolute error statement applies there.

A deliberate p34 complex mutation fails three of the seven exact ordinary-complex rounding checks. The p39 route succeeds in every mode, so 39 digits is retained.

## Special values and range

Classification and assignment implement the complex cases whose result has a known limiting component:

```text
input                 result
NaN + i(+/-0)         NaN + i(+/-0)
+Inf + i(NaN/Inf)     +1 + i0
-Inf + i(NaN/Inf)     -1 + i0
```

These operations need no decimal context and introduce no rounding error. Finite real inputs with an infinite or NaN imaginary component continue through the tangent special-value route and return NaN components. The real and complex matrix routes invoke the same element functions as the scalar routes.

The negative exponential makes `tanh(+/-Infinity)` equal to `+/-1` without a separate magnitude cutoff. A NaN propagates. For complex values, finite imaginary parts beside an infinite real part give the corresponding signed unit real limit and zero imaginary component.

The wide argument reducer used by `TanComplex` covers the complete decimal128 imaginary exponent range on builds with sufficient memory. The DM42 reduction limit remains the one documented in the sine/cosine analysis.

## Tests

The new cases are in the existing `tanh.txt` file-driven suite. They check all seven scalar output modes through digit 34, all seven output modes for an ordinary complex value, and the representable imaginary component at `47+i`.

With these cases present, the former complex implementation succeeds in 290 of 291 affected checks and loses the `47+i` component. The revised implementation succeeds in all 291 checks, including the elliptic callers.

The bounded follow-up set combines `sinh.txt`, `cosh.txt`, and `tanh.txt`. Before the special-value repair it succeeds in 193 of 216 checks; all 216 succeed after the repair. The added matrix cases exercise both the real and complex element dispatch.

The clean complete file-driven suite succeeds in all 18,351 checks with zero GMP-owned bytes.

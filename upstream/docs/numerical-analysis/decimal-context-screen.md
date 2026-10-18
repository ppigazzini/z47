# Decimal contexts in ordinary screen preparation

## Scope

This audit covers decimal work in `screen.c` that prepares ordinary numeric text or decodes a numeric status value. Graph drawing, graph state, pixel addressing, and
native binary arithmetic are excluded. Coordinate conversion is covered by the separate coordinate audits.

The decimal routes are:

| Route | Input and operation | Context conclusion |
|---|---|---|
| Clipboard real and complex values | `real34Reduce`, sign copy, and conversion to text | Exact stored-value operations; no work context is needed. |
| Clipboard statistical sums | Direct `real_t` conversion to text | No arithmetic is performed. |
| Distribution parameter text | One `real_t` to Real34 conversion | The public Real34 boundary uses `ctxtReal34`; one p34 operation is cost-neutral. |
| Matrix index and solver/status labels | Integral tests and integer conversion | No decimal arithmetic is performed. Producer invariants limit the finite integral values. |
| Type label | Multiply the exact type code by 1000, then extract decimal fields | One exact p34 multiplication is sufficient. |
| Ordinary XFN preview | `X*Y+Z`, followed by a Real34 result | One fused p34 operation is the required calculation. |

The time and DMS text conversions are implemented in `display.c` and `conversionAngles.c`, and are covered by their own audits. Matrix and complex display formatting
delegates to the audited formatting and coordinate helpers.

## Type-code decoding

`fnGetType` creates the value decoded by `_displayRegType`. Its coefficient contains at most four significant digits after multiplication by 1000. The input is stored
as Real34, so multiplication by the decimal power 1000 is exact at p34 for every valid code. The integer conversions then recover the type, angular mode, coordinate
mode, and vector orientation without rounding. P39 supplied no extra information. The multiplication now uses `ctxtReal34`.

This is one operation, not a p34 chain. It therefore has neither the conversion concern of chained p34 arithmetic nor a reason for p39 guard digits.

## XFN preview

Let the values obtained from the three registers be `a`, `b`, and `c`. The displayed value requires

```
RN34(a*b + c)
```

in the selected public rounding mode. The former calculation first formed `RN39(a*b)` under the fixed p39 mode, then added `c` at p39 and converted the sum to
Real34. Guard digits do not protect a small residual when `c` nearly cancels the product. For example, all three operands below are exact Real34 values:

```
(1 + 1E-33) * (1 - 1E-33) - 1 = -1E-66
(1 + 1E-33) * (1 + 1E-33) - (1 + 2E-33) = 1E-66
```

The separately rounded p39 product is `1` in the first expression and `1 + 2E-33` in the second. The following addition therefore returns zero. This is not an
accepted p39-to-p34 boundary difference: the first rounding removes a nonzero term before the addition.

`realFMA` evaluates the product and addition without rounding between them. With `ctxtReal34`, its one rounding is the public result rounding. Thus p34 is the
narrowest sufficient context for every finite input and each of the seven modes. P39, p51, and p75 cannot improve the correctly rounded Real34 result. A single p34
operation is cost-neutral, while the prior two-operation chain did more arithmetic.

The fused operation applies its context range to the final exact sum. A finite result outside Real34 range therefore overflows at the public boundary, and a tiny
result underflows there according to the selected mode. NaN, infinity, invalid multiplication such as infinity times zero, and signed zero use the decimal fused
operation rules. An invalid register type still makes `registerFMA` return false before arithmetic.

## Verification

The existing `xfn.txt` file now invokes the ordinary screen helper directly. Before the source change, the two exact cancellation cases returned zero, giving 33
successful cases out of 35. With the fused calculation, both return their exact `1E-66` residuals. Seven further cases use an independently expanded 68-digit product
and assert digit 34 under every public rounding mode. Infinity times zero and an exponent-range case exercise special and wide-intermediate behaviour.

Overflow at the largest Real34 finite value and underflow at the smallest Real34 quantum verify the selected p34 mode at both exponent boundaries.

No graph, plotting, coordinate, or native binary arithmetic was changed.

# Decimal context analysis for real square root

## Scope

This analysis covers the two `sqrtReal` routes which apply one square-root operation to a real magnitude:

* a non-negative real result;
* the positive imaginary component produced for a negative real when `CPXRES` is set.

The general complex kernel `sqrtCplx`, short integers and matrix functions need separate analyses. Non-square LongInteger inputs now use the exact route described
below rather than first being shortened to a decNumber value.

## Recommendation

Keep `ctxtReal39` for both operations in `sqrtReal`. It is the narrowest suitable global context. The five extra digits reduce the interval in which the final
34-digit rounding can lose the side of a rounding boundary. The next narrower global choice, `ctxtReal34`, also loses the selected directed-rounding behaviour.

The negative-real `CPXRES` route uses the square root of the positive magnitude and writes that result as the imaginary component. It has the same error bound and
needs the same context.

## Primitive behaviour

The bundled `decNumberSquareRoot` implementation sets the final internal rounding mode to half-even. Its source states that the supplied context rounding field has no
effect. `sqrtReal` therefore computes a 39-digit half-even value and `convertRealToResultRegister` or `convertComplexToResultRegister` rounds it to 34 digits in the
selected mode.

Let `y` be the exact root, let `h` be one unit in the last place at 34 digits in the decade containing `y`, and let `p` be the square-root context width. Away from an
exponent transition, the primitive returns `z` with

```text
|z - y| <= 0.5 * 10^(34-p) * h.
```

The same bound applies at a power-of-ten transition when expressed using the finer of the two adjacent spacings.

| Context | Maximum first-round error in 34-digit ulps |
| ---: | ---: |
| 34 | `5E-1` |
| 35 | `5E-2` |
| 36 | `5E-3` |
| 37 | `5E-4` |
| 38 | `5E-5` |
| 39 | `5E-6` |

For half-even, half-up and half-down, the final result can differ from direct 34-digit rounding only when `y` is within this bound of a 34-digit midpoint and `z` lands
on that midpoint. For up and ceiling on a positive magnitude, an error can occur only when `y` is above a 34-digit value but `z` lands on it. For down and floor, the
corresponding interval is immediately below a 34-digit value. Reducing the working width from 39 to 38 increases each uncertain interval by a factor of ten. Widths
from 34 to 37 increase it further.

A bare `ctxtReal34` call has a separate directed-rounding problem. The primitive returns the half-even neighbour, while up, ceiling, down and floor sometimes require
the other neighbour. The conversion cannot recover which side of the exact root produced the rounded value.

No finite guard width removes all two-round boundary cases. The requested treatment accepts the existing 39-to-34 boundary behaviour. Arbitrary widths from 35 to 38
digits enlarge its uncertain intervals but are not global contexts, and this analysis does not claim that 39 is the smallest arbitrary precision with an acceptable
forward-error margin. Among the established global choices of 34, 39, 51 and 75 digits, 39 is the narrowest suitable context.

## Exact alternative

An exact directed-rounding implementation can compute the root at 34 digits, square the candidate exactly, and move by one 34-digit value when the square comparison
shows that the candidate is on the wrong side. A 34-digit coefficient can square to 68 significant digits, so the comparison requires a 68-digit multiplication in
the worst case.

The nearest modes need no direction check for a finite non-zero `real34_t` input. Write a midpoint between adjacent 34-digit values as

```text
m = (2n + 1) 10^e / 2,
```

where `n` has 34 digits. Its square is

```text
m^2 = 25 (2n + 1)^2 10^(2e - 2).
```

The integer coefficient has at least 69 digits and no trailing decimal zero, so `m^2` is not a 34-digit input. An exact midpoint is therefore impossible. Half-even,
half-up and half-down select the same neighbour.

This alternative removes the accepted boundary differences but adds a 68-digit multiplication, comparison and possible next-value operation for every directed
result. It is not applied because the boundary differences are excluded from the requested change. It remains available if correctly rounded directed square root
becomes a separate requirement.

## LongInteger inputs

A fixed decNumber input conversion cannot cover an arbitrarily wide LongInteger. For example, the exact square roots of `10^80+1` and `10^80-1` lie immediately
above and below `10^40`; converting either integer to p75 first loses that distinction. The revised LongInteger route obtains the result-width root coefficient directly
with GMP.

For a positive integer with `d` decimal digits and target precision `p`, let `q=floor((d-1)/2)` and `S=p-1-q`. The lower result coefficient is

```text
c = floor(sqrt(N) * 10^S).
```

When `S` is non-negative, `c` is the integer square root of `N*10^(2S)`. When it is negative, it is the integer square root after division by `10^(-2S)`. The GMP
remainders record whether the result is exact. Directed rounding follows that exactness and the selected mode. For a nearest mode, the comparison

```text
4*N*10^(2*max(S,0))  ?  (2c+1)^2*10^(2*max(-S,0))
```

locates the exact root relative to the midpoint without floating-point arithmetic. The selected coefficient is then converted to Real34 exactly once. With `SDIGS`
active, `p` is that configured precision, so no 34-digit intermediate can create a second-rounding midpoint. Perfect integer squares keep the pre-existing
LongInteger result.

When `CPXRES` is set, a negative LongInteger uses the same exact calculation on
its magnitude and places the rounded value in the imaginary component. This
avoids converting a wide magnitude to p75 before the complex square-root path.

## Validation

The unchanged production route was built with `make simc47 t47`. The complete test suite reports 13,822 successful cases and zero failures for the baseline source.
The only linker diagnostic reduces the requested `__DATA,__common` alignment from `0x8000` to `0x4000`; it is unrelated to decimal arithmetic.

Independently constructed values within `5E-6` ulp of 34-digit midpoints and values confirm the predicted 39-to-34 boundary behaviour under all seven rounding modes.
Those cases are not retained as regressions because that behaviour is excluded from this change.

Signed zero is an exact identity case. The scalar real route copies either zero
sign directly before testing whether a nonzero operand needs a complex result.
This preserves `sqrt(-0) = -0` independently of the complex-result flag. The
focused tests verify the result type and use a reciprocal to distinguish the
zero sign.

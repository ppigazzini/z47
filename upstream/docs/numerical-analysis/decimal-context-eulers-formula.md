# Decimal context analysis for Euler's formula

## Scope and recommendation

This analysis covers the public real, complex, and matrix entry points for

```text
E(z) = exp(i z).
```

Use the selected p34 context for real inputs and for complex inputs on the exact real axis. These routes require only sine and cosine, whose audited helper performs its reduction and series work at wider internal widths before one direct p34 result operation. A single p34 operation is cost-neutral; no chained p34 arithmetic remains on these routes.

Retain p39 for a complex input with nonzero imaginary component. This is the narrowest established context among 34, 39, 51, and 75 digits for the exponential magnitude, trigonometric factors, and closing products. The accepted p39-to-p34 boundary effect is outside this analysis.

## Finite complex inputs

For `z=a+ib`, multiplication by `i` is an exact copy-and-sign operation:

```text
i z = -b + i a,
E(z) = exp(-b) cos(a) + i exp(-b) sin(a).
```

The scalar exponential has relative error at most one p39 ulp, or `1E-38`, before final conversion. The trigonometric helper reduces the phase at p12321 on builds with sufficient memory, retains the reduced angle at p75, evaluates its series at p51, and shortens each component to p39. Its series bound is below `1.6E-46` relative for a nonzero first-octant component. The p39 component conversion and closing product each contribute at most `u39=5E-39`.

Combining the exponential error, trigonometric conversion, and closing multiplication gives less than `2.01E-38` relative component error before second-order terms when the mathematical component is nonzero. Near a trigonometric zero, the sine/cosine analysis supplies the corresponding absolute phase bound. There is no addition or subtraction in either output component.

The p39 exponent range prevents premature work overflow. A deliberate p34 public mutation fails at

```text
z = -14149.38539644841072829055748903542 i
```

under rounding mode 4. The exact magnitude lies above the decimal128 finite range, but directed conversion requires the largest finite value. P34 overflows inside the exponential and returns infinity; p39 keeps the intermediate until the final conversion and returns `9.999999999999999999999999999999999E6144`.

P51 and p75 add no required margin because the audited exponential and trigonometric results already meet the Real34 target at p39.

## Real inputs and the exact real axis

For real `z=a`, Euler's formula reduces to

```text
E(a) = cos(a) + i sin(a).
```

Evaluating `exp(i*a)` would compute the exact magnitude `exp(0)=1` and then multiply both trigonometric factors by one. The revised helper detects an exact zero imaginary input and requests sine and cosine directly at the caller's width. The public real callback requests p34, as does a complex matrix element whose imaginary component is exactly zero.

The completed trigonometric analysis uses p12321 phase reduction on builds with sufficient memory, p75 for the reduced angle, and p51 for the series. The p51 relative arithmetic bound is below `1.6E-46` for a nonzero first-octant component. The closing unary operation then applies the selected p34 mode. Near a trigonometric zero, the phase-reduction analysis supplies an absolute bound. P34 is therefore the narrowest result context for this route, and p39 would add an intermediate conversion without improving the Real34 value under the accepted boundary policy.

Tagged real angles use the same p34 result context after reduction in their source unit. Real and complex matrices invoke the corresponding scalar callback for each element; matrix dispatch adds no arithmetic.

Long-integer scalar phases use the same exact radian reduction as the public
trigonometric functions. Converting the complete integer to p75 first is not
sufficient: integers which differ by one can coincide after that conversion.
Reduction precedes the p34 sine and cosine result operations, while the existing
1000-digit input bound remains in force.

## Tagged real angles

A real input with an angular tag represents the phase in degrees, gradians, DMS, or multiples of pi. The former route converted the complete value to radians at p39 before trigonometric reduction. Near a source-unit quadrant, subtraction of a multiple of pi then amplified the conversion error.

The revised route gives the original tagged value directly to `C47_WP34S_Cvt2RadSinCosTan`. That helper removes the quadrant in the exact source unit and converts only the small residual to radians. For

```text
179.9999999999999999999999999999999 degrees,
```

the mathematical imaginary component is

```text
1.7453292519943295769236907684886127...E-33.
```

The former conversion order differs by about `2.08E-39`, leaving only about six correct significant digits in this small component. Source-unit reduction produces the expected 34-digit value. Untagged reals and integer inputs retain their radian interpretation.

## Infinite components

With special results enabled, an infinite phase `a` remains undefined and returns two NaNs. An infinite imaginary component controls only the magnitude when the phase is finite:

```text
b = +Infinity  => exp(-b) = 0,
b = -Infinity  => exp(-b) = +Infinity.
```

These values now enter `expComplex`, which preserves the signs of zero or infinity selected by `cos(a)` and `sin(a)`. The former pre-check returned two NaNs for every infinite complex component. When special results are disabled, either infinite component continues to report the existing domain error.

NaNs retain the complex exponential behavior. Matrices use the same real or complex callback for each element.

## Tests

The new cases are in the existing `eulersFormula.txt` file-driven suite. They check both components through digit 34 in all seven output modes, direct exact-axis complex and matrix inputs in directed modes, source-unit cancellation near 180 degrees, finite phases beside both signs of infinite imaginary part, zero signs through reciprocals, and the directed upper-range result.

With the final fixtures, the revised implementation succeeds in all 69 focused
checks. A deliberate p34 general-complex mutation fails the directed range case
described above. The p34 real and exact-axis routes succeed in every associated
digit-34 check. The two wide-long cases differ by one radian and therefore
verify that the phase is reduced before decimal conversion.

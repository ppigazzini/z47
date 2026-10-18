# Decimal contexts for register value conversions

## Scope and selected contexts

This analysis covers the Real34, complex34, time, date, matrix-copy, snapshot, and generic arithmetic-dispatch routes in `registerValueConversions.c`. Short and long
integer arithmetic, coordinate conversion, representation helpers, state serialisation, and native graph arithmetic are outside this audit. Their established results
are used only where a route in this file depends on them.

| Route | Selected context | Reason |
| --- | --- | --- |
| wide real or complex component to a Real34 result, SD at least 34 | one p34 storage conversion | one rounding must apply the decimal128 coefficient and exponent limits together |
| wide real or complex component to a Real34 result, SD below 34 | one p34 integral rounding, then storage conversion | the requested coefficient reduction has at most 33 digits; the storage conversion then applies the Real34 range |
| time value to decimal hours, or decimal hours to time seconds | p34 | each route is one correctly rounded Real34 division or multiplication |
| supported date formatting and parsing | p34 | the components are bounded integers and every scale factor is a decimal power |
| Real34, complex34, time, or date getter | no arithmetic context | Real34 expansion to `real_t` is exact |
| real-matrix copy and real-to-complex-matrix promotion | no arithmetic context | components are copied exactly and promoted imaginary parts are positive zero |
| snapshots of the in-scope scalar types | no arithmetic context | payloads and tags are copied exactly |
| exact mixed division conversion | p34 final conversion | exact integer division supplies digit 35 and a sticky indicator before one Real34 rounding |
| scalar and matrix generic dispatch | no arithmetic context | the route is selected from stored data types; numerical work belongs to the selected callback |

A single p34 operation is cost-neutral relative to p39. Repeated p34 arithmetic may add unpacking and repacking work, so p34 is not selected here as a speed
optimisation for a dependent chain. It is selected for the Real34 storage boundary and for operations whose inputs and outputs are already Real34. P39, p51, and p75
provide no additional fidelity on those routes.

Differences caused only by shortening a p39 result to p34 before Real34 storage are outside this audit. The defect below is distinct: a redundant p75 rounding at the
public boundary changed a value before the exponent-limited Real34 rounding.

## Wide result to Real34

Let the minimum positive Real34 subnormal be

```text
q = 1e-6176
```

and take the exact p75 value

```text
x = 5.0000000000000000000000000000000000000001e-6177.
```

Thus `x > q/2`. A direct Real34 conversion in any nearest rounding mode returns `q`. The former route first rounded `x` to 34 significant coefficient digits in the
wide exponent range. That operation produced the exact midpoint `q/2`; a second Real34 half-even or half-down rounding then produced zero. Negative values had the
symmetric error, and each component of a complex result was affected independently.

The revised SD-at-least-34 route applies `realToReal34` directly. One operation therefore applies coefficient precision, exponent limits, subnormal precision, sign,
and the selected rounding mode. This covers all seven modes without an intermediate boundary. NaN and infinity propagate under the usual Real34 conversion, and signed
zero keeps its sign.

When the requested significant-digit setting is `d < 34`, the coefficient reduction is part of the public result semantics and remains before storage. The rounding
helper normalises a finite nonzero magnitude to `[0.1,1)` and moves its exponent by `d` before the integral operation. The integral operand consequently has at most
`d` significant digits in the result, independent of the source exponent. P34 is sufficient for every supported `d` from 1 through 33. Restoring the saved decimal
exponent is exact, after which `realToReal34` applies the storage range. Wider contexts cannot improve this result.

## Exact mixed division conversion

Finite integer and Real34 operands can be represented as signed integer
coefficients with decimal exponents. The division converter scales their
magnitudes so integer division yields 35 significant quotient digits. A
nonzero integer remainder appends one nonzero sticky digit; an exact quotient
does not. These data distinguish every nearest tie and every directed-rounding
boundary needed for a 34-digit result. The existing scaled-integer conversion
then applies the selected rounding mode once. Intermediate integer arithmetic
is unbounded because it does not represent a user-visible long integer.

Signed zero is handled before integer division because an integer coefficient
does not encode its sign when it is zero. Special values and a zero denominator
are returned to the operation-specific paths.

The quotient core also accepts scaled coefficients directly. This lets a
long-integer reciprocal use an exact numerator of one without allocating a
temporary calculator register. The register-to-register wrapper and the
reciprocal wrapper therefore share the same 35-digit quotient and sticky-bit
path.

## Time and date routes

Time storage uses seconds in a Real34 payload. Conversion to a plain real divides once by 3600; conversion from a plain real multiplies once by 3600. Each operation is
correctly rounded at the public Real34 boundary. A local copy is made before destination allocation, so source and destination may name the same register. The ordinary
decimal special-value and signed-zero rules apply mechanically.

For a supported date, decomposition produces integral year, month, and day components. Formatting divides or multiplies those components by powers of ten and adds the
non-overlapping decimal fields. Parsing reverses the decimal shifts, uses directed integral extraction, validates the fields, and invokes the previously audited Julian
date helpers. The supported fields fit well inside 34 coefficient digits, so p34 loses no information. A wider dependent chain would add no accuracy.

## Getters, copies, aliases, and dispatch

Expanding a Real34 component into `real_t` is exact. The complex getters add an exact positive-zero imaginary component to non-complex inputs. Their `cmplx` parameter is
an accumulator: a complex input sets it to true and a later real input does not clear it. This supports dyadic promotion without inspecting whether an imaginary
component happens to be zero. The `AnyReal` variants admit tagged time and date payloads, while the ordinary real variants reject them by design. A complex value with a
zero imaginary component is accepted by real getters without changing its real component.

The in-scope snapshot paths copy Real34 payloads and tags directly. Matrix-copy paths copy every decimal128 component byte for byte. Real-to-complex matrix promotion
copies each real component and writes exact positive zero to its imaginary component. Allocation precedes an aliased register replacement, so successful in-place
promotion does not overwrite the source before the copy.

The monadic and dyadic generic dispatchers choose scalar or matrix callbacks from the stored type. Real operands use the real callback; a complex scalar or complex
matrix requires the complex callback; mixed real and complex matrix routes promote through the complex callback. Time and date are intentionally absent from these
arithmetic dispatchers. No decimal rounding occurs in dispatch itself.

## Verification

The added cases are written in the existing `round_cov.txt` file and obtain exact p75 inputs through a small test-suite coverage function. The expected minimum-subnormal
results follow directly from comparison with `q/2`, not from program output. They cover both signs, every selectable rounding mode, a value below the midpoint, independent
complex components, infinity, signed zero, and an SD-below-34 result.

With the redundant 34-digit p75 rounding restored, five focused cases fail: the positive and negative values above `q/2` become signed zero in half-even and half-down,
and the complex half-even result becomes zero in both components. With the revised single storage conversion, all focused cases succeed.

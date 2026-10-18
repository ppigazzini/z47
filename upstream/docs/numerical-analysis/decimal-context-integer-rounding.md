# Decimal context analysis for integral and display rounding

This analysis covers the Real34 and Complex34 routes of `IP`, `CEIL`,
`FLOOR`, `ROUNDI`, `ROUND`, `SDL`, and `SDR`. It includes the matrix routes
supported by these functions. Short and long integer inputs are outside the
analysis.

Differences caused only by shortening a p39 result to p34 and then to Real34
are outside this audit.

## Selected arithmetic

| Route | Selected context | Reason |
| --- | --- | --- |
| `IP`, `CEIL`, and `FLOOR` | p34 | One integral operation directly defines a Real34 result |
| `ROUNDI` scalar real | p34, then exact integer arithmetic | Half-up rounding starts from a Real34 value; GMP represents the integral result exactly |
| `ROUNDI` real matrix | p34 | The public matrix result remains on the Real34 lattice |
| `ROUND` ordinary real or rectangular complex | p34 conversion | Parsing the selected display text directly defines the public result |
| `ROUND` displayed fraction | p39 | Division and recombination form a chained calculation |
| `ROUND` polar complex | p39 | Polar-to-rectangular conversion needs guard digits before the Real34 result |
| `ROUND` time and date | p39 | Scaling, integral selection, and reconstruction form chained calculations |
| `SDL` and `SDR` finite real | no intermediate arithmetic context | The decimal exponent edit is exact; the Real34 conversion applies range and mode |

These choices separate representation semantics from execution cost. A single
p34 wrapper operation is cost-neutral relative to p39 and is suitable when it
directly selects a Real34 result. P34 arithmetic has no general speed advantage
over p39. When several p34 wrapper operations are chained, intermediate
packing and unpacking can cost more than a p39 calculation with one final
Real34 conversion. The chained `ROUND` routes therefore use p39, while the
direct integral operations retain p34 for public-result semantics.

## `IP`, `CEIL`, and `FLOOR`

Each function applies one explicit integral mode to a Real34 input: toward
zero, toward positive infinity, or toward negative infinity. Removing a
fractional suffix cannot create more coefficient digits than the input. The
finite result is therefore exact in 34 digits.

A context below 34 digits could alter an already integral 34-digit value, so
p34 is minimal. P39 would produce the same finite mathematical result, but it
offers no accuracy benefit for this one-operation route. The p34 selection is
not a speed claim.

Real and complex matrices apply the same component operation. With special
results disabled, a NaN or infinity reports a domain error and leaves the
source component unchanged. With special results enabled, a special component
is unchanged while finite components receive the selected integral operation.
Time, date, string, and configuration inputs remain type errors. Short and
long integers remain unchanged.

## `ROUNDI`

Scalar `ROUNDI` first applies half-up integral rounding to its Real34 input.
The resulting decimal integer is then represented exactly by GMP. The
3328-bit size limit must be tested on that exact rounded integer.

The former test estimated the decimal limit from the stored exponent with a
binary floating constant. An exponent does not determine the integer bit
length because the coefficient also contributes. For example, `6e1001` needs
3328 bits and is valid, while `9e1001` needs 3329 bits and must report positive
overflow. The former code accepted both. For an exponent above its estimate,
it also reported overflow and then continued, replacing X with the oversized
integer. The revised route computes the integer once, checks its exact bit
length, and changes X only after the check succeeds.

A real matrix cannot contain long-integer elements. Its public result is a
Real34 matrix, so each finite element now receives one p34 half-up integral
operation in place. This removes the unrelated 3328-bit scalar limit and the
conversion from long integer through p75 back to Real34. A maximum finite
Real34 matrix element consequently remains valid. Matrix special values are
rejected before any element changes, and complex matrices remain type errors.

NaN and infinity remain domain errors for scalar `ROUNDI`, independent of the
special-result flag. Signed finite values select positive or negative overflow
from the sign of the Real34 input.

## `ROUND`

For an ordinary real or rectangular complex value, the chosen display text is
the definition of the result. Direct Real34 parsing is the required public
boundary and introduces no hidden arithmetic chain.

Fraction display reconstructs

```
integer_part + numerator / denominator.
```

The numerator and denominator are exact integers and the displayed fraction
uses a bounded denominator. P39 keeps five guard digits beyond the Real34
input width across the division and addition, followed by one Real34
conversion. The old p34 divide-plus-add sequence offered no performance
advantage and could round twice inside the chain.

Polar complex display already parses magnitude and angle at p39, performs the
polar-to-rectangular conversion at p39, and converts each component once to
Real34. This width remains appropriate because trigonometric conversion is
not exact and the final components need guard digits.

Time display values with one or two time digits use

```
60 * trunc(x / 60).
```

Other nonzero time-display settings use an exact power-of-ten exponent edit,
the selected integral mode, and the inverse exponent edit. A non-boundary
Real34 value has at least one Real34 lattice interval of separation from an
exact minute boundary. After division by 60, that separation is thousands of
p39 intervals, so five guard digits are sufficient for the integral
classification. The exponent edits are exact. The result is converted to
Real34 once.

Date rounding computes

```
43200 + 86400 * round_mode((x - 43200) / 86400).
```

The constants are exact integers. P39 supplies five guard digits for the
subtraction, division, integral selection, multiplication, and addition. It is
the minimum useful intermediate width under the project performance rule.

NaN and infinity now receive the established special-result policy before any
display parsing or arithmetic. With special results enabled, the input is
unchanged. Otherwise NaN reports a domain error and infinity reports signed
overflow. Real and complex matrices check for a disallowed special component
before element evaluation, which prevents a partial matrix result on error.

## Decimal shifts

`SDL` and `SDR` add or subtract a parameter in `[0,99]` from the unpacked
decimal exponent. This edit is exact and cannot overflow the signed exponent
field. No arithmetic context participates. The final Real34 conversion
applies the selected rounding mode and decimal128 exponent range.

NaN and infinity propagate when special results are enabled. Complex values
and both matrix types remain type errors. The representation-helper analysis
contains the corresponding exponent-limit cases.

## Verification cases

The added cases use the existing `roundB.txt`, `round_cov.txt`,
`roundiB.txt`, `integerPart.txt`, `ceil.txt`, and `floor.txt` files. They cover
the exact 3328-bit `ROUNDI` boundary, signed overflow without type mutation, a
maximum finite Real34 matrix element, matrix special-value atomicity, complex
matrix integral rounding, display-time and date dispatch, and scalar or matrix
special values for `ROUND`.

With the original `ROUNDI` source, the maximum-range matrix case terminates the
file-driven executable with status 134. The old capacity test also accepts
`9e1001`, and its overflow branch still converts X. The original `ROUND`
source returns success for disallowed scalar specials and evaluates finite
matrix elements before discovering a disallowed special component.

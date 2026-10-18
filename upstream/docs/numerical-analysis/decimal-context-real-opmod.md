# Decimal context analysis for Real34 modular operations

## Scope

This analysis covers every `MULMOD` route with at least one Real34 operand and
a Real34 result. It also covers Real34 rejection by `EXPMOD`, the scalar and
matrix dispatch rules, finite-domain checks, decimal exponent limits, and the
final Real34 conversion. Short- and long-integer results are outside scope.

Differences caused only by shortening a p39 result to p34 and then to Real34
are outside this audit.

## Selected arithmetic

| Stage | Selected arithmetic | Reason |
| --- | --- | --- |
| Real34 coefficient extraction | exact representation access | no rounded decimal operation is required |
| decimal scale alignment | GMP integers | multiplication by a power of ten is exact |
| modular multiplication | GMP integers | repeated modular addition and doubling are exact |
| integer result shortening | exact GMP division | at least two discarded digits plus a sticky indication determine p39 rounding |
| shortened integer to working real | p39 | five digits separate the working value from the 34-digit public result under the accepted double-rounding exclusion |
| working exponent adjustment | exact representation edit | the coefficient is unchanged |
| Real34 result | p34 public boundary | the selected rounding mode and decimal128 exponent limits apply here |

P34 intermediate arithmetic is not a performance choice. Its wrappers require
decQuad unpacking and repacking, and a chain of p34 operations can cost more
than p39 arithmetic. This implementation uses no p34 arithmetic before the
public result conversion. P34 remains there only for Real34-lattice rounding
and exponent semantics, not for speed. P39 is both narrower than the previous
p75 result conversion and avoids an unnecessary decQuad arithmetic chain.

## Exact decimal model

Write the three positive finite inputs as

```text
z = A * 10^q_z
y = B * 10^q_y
x = C * 10^q_x,
```

where `A`, `B`, and `C` are integer coefficients with at most 34 digits. The
implementation stores signed scales `e_i = -q_i`, so the same values are

```text
z = A / 10^e_z
y = B / 10^e_y
x = C / 10^e_x.
```

The common result scale is

```text
E = max(e_z + e_y, e_x).
```

At that scale the required integer remainder is

```text
R = (A * B * 10^(E-e_z-e_y)) mod (C * 10^(E-e_x)),
result = R / 10^E.
```

Both exponents of ten are nonnegative, and at least one is zero. When the
product operand needs decimal shifts, the modulus is already at the common
scale, so each multiplication by ten is reduced immediately. Otherwise GMP
forms the scaled modulus exactly. The modular addition-and-doubling method then
returns the exact integer `R`. Reducing the multiplier modulo the scaled modulus
before the binary iteration changes neither the congruence nor the result and
reduces work for large coefficients.

The previous scale output was always `e_z+e_y`. When the modulus had a finer
decimal quantum, the integer remainder was therefore paired with the wrong
power of ten. For `3 * 5 mod 7.005`, the integer remainder is `990` at scale
three. The previous route returned `990`; the corrected common scale returns
`0.990`.

Real34 coefficient extraction now uses `real34GetCoefficient` and
`real34GetExponent`. Positive decimal exponents remain signed scales rather
than expanding a coefficient with thousands of zero digits before reduction.
No decimal context is involved in this conversion.

## Exponent bounds and direct reduction

A finite Real34 stored exponent is between `-6176` and `6111`. Each signed
scale is consequently between `-6111` and `6176`, while a product scale is
between `-12222` and `12352`. Exact scale alignment can require 18,463 decimal
places, all represented by GMP rather than a decimal quotient context.

The previous all-Real34 route multiplied at p75 and then used `WP34S_Mod`.
P75 was wider than necessary for the product, whose coefficient has at most 68
digits, but narrowing that multiplication does not repair the reduction. With
a finite modulus greater than one, the quotient can still need 12,289 integer
digits. The simulator reduction buffer provides 6,147 digits, and the DM42
route provides 2,139 digits.

The file-driven exponent case uses

```text
1E6144 * 1E6144 mod 7.
```

Since `10^6 mod 7 = 1` and `12288` is divisible by six, the exact result is
one. Direct decimal reduction returned NaN because the quotient did not fit
its reduction context. Exact coefficient reduction returns one without a
decimal quotient.

## Final conversion and rounding

The exact integer remainder is shortened to at most 42 digits before conversion
to a p39 `real_t`. The GMP digit-count estimate can exceed the decimal length by
one, so retaining p39 plus three estimated digits leaves at least two discarded
digits beyond the p39 coefficient. Exact division supplies the omitted remainder.
When that remainder is nonzero and the final retained digit is zero, changing
that digit to one supplies the sticky indication needed by every rounding mode.
The p39 conversion therefore rounds as if it had received the complete integer.
Its decimal exponent is then adjusted by the number of omitted digits and by
`-E`.

For an all-Real34 route, if `E = e_z+e_y`, the scaled product coefficient has at
most 68 digits. If `E = e_x`, the remainder is less than the at-most-34-digit
modulus coefficient. A mixed route with a long-integer modulus can instead
produce a much longer remainder. The exact shortening keeps both forms inside
the shared conversion buffer.

The p39 context has ample exponent range for every Real34 product scale. The
final conversion applies the selected Real34 rounding mode. Under the accepted
p39-to-p34 double-rounding exclusion, no wider context is required.

For

```text
a = 1.000000000000000000000000000000001,
```

the exact product is `1 + 2E-33 + 1E-66`. With modulus two, half-even returns
`1.000000000000000000000000000000002`, while rounding toward positive infinity
returns the adjacent value ending in three. The minimum-subnormal cases also
check half-even underflow to zero and directed underflow to `1E-6176`.

## Domain, specials, and dispatch

Real modular multiplication requires finite `X > 1`, `Y > 0`, and `Z > 0`.
Zero, negative, NaN, and infinity inputs produce the established domain error.
The explicit special checks are necessary because a sign predicate alone can
classify an unordered comparison as positive.

An angular tag on any Real34 operand produces the established type error.
Real and complex matrices also produce a type error in every stack position;
the operation has no elementwise matrix form.

`EXPMOD` remains an integer operation. Any Real34 operand, including an exact
integer-valued Real34, a special value, or an angular value, produces the type
error before numeric-domain evaluation. Matrices follow the same type-error
dispatch. No Real34 modular-power arithmetic context exists.

The shared integer modular helper is also used by integer-only routes. Their
scales are all zero, so the common-scale correction changes no integer result.
Reducing the multiplier before its binary iteration preserves every residue.

## Verification cases

The durable cases are in the existing `mulmod.txt` and `expmod.txt` files.
They cover the scale error, the maximum product exponent, result rounding,
directed underflow, every scalar domain boundary, specials, angular values,
all three matrix positions, and the Real34 modular-power rejection.

Before repair, the focused reading reported three failing cases: the mixed
scale result was `990` instead of `0.990`, the maximum-exponent result was NaN
instead of one, and NaN modulus input was accepted as an unordered positive
value. The repaired implementation succeeds in all 95 focused cases.

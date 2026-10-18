# Decimal context analysis for integer division

## Scope

This analysis covers `IDIV` and `IDIVR` whenever at least one operand is a
Real34 value. It includes Real34 paired with a long integer, short integer or
another Real34 value in either operand order. Integer-only routes are
unchanged.

The former implementation converted each operand to a p39 `real_t`, divided
there, and converted the integral result back to a long integer. That width is
not sufficient because an integer result is not limited to 34 or 39 digits.
Changing the work format to p51 or p75 would only move the failure boundary.

## Exact representation

Every finite Real34 value has the exact form

```text
C * 10^e
```

where `C` is a signed integer with at most 34 digits and `e` is the stored
decimal exponent. Long and short integers use exponent zero. For operands

```text
Y = C_y * 10^e_y
X = C_x * 10^e_x
```

define `m = min(e_y, e_x)` and the aligned integers

```text
A = C_y * 10^(e_y - m)
B = C_x * 10^(e_x - m).
```

GMP truncating division then gives exact integers `Q` and `R` such that

```text
A = Q * B + R
abs(R) < abs(B).
```

Consequently

```text
Y = Q * X + R * 10^m.
```

This proves that `Q` is the required quotient truncated towards zero and that
the exact remainder has the dividend's sign. No decimal working precision is
part of the quotient calculation.

## Result conversion

`IDIV` returns the exact GMP quotient as a long integer. `IDIVR` also converts
`R * 10^m` directly to Real34 once, using the selected rounding mode. The
coefficient is formatted with its decimal exponent and supplied to the
decimal128 converter, so no p39-to-p34 double rounding occurs.

This final conversion is a single 34-digit result operation. It therefore has
no unpacking and repacking penalty relative to a wider chain. A p39 or p75
intermediate would provide no additional quotient accuracy and could still
discard required integer digits.

## Special values

Zero divisors retain the existing domain error. A NaN or infinity selects the
former decimal path, preserving its result classification and the
`FLAG_SPCRES` handling. Angular metadata remains ignored for integer division;
`IDIVR` returns an untagged Real34 remainder as before.

## Verification

The focused `idiv.txt` and `idivr.txt` suites contain 451 successful function
invocations. New cases cover:

- a 50-digit long integer divided by Real34 `3.0`;
- long integer `1` divided by Real34 `3e-50`;
- Real34 `1e50` divided by long integer, short integer and Real34 `3`;
- positive and negative short integers divided by `+/-0.7`;
- a positive decimal exponent in `1000 / 3e2`;
- exact quotient and remainder checks in both operand orders.

On the former source, `1 / 3e-50` returned a quotient ending in eleven zeroes.
The exact route returns fifty threes and remainder `1e-50`. The 50-digit long
integer divided by `3.0` similarly recovers the eleven quotient digits that
p39 discarded.

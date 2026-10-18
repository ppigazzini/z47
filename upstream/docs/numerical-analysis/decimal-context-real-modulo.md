# Decimal context analysis for real modulo and remainder

## Scope

This analysis covers `modReal` and `rmdReal` for decimal128 values, including mixed integer/real inputs and element-wise real matrix dispatch. It also records the integer
sign correction used by `MOD`. Other integer-only operations, including `dblMultiplication.c` and `dblDivision.c`, are outside scope because neither file contains a
decimal, complex or matrix calculation. `WP34S_Mod` and `mod2Pi` perform angle reduction with wider operands and remain separate tasks.

## Recommendation

Use exact modular exponentiation in a local 68-digit context for two finite decimal128 operands. This replaces the 12,321-digit direct-division context on that route.
For a mixed integer/real pair, align the exact GMP integer coefficients and divide them directly. The sign correction in `modReal` is exact in both routes. Special
decimal inputs retain the p39 path.

The 68-digit context is copied from `ctxtReal75`, which supplies the wide exponent limits needed for scaled decimal128 coefficients. No fixed context is modified.

## Decimal representation

Write the magnitudes as

```text
x = A * 10^e_x
y = B * 10^e_y
```

where `A` and `B` are positive integers with at most 34 digits. When `e_x >= e_y`, the required coefficient is

```text
(A * 10^(e_x-e_y)) mod B.
```

Binary modular exponentiation evaluates the power without forming the integer quotient. When `e_x < e_y`, comparison has already established `x >= y`, so
`B * 10^(e_y-e_x)` has no more digits than `A`; one 68-digit remainder operation is exact.

Every reduced coefficient is less than the 34-digit divisor coefficient. A multiplication of two such values has at most 68 digits and is exact at precision 68.
The quotient of that product by the divisor is less than the divisor, so it has at most 34 digits and the following remainder operation is also exact. Induction over
the exponent bits proves that the returned coefficient equals the mathematical remainder. Scaling by the smaller decimal exponent and applying the dividend sign are
exact field operations.

The exact remainder has at most 34 coefficient digits. For modulo with differing operand signs, adding the divisor subtracts two magnitudes with a common decimal
quantum and returns a value whose magnitude is below the divisor. `ctxtReal34` therefore computes this correction exactly and applies no intermediate rounding.

## Why 68 digits are required

Precision 67 can round a product of two reduced 34-digit coefficients before the remainder operation. The file-driven adversary uses

```text
A = 6356230764183709140204657531161905
B = 8090145177164485152132432950591555
e_x - e_y = 8900.
```

Exact integer arithmetic gives

```text
(A * 10^8900) mod B = 5141104425213890844293115132346920.
```

The 68-digit implementation returns this value. A temporary 67-digit context returned `6891263743902806309722964691928220`; the focused suite then reported two
failures, one for modulo and one for remainder. A 39- or 51-digit context has the same unbounded loss when a rounded product is reduced modulo `B`.

An alternative can multiply a residue by `1000` and reduce after each three decimal places. That approach is exact at 39 digits but needs as many as 4,107 remainder
operations for one decimal128 exponent gap. The 68-digit binary method needs at most 14 squarings and 14 selected multiplications.

## Direct-division context

The largest finite decimal128 magnitude is

```text
(10^34 - 1) * 10^6111,
```

and the smallest positive decimal128 value is `10^-6176`. Their quotient is less than `10^12321` and can contain 12,321 integer digits. The decNumber remainder
operation requires that integer quotient to fit its context, even though the returned remainder is short. Therefore 12,321 is the minimum universal precision for the
generic direct-division method. A context copied from `ctxtReal39` is also required for its wide exponent limits; copying `ctxtReal34` and changing only its precision
would retain decimal128 exponent limits and lose the quotient.

Reducing the direct method to 12,320 digits made every new maximum-gap case return `NaN`: eight focused failures across the two functions. The real34 modular route
avoids that allocation and also removes the DM42 real34 limitation caused by its 2,139-digit generic buffer. Special inputs still use the generic implementation and
its platform-specific storage choice.

## Mixed integer and Real34 inputs

A finite Real34 already has an integer coefficient and decimal exponent. A
long or short integer has exponent zero. Both operands can therefore be aligned
to the smaller exponent and divided by GMP without converting the integer to a
fixed-width decimal first. The quotient is truncated towards zero and the GMP
remainder has the dividend sign, matching `RMD`.

For `MOD`, a nonzero remainder with a sign different from the divisor receives
one aligned divisor addition. The two addends have opposite signs, and the
result magnitude is below the divisor. Converting that exact scaled integer to
Real34 once applies the selected rounding mode at the public boundary. This is
important for long integers beyond p75: an early p75 conversion can erase the
residue or create a midpoint that rounds differently at p34.

When a finite integer dividend has an infinite Real34 divisor, `RMD` and the
same-sign `MOD` case equal the dividend. They now convert that integer directly
to Real34 once. An opposite-sign `MOD` result is the divisor infinity, as in the
existing decimal semantics. Other special inputs continue through the decimal
classification path.

## Integer sign correction

GMP division already returns a truncated remainder with the dividend sign. An
integer `MOD` result therefore needs the divisor added only when the nonzero
remainder and divisor have different signs. Same-sign inputs now return that
remainder directly. This avoids a bounded long-integer addition that could
report overflow for a valid one-unit dividend and a maximum-width divisor.
The sign-adjusted magnitude is below the divisor, so the required addition is
within the register limit. The short-integer route uses the same condition.

## Special values

Zero divisors retain the existing domain error in each command. NaN, infinity and zero-divisor inputs to the shared Real34 helper now use one 39-digit
`realDivideRemainder` operation. Their result is either an exact finite dividend or a non-finite classification, so any context of at least 34 digits gives the same
answer. A local context copied from `ctxtReal75` avoids changing global status and supplies ample exponent range.

The 39-digit choice is deliberate. A 34-digit decNumber operation has no performance advantage and conversion around chained 34-digit work can make that route slower.
No public-boundary semantic requires p34 here. The improvement comes from removing the unrelated 12,321-digit allocation, not from reducing p39 to p34.

Finite dividend remainder infinity returns the dividend, infinite dividend remainder a finite divisor returns NaN, and NaNs propagate. A nonzero remainder preserves
the dividend sign. The shared helper assigns the dividend sign to exact zero, after which the public result adjustment applies the calculator's established
positive-zero convention to scalar and matrix results. These properties do not depend on the rounding mode.

## Matrix and complex dispatch

The dyadic dispatcher applies `rmdReal` element by element for real matrix/matrix, real matrix/scalar and real scalar/matrix combinations. Each matrix element is a
decimal128 value, so the same exact 68-digit proof applies independently to every result. Shape mismatches remain matrix errors. The command has no complex callback;
complex scalars and matrices therefore remain type errors rather than defining a complex remainder.

## Rounding modes and conditioning

All products and remainders in the finite Real34 kernel are exact. The mathematical result has at most 34 coefficient digits and its sign is assigned exactly, so all
seven calculator rounding modes return the same value. The special branch also has no finite rounding error.

As a function of perturbed real arguments, remainder is discontinuous at integer quotients and has no uniform relative condition bound near zero. That does not weaken
the result here: decimal128 register values are the exact inputs being reduced, and the modular algorithm returns their exact mathematical remainder. It does not form
the potentially enormous quotient or subtract two nearly equal wide values.

## Tests

`modulo.txt` and `remainder.txt` cover the maximum finite dividend against `7E-6176` for every sign combination. Integer congruence gives a coefficient remainder of
one, so the expected remainder values are `+/-1E-6176`; modulo adjusts the opposite-sign cases to `+/-6E-6176`. The 68-versus-67 adversary above checks the minimum
working precision under nearest and directed modes. Remainder cases also cover signed zero, NaN, infinities, all three real matrix pairings and a matrix shape error.

Mixed tests use the exact integer `10^79+1` with divisors `3` and `0.3`, all
four sign combinations, and both operand orders against `1E100`. A separate
infinite-divisor case distinguishes direct p34 rounding from the former
p75-to-p34 double rounding. Further cases cover a p34 rounding boundary, exact
positive zero, the minimum Real34 quantum, and the maximum finite Real34 value.
Opposite-sign unit dividends with divisors at `+/-1E6144` verify the wide
coefficient conversion and directed rounding.

A maximum-width positive long divisor with a one-unit positive dividend checks
that the integer route does not perform an unnecessary overflowing addition.

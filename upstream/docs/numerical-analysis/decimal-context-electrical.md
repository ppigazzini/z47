# Decimal contexts for electrical transforms

## Scope and selections

This analysis covers the electrical functions in `elec.c` whose inputs and
outputs are Real34 or Complex34 values.

| Function | Work context | Reason |
| --- | ---: | --- |
| Delta to star | 75 digits | Products and complex quotients follow cancellation-sensitive sums. |
| Star to delta | 75 digits | Three pairwise products can cancel by more than 39 or 51 digits. |
| Symmetrical components to ABC | 75 digits | Sequence rotations can cancel and expose low digits of sqrt(3). |
| ABC to symmetrical components | 75 digits | The inverse sequence sums have the same cancellation. |
| Three-phase `V/I` and `V/Z` | 75 digits | Each operation is a direct Complex34 division. |
| Three-phase `I*Z` | 39 digits | Each operation is a direct Complex34 multiplication. |
| Copy X to ABC | 39 digits | Each calculated value is one isolated rotation. |

The polar-display toggle performs no numerical transform in this file.  The
stack and named-register transfer helpers perform no decimal arithmetic.

These selections target faithful 34-digit accuracy.  A final 39-to-34 or
75-to-34 boundary discrepancy is excluded as requested.  No universal
componentwise-relative claim is possible when a complex result is arbitrarily
close to an axis.  The bounds for those cases are normwise, while direct
Complex34 division has the stronger component result described below.

## Work precision model

For a `p`-digit half-even context, define

```text
u_p = 0.5 * 10^(1-p).
```

Thus `u_39=5E-39`, `u_51=5E-51`, and `u_75=5E-75`.  The work contexts have
exponent limits of plus or minus 999999, so every sum, product and quotient
formed from finite Real34 inputs is clear of a work-context range boundary.

## Complex multiplication and division dependencies

The audited compensated complex-multiplication kernel has the component bound

```text
|fl(z*w) - z*w| <= 2*u_p*|z*w|
```

at 39 digits.  Its work exponent range also prevents premature range loss.
This makes p39 sufficient for the independent phase products in three-phase
`I*Z` and for the two rotations in Copy X to ABC.  The p39 approximation to
sqrt(3)/2 contributes less than `u_39` relative error to an isolated rotation.
P34 has neither the five-digit margin nor the required wide exponent range.

The audited direct Complex34 division requires p75.  In

```text
(a+ib)/(c+id),
```

the component numerators are `ac+bd` and `bc-ad`.  Two Real34 products can
each have 68 coefficient digits.  P75 makes those products exact before the
subtraction, whereas p39 discards as many as 29 digits and p51 discards as many
as 17.  After the final p75 division, each nonzero direct-division component
has working relative error below `1.51E-74`; exact cancellation produces exact
zero.  The three-phase `V/I` and `V/Z` functions therefore use p75.

## Network conversion sums

Star to delta forms

```text
P = x*y + y*z + z*x
```

before dividing P by each input impedance.  Every real product of two Real34
components has at most 68 coefficient digits.  A complex-product component,
which is a sum or difference of two such products, has at most 69 aligned
digits.  P75 therefore preserves every aligned product component exactly.

Delta to star similarly forms three pairwise products and the denominator
`S=x+y+z`.  Both conversions now use a two-term expansion for each three-value
sum.  FastTwoSum first produces a rounded leading value and its exact residual.
Two stages preserve a small term across patterns such as `large + small -
large`; the residuals are combined before the final p75 result.  For terms of
similar magnitude, all aligned coefficient digits fit within p75.  For widely
separated terms, the expansion prevents an early discarded term from becoming
the only survivor after a later cancellation.

The closing complex divisions can have a component arbitrarily close to zero
because of input geometry.  Their arithmetic error is bounded relative to the
complex norm, not relative to that small component.  P75 provides at least 40
decimal guard places for ordinary conditioning and materially extends the
accurate component range.  P39 and p51 are not suitable: the stored real
star-to-delta discriminator gives only 5 and 16 correct significant digits,
respectively.

For that discriminator,

```text
x = 9794374625685484555019278584798515
y = 6230319616471174524125468311303272
z = -3808003038269716611271229923194149
```

integer arithmetic gives

```text
x*y + y*z + z*x = -7166890585241250100545976486603183.
```

P75 forms this integer exactly.  P39 forms `-7.1669E33`, while p51 forms
`-7.1668905852412502E33`.  The first delta impedance is consequently

```text
1.882060101637352535043739950142617...
```

at p75, versus `1.882062573998497...` at p39 and
`1.882060101637352561...` at p51.

## Symmetrical components

The sequence transforms use

```text
a  = -1/2 + i*sqrt(3)/2,
a2 = -1/2 - i*sqrt(3)/2.
```

The former p39 constant limited results after cancellation.  P75 transforms
derive sqrt(3)/2 at p75 and use p75 complex products plus the same expanded
three-value sum.  A p51 constant still leaves only about 17 significant digits
in the stored discriminator.

For `A1=10^34-1`, `A2=A0=10^34`, one phase contains

```text
A0 + a2*A1 + a*A2 = 1/2 + i*sqrt(3)/2.
```

The p39 calculation gives an imaginary component of `0.86603`; p51 gives a
value whose first error is near digit 18; p75 supplies the requested 34-digit
value.  The inverse transform has the corresponding small component
`1/6-i*sqrt(3)/6`.

A Real34 ratio can approximate the irrational rotation closely enough to make
one output component much smaller than the vector norm.  P75 does not establish
a uniform component-relative theorem for that class.  The transform remains
normwise well-conditioned because its matrix is unitary up to the scale factor
three, and p75 reduces the arithmetic contribution far below a Real34 ulp of
the vector norm.

## Rounding modes and special values

All work contexts use half-even rounding.  Conversion to Real34 applies the
selected calculator mode.  The accepted final-width boundary exclusion applies
to half-even, half-up, half-down, away from zero, toward zero, ceiling and
floor.

The context changes do not alter the existing complex-result gate, NaN and
infinity policy, stack movement, named-register updates, or signed-zero
conversion.  The expanded summation falls back to ordinary arithmetic for a
NaN or infinity, avoiding residual expressions such as infinity minus
infinity.

## Verification

The existing file-driven `elec.txt` suite includes:

* the 68-digit pair-product cancellation above;
* forward and inverse sequence cancellation exposing sqrt(3);
* delta-to-star division with a 35-place small quotient component;
* the same quotient through both stored three-phase division functions; and
* the earlier real, complex, range-gate, stack and polar-display cases.

With every changed route deliberately reduced to p39, 48 of 54 focused checks
succeed.  The six new numerical discriminators fail, with only about five
correct significant digits in their sensitive components.  A p51 mutation
also succeeds in 48 of 54 and supplies only 16 or 17 correct significant digits
for those components.  The selected contexts succeed in all 54 focused checks.

# Decimal context analysis for representation helpers

This analysis covers the real-number routes of `DECOMP`, `MANT`, `EXPT`, `ULP`,
`NEIGHB`, `SDL`, `SDR`, and `FP`. It also covers the real-matrix routes that
exist for `NEIGHB` and `FP`, and the shared fraction selection used by
`DECOMP`. Integer arithmetic itself is outside the analysis; the long-integer
conversions used by `MANT` and `NEIGHB` are included.

Differences caused only by shortening a p39 result to p34 and then to Real34
are outside this audit.

## Selected arithmetic

| Route | Selected context | Reason |
| --- | --- | --- |
| `DECOMP` integer and fractional split | p34 | truncation is explicit and the subtraction is exact |
| fixed-denominator fraction numerator | p39 | the widened fused operation retains the Real34 numerator boundary for `D <= 32500` |
| factor-of-maximum fraction candidates | p39 | each candidate is on the grid with denominator `D`, so the same separation applies |
| unrestricted Farey fraction selection | p51 | two candidate denominators introduce a factor as large as `D^2`; a p39 discriminator fails |
| `MANT` finite real | no arithmetic context | only coefficient digit count and exponent are changed |
| `MANT` long integer | one Real34 conversion | the exact integer coefficient is rounded only at the result boundary |
| `EXPT` real or integer | no arithmetic context | the stored exponent or exact decimal digit count determines the result |
| `ULP` finite real | no arithmetic context | the Real34 lattice exponent determines an exact power of ten |
| `NEIGHB` real and real matrix | p34 | the operation is defined by adjacency in the Real34 lattice |
| `SDL` and `SDR` finite real | no intermediate arithmetic context | changing the decimal exponent is exact; Real34 conversion applies range and mode |
| `FP` finite real and real matrix | p34 | directed truncation is exact and the following subtraction is exact |

These widths describe accuracy and representation semantics, not execution
speed. P34 arithmetic requires decQuad unpacking and repacking and has no
inherent performance advantage over p39; a chain of p34 wrapper operations
can cost more. `DECOMP` and `FP` retain p34 operations because their public
Real34 truncation and exact subtraction need no wider intermediate result.
`NEIGHB` requires p34 specifically because its result is adjacent in the
Real34 lattice. Fraction selection uses p39 or p51 internal arithmetic where
candidate discrimination needs additional digits.

The target files contain no bare decNumber, decQuad, or decDouble operation.
All decimal operations use the wrappers in `realType.h`.

## `DECOMP`

Let a finite Real34 input be `x`, and define

```
a = trunc(abs(x))
f = abs(x) - a
```

If `a=0`, then `f=abs(x)` is copied exactly. If `a>=1`, `a` and `abs(x)`
have the same sign, `a <= abs(x) < a+1`, and `abs(x)/a < 2`. Decimal
Sterbenz subtraction therefore makes `f` exact at p34.

The fraction selector supplies `n/d` for `f`, with `d <= 32500`. The final
improper numerator is formed as

```
N = sign(x) * (a*d + n).
```

`a`, `N`, and `d` are integers. GMP multiplication and addition make this
recombination exact. No decimal working context is required after fraction
selection.

The previous route sent the complete magnitude to `fraction()`. That helper
converted the integer part through `uint32_t`; an out-of-range conversion
became zero. A Real34 input of `5000000000` consequently produced `0/1`, and
`-5000000000.5` produced `-1/1`. The revised route sends only `f` to the
bounded fraction selector and converts `a` directly to a long integer. Inputs
with positive decimal exponents, including `1e100`, therefore retain every
integer digit.

NaN retains the established `0/0` result. Positive and negative infinity
retain `1/0` and `-1/0`. Real and complex matrices and scalar complex values
remain type errors.

### Fraction-selection widths

For a fixed denominator `D`, the numerator is

```
floor(D*f + 1/2).
```

The Real34 input has at most 34 coefficient digits, while `D` has at most five
digits. A p39 fused operation therefore evaluates the scaled coefficient
without discarding an input digit. The same result applies when denominators
are restricted to factors of `D`: every such rational is also a point on the
denominator `D` grid. P39 is sufficient for the numerator operation and the
candidate distance comparisons.

The original p34 fused operation does not provide this separation. For

```
D = 9999
f = 5.000500050005000500050005000500050e-5,
```

the exact value of `D*f+1/2` is immediately below one. P34 rounds it to one,
selecting `1/9999`; p39 selects the correct `0/9999`.

The unrestricted Farey route compares rationals `a/b` and `c/d`, where both
denominators can approach the configured maximum. Their midpoint has a
denominator no greater than `2D^2`. A non-equal Real34 input and such a
midpoint can differ by about `1/(2D^2*10^34)` relative to their decade. P51
has more than seven decimal guard digits against that bound; p39 has none.

The durable discriminator is

```
x = 0.7323474125192068722573232698216628.
```

Its two adjacent Farey candidates are `5051/6897` and `3516/4801`. The input
is `3.5032090754e-40` above their exact midpoint, so `3516/4801` is nearer.
At p39 both computed distances are equal and the former candidate is selected.
P51 preserves the ordering.

## `MANT`

For a finite nonzero decNumber representation with `p` coefficient digits
and exponent `e`, `MANT` changes the exponent to `1-p`. The coefficient and
sign are unchanged, so the value becomes a signed number in `[1,10)` in
magnitude. This is a representation edit and has no rounding error.

Zero remains zero. The established special-value policy rejects NaN and
permits infinity only when special results are enabled. Scalar complex values
and both matrix types remain type errors.

For a long integer, its exact decimal coefficient is paired with exponent
`1-p`, where `p` is counted from the coefficient string without its sign. One
direct Real34 conversion then applies the selected rounding mode. The former
p39 conversion could first round digit 40 and create a false p34 midpoint. A
second rounding could consequently change the final unit in the last place.

## `EXPT`

For a finite nonzero Real34 with exponent `e` and `p` coefficient digits,
`EXPT` returns `e+p-1`. Zero returns zero. These fields are read directly after
unpacking and require no decimal arithmetic.

For an integer, the result is one less than the exact count of coefficient
digits, with the sign character excluded. Counting the GMP decimal string
avoids converting the value to p75 first. Such a conversion maps an 80-digit
string of nines to `1E80` and incorrectly changes the result from 79 to 80.

## `ULP`

For decimal precision `p=34`, adjusted exponent `A`, and minimum quantum
`Etiny=-6176`, the unit in the last place is exactly

```
10^max(A-p+1, Etiny).
```

Zero uses `10^Etiny`. The revised implementation constructs this power of ten
from the Real34 representation fields. It performs no rounded arithmetic and
is independent of the selected rounding mode.

The previous implementation subtracted `x` from its neighbour toward positive
infinity. At a negative power-of-ten boundary that upward interval is one
tenth of the unit associated with the magnitude. It therefore returned
`1e-34` for `ULP(-1)` instead of `1e-33`. Direct exponent construction is
symmetric and also covers the minimum subnormal and maximum finite values.

NaN propagates. Infinity remains a domain error. Complex values and matrices
remain type errors.

## `NEIGHB`

`NEIGHB(x,y)` is defined by the next Real34 value from `x` toward `y`.
`ctxtReal34` is therefore necessary: a wider context would select adjacency
in a different lattice. The decNumber wrapper selects the direction without
using the caller's rounding mode. Equal values copy the sign of `y`, which
includes the two zero signs. The exponent endpoints produce zero, the minimum
subnormal, the maximum finite value, or infinity as required by direction.

When `x` is Real34 and `y` is a long integer, direction is selected by an
exact comparison of the Real34 coefficient and exponent with the GMP integer.
Converting the target to p75 first can remove the difference: both `10^80-1`
and `10^80+1` round to `10^80` at that width. The exact comparison scales one
integer coefficient by a power of ten, then supplies positive or negative
infinity to the p34 neighbour operation. An exactly equal target retains its
converted value, including signed-zero behaviour.

The generic dyadic dispatcher supported real matrices but invoked a null
complex callback when `X` was numeric and `Y` was a complex matrix. The added
guard reports the established type error. Real scalar/matrix and matching
real-matrix routes continue element by element. Scalar complex values and
complex matrices have no ordered-neighbour route.

## Decimal shifts

`SDL` and `SDR` add or subtract a parameter in `[0,99]` from the decNumber
exponent. This edit is exact and cannot overflow the signed exponent field.
The closing Real34 conversion applies the selected rounding mode and the
decimal128 exponent range. Tests cover positive and negative overflow,
directed underflow, NaN, and infinity. Complex values and matrices remain type
errors.

## Fractional part

The real fractional part is

```
x - trunc(x).
```

For `abs(x)<1`, truncation is zero and the subtraction copies `x`. For
`abs(x)>=1`, the operands have the same sign and their magnitude ratio is
less than two. Decimal Sterbenz subtraction is exact, including a fractional
term beside a 32-digit integer term. P34 is consequently the narrowest useful
context.

The sign of an exact zero result is taken from `x` when special results are
enabled. This agrees with negative non-integers and with the existing signed
short-integer convention. NaN propagates, while either infinity produces NaN.
Real matrices use the same scalar operation element by element. Complex
values and complex matrices remain type errors.

## Verification cases

The new cases are written in the existing `decomp.txt`, `mant.txt`, `expt.txt`, `ulp.txt`,
`neighb.txt`, `fractionalPart.txt`, and `mathmisc_cov.txt` files. They cover
large improper numerators, fraction-selection boundaries, Real34 exponent
limits, directed modes at range boundaries, signed zero, NaN, infinity,
real-matrix evaluation, and rejected complex or matrix types.

Four additional neighbour cases place `x` at positive or negative `10^80`
and use exact long-integer targets one unit to either side. They require all
34 result digits and distinguish the adjacent Real34 values from an unchanged
input.

Long-integer `MANT` cases place discarded digits on either side of p34
midpoints. Positive and negative inputs exercise all seven rounding modes and
require all 34 result digits.

Long-integer `EXPT` cases distinguish `10^80-1` from `10^80` and include a
negative coefficient.

With the original arithmetic, three large `DECOMP` cases fail, `ULP(-1)` is a
factor of ten too small, two fractional-part cases lose negative zero, and the
complex-matrix `NEIGHB` case terminates the test executable with status 139.
The p34 fixed-denominator case selects `1/9999` instead of `0/9999`. A p39
mutation of the Farey comparisons succeeds for 191 of 192 focused checks and
selects `5051/6897` in place of the nearer `3516/4801`.

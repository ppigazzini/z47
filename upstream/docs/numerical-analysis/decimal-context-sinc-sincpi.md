# Decimal context analysis for sinc and sincpi

## Scope

This analysis covers the scalar and complex entry points for `sinc(z) = sin(z)/z` and `sincpi(z) = sin(pi*z)/(pi*z)`. The zero and infinity branches are included.
Real and complex matrix elements use the same entry points. The completed sine, cosine, hyperbolic sine, hyperbolic cosine, multiplication, and complex-division
analyses supply the dependency bounds used below.

## Recommendations

For scalar `sinc`, request the sine at 39 digits and divide at 39 digits. The shared trigonometric helper evaluates a 39-digit request with a 51-digit internal
series before shortening its result to 39 digits. A 75-digit division cannot recover digits beyond its two 39-digit operands. Tagged angles must enter the
trigonometric helper before conversion to radians so that quadrant reduction occurs in the exact source unit.

Keep the general complex `sinc` route at 75 digits because its complex numerator and division can contain severe component cancellation. For both components below
`0.1` in magnitude, evaluate the entire sinc power series at 75 digits. This avoids cancellation that no fixed-width evaluation of `sin(z)/z` can control near zero.

Keep scalar and complex `sincpi` at 75 digits and use the 75-digit pi constant. Precision 51 cannot preserve a decimal128 input's small distance from an integer.
Detect exact integers without a remainder quotient, returning the exact zero before multiplication by pi. After pi scaling, reuse the complex sinc kernel and its
small-argument series.

## Scalar sinc

After the sine and radian denominator have been calculated, write their relative errors as `delta_s` and `delta_x`. A correctly rounded 39-digit division gives

```text
computed/sinc(x) = (1+delta_s)(1+delta_d)/(1+delta_x),
|delta_d| <= u_39 = 5E-39.
```

Thus the division adds less than `5E-39` relative error to the two existing operand errors. Evaluating that division at 75 digits only returns more digits of the
quotient of two already rounded 39-digit values. It does not reduce either operand error. Precision 39 is the narrowest established final division context with a
five-digit margin before decimal128 conversion.

A temporary 34-digit request and division failed the exact half-even case `x=0.3`. The correct decimal128 result is
`0.9850673555377985836844024856167579`; the 34-digit route differed by one output ulp. The file-driven subtraction scales any last-digit residue by `1E40`, so the
normal comparison tolerance cannot hide it.

### Tagged angle order

The former route first converted a tagged angle to radians at 39 digits and then reduced the rounded radian value. Near a sine zero, subtraction of a multiple of pi
amplified that conversion error without bound. For `179.9999999999999999999999999999999` degrees, the distance from 180 degrees is `1E-31` degrees. Converting the
full angle first left only five correct digits in `sinc`.

The revised route gives the original degree value to the trigonometric helper. Its quadrant steps reduce the angle to `1E-31` degrees before conversion to radians,
so the conversion has relative rather than cancellation-amplified error. The denominator is converted separately; near 180 degrees it is near pi and is
well-conditioned. The resulting value is

```text
5.555555555555555555555555555555559E-34.
```

Untagged real values retain the existing radian interpretation, independent of the current angular mode. Degree, gradian, DMS and multiple-of-pi tags retain their
existing meanings.

A scalar long integer needs two representations: exact radian reduction for
the sine numerator and a p75 conversion of the original integer for the
denominator. A single p75 conversion cannot supply both because adjacent wide
integers can become equal before phase reduction.

## Scalar sincpi

Let a non-integer decimal128 input be `x=n+d`, where `n` is an integer and `d` is the represented fractional part. The smallest possible relative separation from an
integer is of order `1E-33`. Multiplication by pi followed by quadrant reduction subtracts `n*pi`; a p-digit multiplication error can therefore be amplified by about
`1E33` in the reduced phase. Precision 39 or 51 cannot support a 34-digit result for every decimal128 value near an integer.

At 75 digits, the multiplication and the pi constant provide about 42 significant digits after the worst decimal128 phase cancellation. This leaves eight decimal
guard digits before conversion. The 75-digit trigonometric work and division preserve that margin under the completed shared-kernel analyses. Among the established 39-,
51- and 75-digit contexts, 75 is the narrowest suitable choice.

The adversarial input

```text
x = 1.000000000000000000000000123456789
```

has

```text
sincpi(x) = -1.234567889999999999999999847584212...E-25.
```

The former 39-digit pi constant produced only 14 correct digits on the scalar route and 13 on the complex route with zero imaginary part. With the 75-digit pi
constant but a temporary 51-digit calculation, both routes retained only 25 correct digits. The settled 75-digit routes return the expected decimal128 value.

Exact integer inputs have zero numerator. `realIsAnInteger` determines this from the decimal value at bounded precision, while the former complex test formed a
remainder quotient. Returning zero before multiplication also avoids unnecessary 12,321-digit reduction for exponent-limit integers.

## Complex routes

For `z=a+ib`, the shared complex sine gives

```text
sin(z) = sin(a) cosh(b) + i cos(a) sinh(b),
```

followed by complex division by `z`. Either output component can be arbitrarily small through cancellation between two products in that division. A 39- or 51-digit
componentwise relative bound is therefore unavailable. Both `sinc` and `sincpi` use 75 digits for the trigonometric, hyperbolic, multiplication and complex-division
steps. The recent compensated complex-division analysis applies to direct decimal128 operands; here its numerator is a correlated transcendental intermediate, so no
narrower claim is inferred from that result.

The finite input

```text
z = 4 + 3.447777344928863627599412458046536 i
```

is close to a zero of the imaginary output component. Independent 220-digit decimal series and exponential calculations give

```text
sinc(z) = -2.976340728428696105254325759276172...
          + 1.516479786557633130140821279065189...E-34 i.
```

A p51 trial retained only 16 significant digits in the imaginary component and returned
`1.516479786557633088120084440072651E-34`. P75 returns the stated 34-digit value. This establishes p75 as the narrowest available context for the general complex
route. It does not establish universal correct rounding at a final decimal128 boundary; the requirement here is 34-digit accuracy.

For `sincpi`, multiplying both components by the 75-digit pi constant precedes the same calculation. The zero-imaginary adversary above proves the need for more than
51 digits on this route.

### Complex values near zero

Let `q=z^2`. Direct division is unsuitable when both components of `z` are tiny. In the imaginary quotient numerator,

```text
a cos(a) sinh(b) - b sin(a) cosh(b) = -ab(a^2+b^2)/3 + higher terms.
```

The two evaluated products are each about `ab`, so cancellation loses about `-log10(a^2+b^2)` digits. No fixed 75-digit context can cover the decimal128 exponent
range. At `a=b=1E-3000`, the former route returned a zero imaginary component although the decimal128 result is
`-3.333333333333333333333333333333333E-6001`.

The revised route evaluates

```text
sinc(z) = 1 - q/3! + q^2/5! - q^3/7! + ...
```

when `|a|<0.1` and `|b|<0.1`. In this square, `|q|=a^2+b^2<0.02`, and consecutive term magnitudes have ratio at most

```text
0.02 / ((2n+2)(2n+3)) <= 0.02/6.
```

The term with `n=20` is below `3.2E-84`, so fewer than 20 terms suffice at p75. The sum of absolute correction terms is below `0.00334`, keeping the real result away
from zero. If `v=Im(q)=2ab`, then `|Im(q^n)| <= n|v||q|^(n-1)`. Relative to the first imaginary term, all later imaginary terms total less than

```text
6 * sum(n * 0.02^(n-1) / (2n+1)!, n=2...) < 0.00201.
```

Thus the small imaginary component is also well-conditioned. Fewer than 300 rounded elementary steps contribute less than `2E-72` at p75 before second-order terms,
leaving more than 37 decimal guard digits. The real correction is accumulated separately from one. If adding a nonzero correction rounds back to exactly one, one
p75 neighbour in the correction's direction records the lost direction. This neighbour still rounds to one in the three nearest modes and gives the correct adjacent
decimal128 number in a directed mode.

`sincpi` multiplies `z` by the p75 pi value and invokes the same series. At `z=1E-3000+1E-3000i`, its imaginary component is
`-3.289868133696452872944830333292050E-6000`. The scalar and complex matrix paths inherit the corresponding scalar or complex result without another working context.

### Finite hyperbolic overflow

When finite `b` is large enough that p75 hyperbolic sine and cosine are infinite, the mathematical decimal128 result is determined by

```text
Re numerator / cosh(b) = a sin(a) + |b| cos(a),
Im numerator / cosh(b) = sign(b) (a cos(a) - |b| sin(a)).
```

The denominator is positive and polynomial in `a` and `b`, while the omitted hyperbolic factor is exponential. A nonzero coefficient therefore selects the sign of an
infinite output. An exact zero coefficient gives a zero output after the exponentially decreasing counterpart is divided by the polynomial denominator. Forming these
finite coefficients before setting zero or signed infinity avoids the NaNs produced by dividing infinite rectangular components. The pure imaginary case uses
`sinh(b)/b` directly.

## Special values

Both functions return one at exact scalar or complex zero. Scalar infinity returns zero when special results are enabled and retains the existing domain error
otherwise. NaNs and complex infinite inputs retain the existing sine, hyperbolic, and division classifications. Finite inputs whose hyperbolic intermediate overflows
now return the signed zero or infinity selected by the formulas above. Exact zero products remain zero instead of becoming NaN.

## Tests

The existing file-driven tests cover tagged angle cancellation, exact scalar digit 34, complex near-integer inputs, exponent-limit integers, tiny complex scalar and
matrix inputs, directed conversion of a correction below p75, closing-division cancellation, and finite hyperbolic overflow. Independent decimal evaluation supplies
the new tiny and cancellation values.

The original division formula succeeded in 75 of 79 focused checks after the first tiny cases were added. Before the finite-overflow branch, 87 of 89 checks
succeeded. Removing the p75 direction marker succeeds in 100 of the then-current 102 checks. A p51 general-complex trial succeeds in 91 of the then-current 93 checks
and retains only 16 significant digits in the cancellation case. The settled
implementation succeeds in all 110 focused checks. Two adjacent 81-digit
integers verify independent phase reduction while retaining the unreduced
denominator.

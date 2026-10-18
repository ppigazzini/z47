# Decimal context analysis for the quadratic solver

## Scope and decision

This analysis covers the scalar `SLVQ` calculation, the two- and
three-coefficient vector routes, and the quadratic reduction used by `SLVC`.
The coefficients are Real34 or Complex34 values and the roots are converted
to the same 34-digit component format.

The selected work context remains p75.  It is the narrowest established
context among p34, p39, p51, and p75 that retains a cancellation-sensitive
discriminant formed from arbitrary 34-digit coefficients.  The complex
reconstruction is changed to avoid two independent cancellation defects.

## Discriminant width

For real coefficients,

```text
D = b^2 - 4*a*c.
```

Each input product has at most 68 coefficient digits and multiplication by
four needs at most one additional digit.  When the two terms can cancel, their
exponents are close and p75 retains the complete products and their
difference.  If their exponent separation exceeds the available coefficient
width, the smaller term is already below the p75 relative error scale.

The same reasoning applies component by component to the complex products.
Each component of `b^2` or `a*c` is a sum or difference of two 68-digit real
products.  At p75 the cancellation-relevant form uses at most 71 coefficient
digits after the factor four and the final subtraction.

P51 is insufficient.  The existing real coefficients

```text
a = 1111222233334444555566667777888886
b = 1111222233334444555566667777888885
c = 277805558333611138891666944472221
```

have the integer discriminant `D=1`, obtained beside terms near `1E66`.
Deliberate p51 work changes the sign of the computed discriminant and returns
roots with spurious imaginary components near `2.58E-26`.  P39 and p34 lose
still more product digits.  P75 is therefore required even though most
ordinary quadratics use far fewer digits.

## Stable complex square root

The former complex route converted the discriminant to polar form, halved the
angle, and converted back.  An angle close to either side of pi loses a small
but valid real component.  The revised principal square root uses

```text
rho = hypot(x,y)

x >= 0:  u = sqrt((rho+x)/2),  v = y/(2*u)
x <  0:  v = sign(y)*sqrt((rho-x)/2),  u = y/(2*v).
```

In each branch the large component is formed by addition of like-signed
magnitudes.  The small component follows from `2*u*v=y`, without subtraction.
The separately analysed magnitude kernel has relative error below
`1.01E-74` at p75.  The noncancelling addition, square root, and division add a
small fixed multiple of `u75=5E-75`.

For `x^2 + (1+i*1E-100)=0`, the positive-real component of one root is about
`5E-101`.  The former polar reconstruction returns approximately
`3.104499314E-75`, which has the wrong scale.  The revised algebraic formula
retains the expected component on both sides of the cut.

## Stable root numerators

For a complex square root `s=sqrt(D)`, directly evaluating both
`(-b+s)/(2a)` and `(-b-s)/(2a)` can cancel one numerator.  The revised route
uses the sign of

```text
Re(conj(b)*s)
```

to select the larger of `b+s` and `b-s`.  It forms the corresponding root as
`q/a`, then obtains the other as `c/q` from Vieta's identity.  The original
principal-square-root ordering is retained when the results are stored.

For

```text
x^2 + (1+i)*x + 1E-60 = 0,
```

the former p75 numerator subtraction leaves about 14 correct digits in the
small root and perturbs the large root at its thirtieth digit.  The selected
route returns the 34-digit components of both roots.

The sign test can be sensitive only when the two numerator magnitudes are
nearly equal.  In that region either sign is well conditioned.  Away from it,
the larger numerator has no destructive subtraction.  The closing complex
divisions therefore retain a p75 normwise error scale.

An individual component of a general complex root can be arbitrarily small
relative to the root magnitude.  No fixed context gives a uniform
componentwise-relative guarantee for every such input.  The claim here is a
34-digit normwise result, together with componentwise retention for the
square-root cut and numerator-cancellation classes addressed above.

## Rounding and special values

P75 work uses half-even rounding.  Conversion to Real34 or Complex34 applies
the selected calculator mode.  The result is a faithful 34-digit value rather
than a universal correctly rounded value; differences caused only by the
final p75-to-p34 conversion are outside this claim under the requested
double-rounding policy.

When the optional p159 kernel is enabled, its inputs originate in Real34
component storage. Copying those values into wider temporaries is exact; a
p159 unary rounding operation cannot add information and is unnecessary.
The computed p159 roots still receive the established p39 rounding before
the public Real34 conversion.

Linear equations, an exact zero constant term, exact repeated roots, NaNs,
and infinities retain their existing branches.  Distinct work destinations
are now used for the complex discriminant products, avoiding dependence on
output aliasing in the shared multiplication kernel.

## Verification

The added cases are in the existing `slvq.txt` file.  They cover both sides of
the negative-real square-root cut and a small root obtained through Vieta's
identity.  With the final cases, the former reconstruction succeeds in 48 of
51 focused checks.  The selected reconstruction succeeds in all 51.  A p51
context trial also fails the two existing exact-discriminant checks described
above.

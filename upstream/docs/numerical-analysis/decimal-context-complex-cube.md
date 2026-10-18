# Decimal context analysis for complex cube

## Scope

This analysis covers the public complex34 route in `cubeCplx` and its finite helper `cubeComplex`. Scalar real cube, short integers, long integers, matrices and the
159-digit routes need separate analyses. The compensated complex-multiplication and complex-square bounds are dependencies only where this document compares the
former implementation.

## Recommendation

Keep `ctxtReal39` for complex cube. It is sufficient for a 34-digit result and is the narrowest suitable established context among 34, 39, 51 and 75 digits.
`ctxtReal34` produces ordinary finite errors and loses finite values at both decimal128 exponent limits. Widths of 51 and 75 digits reduce an already adequate bound
without changing the final format.

Use the specialised component formula

```text
Re(z^3) = a(a^2 - 3b^2),
Im(z^3) = b(3a^2 - b^2).
```

Each parenthesised factor uses a compensated sum of two products. This gives a componentwise relative bound even when either cube component is much smaller than
the other. It also reduces the finite route from sixteen arithmetic operations in two general complex multiplications to twelve.

## Defect in two consecutive complex multiplications

The former route first computed a 39-digit approximation to `z^2`, then multiplied that approximation by `z`. The complex multiplication kernel is stable for the
floating-point operands supplied to one invocation, but the second invocation cannot recover errors already present in the approximate square.

Write the computed square as

```text
R2_hat = a^2 - b^2 + delta_R,
I2_hat = 2ab       + delta_I.
```

The real input to the second multiplication differs from the exact real cube component by

```text
a * delta_R - b * delta_I.
```

Its absolute size depends on the two terms of order `|z|^3`, not on the possibly tiny real cube component. The former route retains a small normwise error but has no
componentwise relative guarantee near a real- or imaginary-component zero.

A Pell equation supplies an exact decimal demonstration:

```text
a = 2778915293036784572512633160826602
b = 1604407492489955336783484248535599
a^2 - 3b^2 = 1
```

The exact cube components are

```text
R = 2778915293036784572512633160826602
I = 33039542981559979987211181303948982401149337531293659262961457652414911336480956999496272191621821189
```

The two-multiplication route returned

```text
3.58315113540872603514399615653972E+60
  + i*3.303954298155997998721118130394898E+100.
```

The real component is about 27 decimal orders larger than its exact value. The specialised formula computes the parenthesised real factor as exactly one in this
case, then returns the exact 34-digit real component.

## Compensated component factors

For either parenthesised factor, write the exact value as `H = xy + sv`. At a `p`-digit half-even context the helper evaluates

```text
q = RN_p(xy)
t = RN_p(q + sv)
e = FMA(x, y, -q) = xy - q
h = RN_p(t + e)
o = RN_p(wh).
```

The real component uses `(x, y, s, v, w) = (a, a, -3b, b, a)`. The imaginary component uses `(3a, a, -b, b, b)`. Multiplication by three is exact at 39 digits
because a 34-digit decimal multiplied by three has at most 35 significant digits.

The exact first product has at most 68 significant digits for `a^2` and at most 69 for `3a^2`. Its residual after 39-digit rounding has at most 30 significant digits,
so the fused multiply-add computes `e` exactly.

This is Kahan's compensated sum-of-two-products algorithm. For even radix, half-even rounding and no work-context range loss, Jeannerod, Kornerup, Louvet and Muller
establish the sharp bound in [Error bounds on complex floating-point multiplication with an FMA](https://doi.org/10.1090/mcom/3123):

```text
|h - H| <= 2 u_p |H|,       u_p = 0.5 * 10^(1-p).
```

The final multiplication gives

```text
|o - wH| <= ((1 + 2u_p)(1 + u_p) - 1) |wH|
           = (3u_p + 2u_p^2) |wH|.
```

At 39 digits this is

```text
|computed component - exact component|
  <= (1.5E-38 + 5E-77) |exact component|.
```

The same componentwise bound applies independently to the real and imaginary components, and therefore also gives the complex norm bound. Severe cancellation does
not introduce the magnitudes of the two cubic terms into the result error.

## Exact zero and signed zero

For finite decimal inputs, a non-axis exact component zero would require the rational number `a/b` or `b/a` to equal `sqrt(3)`. This is impossible, so finite exact
component zeros occur only when `a` or `b` is zero. The outer multiplication then produces exact zero. The helper normalises such exact results to positive zero,
matching the previous public result for signed-zero inputs.

Non-zero work results which underflow during decimal128 conversion retain their sign while `SPCRES` is enabled. For example,

```text
(1E-6176 + i*1E-6176)^3 = -2E-18528 + i*2E-18528.
```

Nearest rounding returns `-0 + i*0`; the test extracts and inverts the real component to distinguish negative zero. Round-away returns
`-1E-6176 + i*1E-6176`. With `SPCRES` disabled, the common result adjustment normalises zero signs.

## Exponent range

The 39-digit work contexts use exponent limits of `+/-999999`. Decimal128 components range from `1E-6176` to
`9.999999999999999999999999999999999E+6144`. The factor-of-three operations reach adjusted exponent `6145`, the quadratic factors reach at most `12290`, and the
final components reach at most `18435`. At the lower end, a non-zero exact cubic component has exponent no smaller than `-18528`. Every finite intermediate therefore
fits in `ctxtReal39`.

The decimal128 range attached to `ctxtReal34` is too narrow for intermediate work. Minimum components underflow during the quadratic products. At the maximum input,
even the exact multiplication by three overflows before cancellation or the final user rounding can occur. The focused maximum-axis case returns NaN in both
components with the 34-digit work context instead of `infinity + i*0`.

## Final 34-digit rounding modes

The 39-digit contexts use half-even rounding. Only `ctxtReal34` tracks the selected user mode, so conversion applies half-even, half-up, half-down, up, down, ceiling
or floor to both work components. Since `u_34 = 5E-34`, the specialised kernel's relative work bound is about `3E-5` of the normal 34-digit unit roundoff.

A work perturbation can affect the final result when the exact component is correspondingly close to a 34-digit rounding boundary. Differences confined to those
accepted 39-to-34 boundary intervals are outside this analysis. Outside those intervals, the guard margin gives the directly rounded result under every user mode.

No finite relative guarantee exists after conversion near decimal128 zero. Nearest modes have absolute conversion error at most `0.5E-6176`; directed modes have
absolute conversion error below `1E-6176`. The signed-zero behaviour above applies when a non-zero component rounds to zero.

## Why 34 digits are insufficient

At 34 digits the finite bound is

```text
3u_34 + 2u_34^2 = 1.5E-33 + 5E-67.
```

This exceeds the `5E-34` unit roundoff needed for a 34-digit result. The bound also assumes nearest internal arithmetic, while `ctxtReal34` changes with the selected
user mode.

An independently constructed input demonstrates the finite loss:

```text
a = -9704585694022689733994089016212657
b =  6702519828487395378709892791535883

R = 393931770830602896535997368384389121999885871128511502563863387156224713815403288091820125422484123626
I = 1592607039914353045218126363354619050127863922114418392952970261102301118498647937956429439650704404814
```

The half-even 34-digit real component is `3.939317708306028965359973683843891E+101`. Running the specialised kernel at `ctxtReal34` instead returns
`3.939317708306028965359973683843892E+101`, one ulp high. Exact scaled-residual cases fail under every one of the seven user modes; down and floor also misround the
imaginary component.

## Special values and tests

Any NaN component produces NaN in both result components. An infinite input uses the existing eight-sector direction representation. If its sector is `k`, cubing
selects sector `3k mod 8` without arithmetic on infinity. The focused cases cover positive and negative axes and diagonals.

`cube.txt` checks full 34-digit results under all seven rounding modes, the Pell cancellation case, exact and signed zeros, minimum and maximum decimal128 exponents,
underflow and overflow, and NaN and infinity directions. The former two-multiplication route fails the Pell case, leaving a real residual of about `-3.58E+60` after
subtraction. Temporarily selecting `ctxtReal34` makes thirteen of the 67 focused checks fail: all seven mode cases, four minimum-exponent checks and two
maximum-exponent checks.

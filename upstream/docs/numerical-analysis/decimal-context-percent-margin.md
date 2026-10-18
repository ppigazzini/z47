# Decimal context analysis for margin percentage

## Scope

This analysis covers `fnPercentPlusMG`, which evaluates

```
f(x,y) = y / (1 - x/100).
```

The former public call supplied `ctxtReal34` to all three operations.

## Error analysis

For a finite real34 `x`, division by 100 changes only its decimal exponent and
is exact.  Let `t=x/100` and `d=1-t`.  When positive `t` is close enough to one
for cancellation to be severe, subtraction is exact because the two operands
are within a factor of two.  In the other finite cases a correctly rounded
subtraction gives

```
d_hat = d * (1 + delta1),  |delta1| <= u.
```

The final correctly rounded division contributes a second factor with
absolute relative value at most `u`.  Away from an exact zero denominator,

```
|f_hat - f| / |f| <= (2*u + u^2) / (1-u).
```

At 39 digits this is less than `1.01E-38`, leaving almost five decimal guard
digits before conversion to real34.  At 34 digits the bound is slightly above
`1E-33` and does not retain a complete 34-digit margin.

The analysis above assumes exact Real34 inputs. For a wider LongInteger, even
p75 conversion can discard digits needed by the Real34 result. When either
scalar input is a LongInteger, the revised route evaluates the equivalent
ratio `100*y/(100-x)` with exact integer coefficients and decimal exponents,
then rounds only the quotient to Real34. The ordinary Real34 route retains its
p39 two-operation chain.

## Direct 34-digit counterexample

For

```
x = 8.474129809663119388084267268E-7
y = 87294111.12200914204267302038
```

an independent 150-digit decimal evaluation gives

```
f(x,y) =
87294111.8617507775784021896271905822660366238315378976932742412194113676246683972523161509979518952706604765358189060925213977105085603091187674510400
```

The correctly rounded real34 value is

```
87294111.86175077757840218962719058
```

The p34 three-operation route returns the adjacent value ending in `059`.
This difference occurs before any 39-to-34 conversion and is therefore not the
accepted double-rounding case.

The file-driven regression subtracts the independent real34 result.  It
produces `-1E-26` with p34 and zero with p39, so the general relative tolerance
cannot hide the final-digit defect.

## Decision

Use `ctxtReal39` in the public `percentPlusMGReal` call.  The zero-denominator
and special-result branches are selected before the arithmetic and are not
changed.

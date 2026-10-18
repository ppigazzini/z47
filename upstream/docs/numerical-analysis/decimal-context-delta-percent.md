# Decimal context analysis for delta percentage

## Scope

This analysis covers the real arithmetic and public type dispatch through
`fnDeltaPercent` and `deltaPercentReal`:

```
f(x,y) = 100 * (x-y) / y.
```

Statistics-based mean-relative variants, margin percentage and mean rate of
return are separate audits.

`fnDeltaPercent` uses `getRegisterAsReal` for both arguments.  A complex scalar
with a zero imaginary component is accepted exactly as a real value.  A
non-real complex scalar and either matrix type produce the established
invalid-data error before arithmetic or stack mutation.  The command has no
complex-valued or matrix arithmetic route and therefore no context decision for
those types.

## Error analysis

Let `u = 0.5 * 10^(1-p)` for any of the three nearest modes in a p-digit
working context.  In any of the four directed modes use `u = 10^(1-p)`.  When
same-sign `x` and `y` are within a factor of two, their difference is exact,
including the severe-cancellation region.  Otherwise the correctly rounded
subtraction gives

```
d_hat = (x-y) * (1 + delta1),  |delta1| <= u.
```

The correctly rounded division contributes a second relative error bounded by
`u`.  Multiplication by 100 is an exact decimal exponent adjustment.  For a
finite non-zero result,

```
|f_hat-f| / |f| <= 2*u + u^2.
```

At p39 this is less than `1.01E-38` in nearest modes and less than `2.01E-38`
in directed modes.  This retains more than four decimal guard digits before
conversion to real34.  At p34 the nearest-mode bound is slightly above
`1E-33`, which does not retain a complete 34-digit margin.

The p39 exponent range also contains every finite intermediate exponent for
real34 inputs.  A non-zero real34 operand has exponent at least `-6176`, and a
ratio of finite real34 values needs an exponent magnitude below 12322 after
the exact factor of 100.  The final conversion applies real34 overflow and
subnormal semantics.

This subtraction and division form is preferable to `x/y-1`: subtraction is
exact in the cancellation region, while dividing first would discard the
small change when `x` and `y` are close.  The two dependent operations remain
at p39.  Chaining them at p34 is both inaccurate by the counterexample below
and can add real34 conversion work; p34 has no speed rationale here.

The bound above assumes exact Real34 inputs. A wider LongInteger can lose the
small difference during conversion even at p75. When either scalar operand is
a LongInteger, the revised route aligns the integer coefficients exactly,
forms `x-y`, applies the factor of 100 as an exponent adjustment, and performs
one correctly rounded Real34 division. This avoids both the information loss
and a chain of p34 operations.

## Direct 34-digit counterexample

For

```
x = 0.001000000000000000000000000000000001
y = 0.01100000000000000000000000000000001
```

an independent 160-digit decimal evaluation gives

```
f(x,y) =
-90.90909090909090909090909090909090826446280991735537190082644628099248685199098422238918106686701727955740728092343419165357557543883676599338097869618940584039
```

The correctly rounded real34 result ends in `091`; sequential p34 subtraction
and division instead end in `092`.  This is an intermediate-subtraction error,
not an accepted 39-to-34 conversion difference.

The file-driven case subtracts the independently computed result and scales
the residual by `1E40`.  A p34 implementation produces `1E8`; p39 produces
zero.

## Decision

Keep `ctxtReal39` in `fnDeltaPercent`.  Wider contexts do not improve the
real34 result model, while p34 is demonstrably insufficient for the
two-operation route.

With special results disabled, a zero baseline remains a domain error.  With
special results enabled, zero divided by zero and NaN divided by zero produce
NaN.  For non-zero `x` and signed-zero `y`, the numerator `x-y` has the sign of
`x`, so the infinity sign is `sign(x) XOR sign(y)`.  These results do not depend
on coefficient width.  Other NaNs and infinities use the subtraction and
division wrapper semantics.

# Decimal context analysis for real cube

## Scope

This analysis covers `cubeReal`, which returns a real34 result from a real34
input.  Integer, complex and matrix cubes are separate routes.

The implementation evaluates two multiplications in `ctxtReal39`:

```
p = RN39(x * x)
r = RN39(p * x)
```

and then converts `r` to real34.

## Error bound

For the 39-digit nearest-mode working context, let
`u = 0.5 * 10^(1-39) = 5E-39`.  When the exact result is finite and non-zero,
the standard model for the two correctly rounded multiplications gives

```
r = x^3 * (1 + delta1) * (1 + delta2)
|delta1| <= u
|delta2| <= u
```

and hence

```
|r - x^3| / |x^3| <= 2*u + u^2 < 1.01E-38.
```

This leaves almost five decimal guard digits before conversion to real34.
Repeating the calculation at 34 digits gives a bound slightly above `1E-33`,
which does not retain a complete 34-digit margin.

Finite real34 inputs can create intermediate squares outside the real34
exponent range even though `ctxtReal39` represents them.  The wide exponent
range also ensures that the final real34 conversion, rather than an
intermediate operation, determines overflow and underflow.

## Direct 34-digit counterexample

For the real34 input

```
x = 8.565638630558039871615400054
```

an independent 140-digit integer-decimal evaluation gives

```
x^3 =
628.462320933337621703536371996956985741070536339771157034267864308090576811519357464
```

The correctly rounded real34 value is

```
628.4623209333376217035363719969570
```

Two sequential 34-digit multiplications instead produce

```
628.4623209333376217035363719969569
```

The difference is caused by the rounded intermediate square, not by the
accepted 39-to-34 conversion effect.  The file-driven regression subtracts
the independently computed result from the function result, so a one-ulp
difference cannot be hidden by the general comparison tolerance.

## Decision

Keep `ctxtReal39` for both multiplications in `cubeReal`.  `ctxtReal34` is not
sufficient for the existing two-step algorithm, while `ctxtReal51` and
`ctxtReal75` provide unused digits for a real34 result.

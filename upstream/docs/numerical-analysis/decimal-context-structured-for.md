# Decimal context analysis for structured FOR

This analysis covers the numeric counter operations used by `FOR`, `FORTOP`,
and `NEXT` in `src/c47/programming/structured.c`. Program expressions and the
general dyadic arithmetic handlers are outside this narrow audit.

## Counter updates

`NEXT` applies the existing public addition handler to the saved counter and
step. A Real34 result is therefore one selected-mode p34 operation. Such a
single operation is cost-neutral relative to p39 and is the required public
Real34 result. No dependent p34 arithmetic was introduced.

The implementation then compares the updated counter with its saved copy. For
a complex counter, equality is an exact comparison of the two Real34
components. Subtracting components at p39 was unnecessary: equality does not
need a rounded arithmetic result. Direct comparison also gives explicit
unordered behaviour for NaNs.

## Complex end classification

When any of the counter, end, or step is complex, the documented iteration
order is distance from the origin. The top check therefore compares

```
counter_re^2 + counter_im^2
```

with the corresponding squared length of the end value.

Each component is a Real34 number. A finite square has at most 68 coefficient
digits, and adding two nonnegative squares needs at most 69 coefficient digits.
The p75 context represents both products and their sum exactly. Its exponent
range also contains every square of a finite Real34 input. The final comparison
is exact and independent of the selected result-rounding mode.

P51 is insufficient for the full input set. For example,

```
counter = 1 + i 1E-34
end     = 1 + i 0
```

has squared lengths `1 + 1E-68` and `1`. Both p39 and p51 round the first value
to `1`, changing whether the body executes. P75 retains the nonzero term and is
the narrowest established project context among p34, p39, p51, and p75.

This is a discrete control-flow decision rather than a Real34 result, so the
accepted p39-to-p34 final-conversion boundary does not apply. Narrowing this
chain to p34 would also provide no performance gain: dependent p34 work can add
Real34 unpacking and packing, while still losing the deciding term.

## Other counter types and special values

Real and integer counters use the existing exact register comparison. Short
and long integer arithmetic is outside this audit. If a counter or end cannot
be read as a numeric value, the iteration terminates. NaN squared lengths are
unordered, so they do not classify as greater. This retains the existing
special-value behaviour.

## Verification

The file-driven `program_flow_cov.txt` case constructs the p51 discriminator
above and counts body executions. The earlier p39 implementation completed
seven of eight focused checks: the new case produced one execution instead of
zero. The p75 squared-length comparison completes all eight checks. The case
uses the existing program-flow fixture and adds no auxiliary test script.

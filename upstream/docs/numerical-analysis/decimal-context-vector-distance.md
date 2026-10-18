# Decimal context analysis for matrix vector distance

## Scope

This analysis covers the real, complex and mixed-matrix routes selected by `fnVectorDist`.  Equally shaped matrices use the direct distance kernel described here.
The existing subtraction-then-norm dispatch remains in use when either operand is not a matrix, preserving its scalar-broadcast behaviour.

The selected matrix kernel uses p39 from component subtraction through the closing multiplication, followed by one Real34 result conversion.  P39 is the narrowest
suitable established context among p34, p39, p51 and p75.

## Scaled algorithm

For exact Real34 matrix components, the kernel computes each real or complex difference at p39.  Let `d_j` be the magnitude of difference `j` and
`M=max(d_j)`.  The distance is evaluated as

```text
M * sqrt(sum((d_j/M)^2)).
```

Two readings of the input avoid a temporary difference matrix.  The first obtains `M`; the second forms the fused non-negative sum.  Every finite ratio is in `[0,1]`,
the sum is in `[1,n]`, and the final multiplication is the first operation which returns to the input scale.  The p39 exponent range therefore contains every finite
intermediate formed from Real34 components.

The direct kernel also avoids conversion of every component difference to and from Real34.  A single p34 operation is cost-neutral relative to p39.  This route is a
chained calculation, however, and repeated p34 packing and unpacking has no performance benefit and can add work.

## Error bound

Let `u=5E-39` for p39 half-even arithmetic and let `n<=16384`, the maximum real-matrix element count.  A nonzero real component difference is correctly rounded with
relative error at most `u`.  For a complex difference, the two component errors feed the p39 magnitude with condition number one.  Including its multiply, fused
addition and square root gives the conservative relative bound `4u` for each nonzero `d_j`.

The selected scale is one computed magnitude and introduces no extra arithmetic.  A scaled ratio has relative error below `9u`, including numerator, denominator and
division error.  Squaring doubles that contribution.  The fused non-negative sum contributes

```text
gamma_16384 < 8.20E-35.
```

The square root halves the relative sum error.  Its rounding, the scale error and the final p39 multiplication add less than `15u`.  The resulting p39 relative work
error is therefore below

```text
gamma_16384/2 + 15u < 4.11E-35.
```

This supports faithful 34-digit accuracy.  It is not a universal correct-rounding claim, and differences caused solely by the final p39-to-p34 shortening are excluded
under the requested double-rounding policy.  The bound concerns arithmetic error for exact Real34 operands; the mathematical distance can remain sensitive to changes
in nearly equal input data.

## Why p34 is unsuitable

The former matrix route first stored `Y-X` as a Real34 matrix, then unpacked it for a p39 norm.  For

```text
Y = [1, 0.5146678535507867701783243552272027]
X = [-1E-34, 0],
```

the exact first difference is `1+1E-34`.  P34 half-even subtraction stores one and loses the positive correction.  Independent 180-digit decimal evaluation gives

```text
sqrt((1+1E-34)^2 + 0.5146678535507867701783243552272027^2)
= 1.124670173641398786712973008083581555388936083944272078087428...
```

The correct Real34 half-even result ends in `...3582`; the intermediate-p34 route ends in `...3581`.  Directed p34 subtraction can move the first difference by one
Real34 unit and makes the final distance one unit too high.  File-driven checks expose the defect in rounding modes 0, 1, 2, 3 and 5.

Even without this two-element example, a p34 non-negative sum can accumulate `gamma_16384/2` near `4.10E-30` after the square root.  P34 has no 34-digit margin for the
chained calculation.  P51 and p75 reduce an already sufficient p39 bound without improving the public Real34 result.

## Special values and verification

A NaN component difference produces NaN.  Equal infinities are indeterminate; a finite/infinite difference has infinite distance.  An exact zero distance is positive
zero.  Real, complex and mixed matrices use the same scaled kernel, and a shape mismatch reports the existing matrix error.

The initial focused reading with the seven full-digit cases succeeded for 92 of 97 checks; the five failures are the expected p34-intermediate defects.  The selected
kernel succeeds for all 104 expanded checks in `matrixops_cov.txt`.  The expanded cases also cover mixed matrix types, scalar broadcasting, equal-element-count shape
mismatch, NaN and infinity.

The simulator, invoked by the public catalogue name, returns

```text
1.124670173641398786712973008083582
```

for the half-even adversarial input.  No plotting source or native floating-point arithmetic is changed.

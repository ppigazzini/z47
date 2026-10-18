# Decimal context analysis for the arithmetic-geometric mean

## Result

The public arithmetic-geometric mean uses these contexts:

| Calculation | Selected context | Reason |
| --- | ---: | --- |
| finite positive real operands | 39 | at most 22 stable iterations plus the `1e-37` termination threshold retain approximately three decimal guard digits |
| finite complex operands | 75 | complex product cancellation and square-root branch selection do not have the positive-real enclosure property |
| real matrix elements | 39 | each element uses the public positive-real kernel |
| complex matrix elements | 75 | each element uses the public complex kernel |

The real route narrows from 75 to 39 digits. The complex route remains at 75 digits. Internal AGM helpers used by elliptic calculations continue to use the context selected by their enclosing algorithm.

The fixed contexts use round-to-nearest, ties-to-even. The user-selected mode is applied when the working result is converted to decimal128. Differences caused only by the final 39-to-34-digit conversion are excluded as requested.

## Positive real iteration

For positive `a` and `b`, one iteration is

```text
a' = (a+b)/2
b' = sqrt(a*b).
```

The exact sequences converge monotonically to the common arithmetic-geometric mean. The mean is homogeneous and increasing in each positive operand. If both inputs to an exact iteration have relative perturbations bounded by `epsilon`, homogeneity and monotonicity bound the resulting mean by the same `epsilon`.

Let `u` be the working unit roundoff. The rounded addition and multiplication by one half perturb `a'` by less than `2u+u^2`. The product for `b'` contributes at most `u`; propagation through the exact square root contributes less than `u/(1+sqrt(1-u))`, and square-root rounding contributes at most `u`. Including their products gives a conservative bound below `1.51u` for `b'`. Thus one iteration perturbs either member by less than `2.01u`.

The decimal128 input ratio cannot exceed approximately `1e12321`. Write `r=max(a,b)/min(a,b)`. The exact ratio after one iteration is

```text
r' = (r+1)/(2*sqrt(r)) <= sqrt(r).
```

After 14 iterations, `r<5.7`. With `e=r-1`,

```text
e' = (sqrt(r)-1)^2/(2*sqrt(r)) <= e^2/8.
```

Eight further iterations put `e` below `1e-37`. Thus 22 is a conservative finite-input bound. A direct high-precision evaluation of the minimum-positive and maximum-finite decimal128 pair reaches the implemented criterion in 19 iterations.

At precision 39, `u39=5e-39`. Accumulating 22 perturbations of at most `2.01u39`, with second-order terms, contributes less than `2.3e-37` relative error. When the implemented relative difference falls below `tau=1e-37`, the exact mean of the final pair lies between its two members and differs from the returned arithmetic member by less than `tau`. The total working error is therefore below approximately `3.3e-37`, leaving approximately three digits beyond decimal128.

The 75-digit context cannot materially improve the public result because the fixed termination criterion already limits the final pair to a relative separation near `1e-37`. Precision 39 is the narrowest established project context that keeps its arithmetic noise below this criterion.

## Why precision 34 is unsuitable

At precision 34, one rounding can contribute `5e-34`, already far above the `1e-37` convergence test. A deliberate precision-34 build enters a rounded cycle for the stored discriminator and does not complete. It also overflows the first product for two large finite decimal128 operands even when their AGM is a valid finite decimal128 number.

The finite range case is

```text
a = 9.999999999999999999999999999999999e6144
b = 8e6144
AGM(a,b) = 8.9721143211504102805112087713162656884...e6144.
```

The precision-39 exponent range retains the product and produces the expected rounded result. The exact digit discriminator

```text
a = 4.482641554400924039604901399e82
b = 7.153175982084252549634178599e37
AGM(a,b) = 6.7358282437728773155295804232905399215...e80
```

is checked in all seven output modes by subtraction and scaling. An independent precision-34 simulation gives a result five decimal128 units above the nearest-even reference. The calculator mutation does not complete because its rounded state cycles. Precision 39 succeeds in every output mode.

## Complex route

The complex iteration uses the same arithmetic mean and a selected square root of the complex product. It chooses between the two roots from the input and candidate arguments. Unlike the positive-real iteration, neither component encloses the limit, and component cancellation does not have a uniform relative bound.

The first product of decimal128 complex components can expose as many as 68 coefficient digits. Later iterations operate on wide components, and their real or imaginary products can cancel before the root selection. A 39- or 51-digit replacement lacks a global argument-separation bound near a root-choice boundary. Precision 75 retains every first-iteration decimal128 product and supplies 41 guard digits for later component cancellation. It remains the narrowest context with an established implementation-level justification for this branch-sensitive route.

This is a normwise accuracy decision. No fixed context can give a uniform componentwise relative guarantee when an exact component approaches zero or when the input approaches a square-root branch boundary.

## Zero, NaN and infinity

Zero is absorbing for the real AGM, including a zero paired with positive infinity. Opposite finite real values with equal magnitude also retain the existing zero result. NaN now has priority over these shortcuts and propagates instead of becoming zero.

Nonfinite inputs no longer enter the iterative kernels. A positive real infinity paired with a positive nonzero real returns positive infinity when special results are enabled and reports a domain error otherwise. For complex inputs, nonnegative real-axis infinities follow the same zero or positive-infinity limits. An infinite input in any other complex direction returns `NaN+iNaN`, because decimal infinity does not retain the component ratio needed to select a finite direction. Any complex NaN returns `NaN+iNaN`.

These guards also prevent the former unbounded evaluation of positive infinity, complex infinity and NaN.

## Verification

The existing `agm.txt` file now contains 61 checks. The selected real39 and complex75 contexts succeed for all 61 with no GMP-owned bytes at exit. The new cases include all seven output rounding modes, a finite result whose first precision-34 product overflows, scalar and complex NaNs, positive infinities, zero paired with infinity, and an infinite off-axis complex value.

The unmodified nonfinite route cannot complete the added infinity cases. The selected guards resolve them before the iterative kernel. The deliberate precision-34 finite build also cannot complete the stored digit discriminator because its convergence threshold is three orders below its arithmetic resolution.

A clean repository run succeeds for all 15,465 cases with zero failures and no GMP-owned bytes at exit. Compilation emits no changed-source diagnostic; the existing Mach-O section-alignment warning remains.

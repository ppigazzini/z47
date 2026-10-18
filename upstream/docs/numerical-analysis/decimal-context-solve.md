# Programmable real equation-solver decimal contexts

## Scope and result

This audit covers `solver()` in `src/c47/solver/solve.c`, its interpolation
helpers, the scalar evaluator in `src/c47/solver/equation.c`, formula and
program evaluation, and the directly coupled TVM caller. The complex root
algorithm and the separate closed-form solvers are outside this audit.

The programmable route now uses a sign bracket as its numerical certificate.
A residual is accepted as a root only when the Real34 user calculation returns
exact zero. The position target is `1e-37` at p39 for a full-precision request.
Lower `SD` settings retain their requested decimal target. Graph and TVM calls
retain their application-specific residual and position tolerances.

The result is a faithful Real34 root of the sampled user calculation. Universal
correct rounding of the mathematical root is not claimed: each programmable
trial is converted to Real34 before the formula or program is executed, and its
result is converted back from Real34. Distinct mathematical roots within one
such input or output quantisation cell cannot be distinguished. Differences
caused only by the accepted p39-to-Real34 conversion are outside this audit.

| Route | Work context | Function evaluation | Position target |
| --- | ---: | ---: | ---: |
| formula or RPN program, full precision | p39 | Real34 | `1e-37` relative |
| formula or RPN program, reduced `SD` | p39 | Real34 | `10^-SD` relative |
| equation token or intermediate | Real34 | selected result mode | not applicable |
| graph accuracy | p39 storage, reduced evaluation context | graph setting | graph setting |
| TVM | p39 solver arithmetic; p51/p75 within TVM formulae | extended real | established TVM setting |
| returned calculator value | Real34 | selected result mode | not applicable |

The heap buffers remain sized for 75 digits because the TVM route writes
extended results through the same objects. Buffer capacity is not the selected
arithmetic precision.

## Why p39 is retained

Two Real34 endpoints can require 35 significant digits in their exact sum.
Consequently a p34 midpoint can round before division by two and can coincide
with an endpoint before the internal bracket has adequate resolution. P39
represents that sum with four spare digits and supports the `1e-37` position
test. P34 therefore has no demonstrated margin for a 34-digit result. A single
p34 operation is cost-neutral, but the solver is a dependent arithmetic chain,
so p34 is neither an accuracy choice nor a speed optimisation here. The
equation evaluator retains p34 because each token result is a public Real34
calculator operation, not for performance.

For finite Real34 inputs and function values, the largest adjusted exponent of
a difference is about 6145, a secant product about 12290, and the products in
inverse quadratic interpolation about 18435. These are far inside the p39
context exponent range of plus or minus 999999. P51 does not recover
information lost when a trial and its result are converted through Real34, so
it has no established accuracy benefit for the programmable route.

Subtractive cancellation can make a secant or inverse-quadratic proposal
poorly conditioned. The proposal is now accepted only if it is strictly inside
the current sign bracket and its displacement is less than half the preceding
endpoint displacement. Otherwise the p39 midpoint is used. Thus interpolation
error affects speed, not the bracket certificate. The former first comparison
used a work value initialised to zero and never changed, so it supplied no
safeguard.

All extended solver operations use round-to-nearest, ties-to-even. The selected
one of seven calculator modes applies to Real34 trial conversion, execution of
the user calculation, and final conversion. A directed mode can shift the
sampled zero cell by one Real34 unit, which is part of the quantisation limit
above. The bracket and fallback conditions depend on ordering and signs, so
they remain valid for every mode.

## Sign-bracket termination

The interpolation displacement is not a root-error estimate. In particular,
a secant step can be very small when the endpoint residual magnitudes are very
different, even though the root remains far from that endpoint. The previous
position test compared the current best point with the preceding best point.
It could therefore report success while the opposite-sign interval was wide.

The revised programmable route tests the two current opposite-sign endpoints
after the candidate has updated the interval. With

```text
f(x) = (x - 2.1) * exp(44 * (x - 1))
```

and guesses one and three, the first secant displacement is about one p39 unit
because the endpoint residual magnitudes differ by about `1.2e38`. The next
fallback point is two. The former consecutive-point test returned two; the
revised interval test continues to the exact Real34 root 2.1 in every result
mode.

Interpolation cancellation can still delay convergence, but it cannot satisfy
the programmable position criterion. A rejected or repeated proposal selects
the p39 midpoint. The method reports a normal position result only after the
relative width of the sign interval meets its target, or after a Real34 sample
is exactly zero. TVM and graph accuracy keep their established consecutive-
point tests because their residual scales and termination settings are defined
by those applications.

## Position convergence near zero

`WP34S_RelativeError(x,y,tol)` changes to an absolute comparison when `x` is
zero. Calling it with the current best endpoint first therefore made a bracket
such as `[0,1e-2999]` satisfy a `1e-37` test immediately. The revised
programmable route uses the endpoint with larger magnitude as the denominator.
For nonzero scale `m=max(abs(a),abs(b))`, the measured quantity is

```text
abs(a-b)/m.
```

At p39, subtraction and division contribute about two p39 rounding units away
from cancellation. A `1e-37` threshold leaves a decimal margin over that work
error and is three orders below the Real34 relative scale. Exact equality is a
separate termination condition. TVM and graph accuracy retain their previous
zero-relative interpretation because their application tolerances were chosen
for it.

The regression `X^2-1e-6000` with guesses zero and `1e-2999` has the exact
positive root `1e-3000`. Before this change the fixed absolute comparison
returned `0E-71`; the revised sign bracket returns `1e-3000`.

## Residual scaling

An absolute residual threshold cannot certify a root of an arbitrary user
equation. Multiplication of an equation by any finite nonzero constant leaves
its roots unchanged but changes every nonzero residual. For

```text
1e-100 * (X^2 - 2)
```

with guesses one and two, the former `1e-34` residual rule accepted the first
secant proposal, `1.333333333333333333333333333333333`. Requiring an exact
zero residual or position convergence now returns
`1.414213562373095048801688724209698`.

The exact-zero rule is safe under every result mode: it certifies a zero of the
calculation that the calculator executed. It does not imply that an arbitrary
continuous mathematical function is exactly zero there, due to the Real34
evaluation boundary described above. TVM and graph routes preserve their
existing absolute residual rules because those equations have defined scales.
The near-zero TVM constant is now formed from one and a decimal exponent rather
than parsed from a string at run time.

## Initial guesses and special values

The former fixed `1e-32` widening applied to every close pair, including two
distinct Real34 inputs. It also changed the left endpoint without updating the
point associated with its stored function value. This broke both the endpoint
association and narrow brackets at very small exponents. Widening is now
limited to equal guesses, and the associated point is updated with the changed
endpoint. Distinct inputs are retained exactly.

An initial NaN, infinity, or formula-domain failure creates a special function
value. The former path marked a bad guess but continued into interpolation,
where the result could be replaced by the pole error. The revised path returns
the initial-guess domain result immediately. Positive and negative zero compare
equal; the established representable-neighbour search remains in use, and an
exact zero function value terminates successfully.

## Equation evaluation boundary

The equation parser stores at most ten numeric values and ten operators. A
numeric literal is converted directly to Real34, and each monadic or dyadic
item is executed through the normal calculator operation before its Real34
result is returned to the parser stack. The final `right - left` residual for
an equality is also one correctly rounded Real34 subtraction. No wider context
inside `solver()` changes these semantics.

For a well-conditioned chain of `n` basic operations, nearest-mode arithmetic
has the usual first-order error bound of roughly `n * 5e-34`; a directed mode
can contribute up to one Real34 unit per operation. Cancellation can amplify
that bound without limit. For example, `1e34 + 1 - 1e34` evaluates to zero in
nearest mode and ten in round-toward-positive-infinity. This is the calculator
expression the solver samples, rather than an extended-precision expression
tree. Functions invoked by an equation retain their own documented accuracy
and domain limits.

An imaginary NaN is a component of a complex value, not a marker that the
value is real. The former evaluator discarded such a component while preparing
monadic and dyadic operands and while constructing the final result. Thus
`(1 + NaN i) + 2` became the finite real three, and its magnitude became the
finite real one. The evaluator now keeps that operand complex; the invoked
operation propagates the NaN in the normal way.

The left side of an equality is already stored in the parser's private Real34
pair. The former equality action nevertheless tried to convert the unrelated
calculator X register to a real. Consequently `2+3=5` failed when evaluation
began with a matrix in X. Removing that conversion makes the residual depend
only on the expression. End-of-expression processing now also requires exactly
one right-side numeric value. A missing right side and adjacent unconnected
values report the equation syntax error instead of reading outside the active
numeric stack or silently selecting its top value.

## File-driven evidence

`src/testSuite/tests/solve_cov.txt` contains cases for:

- equation-scale invariance;
- a root and bracket near exponent minus 3000;
- a root near exponent plus 3000;
- equal finite guesses;
- NaN and negative-infinite guesses;
- signed-zero guesses;
- a highly skewed residual in all seven result modes; and
- a non-root local minimum.

`src/testSuite/tests/eq_cov.txt` also covers Real34 chained rounding, an
incoming matrix at an equality, complex imaginary NaNs through monadic,
dyadic and equality paths, and malformed final numeric-stack counts.

On the pre-change source the scale case returned `1.333333333333333333333333333333333`,
the tiny-root case returned `0E-71`, and both invalid guesses reported the pole
error 41 rather than the domain error 43. Reinstating only the consecutive-point
termination makes 40 of the final 47 equation and solver checks successful; the
seven skewed-residual mode cases all return two. Before the evaluator repairs,
20 of its 26 then-current checks were successful: the incoming-matrix case,
three NaN-component cases, and both malformed expressions failed. The focused
solver, equation, equation-dispatch, TVM and program-solver set is successful
for all 250 checks with the revised source.

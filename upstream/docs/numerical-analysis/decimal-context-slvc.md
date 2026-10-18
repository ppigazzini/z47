# Decimal-context analysis for `SLVC`

## Scope and result

`SLVC` accepts four scalar coefficients or a Real34/Complex34 coefficient vector. The vector form also redirects two entries to a linear equation and three entries to the shared quadratic solver. This audit does not alter matrix storage, eigenvalue code, `SLVQ`, or the iterative solvers.

The selected working contexts are:

| Route | Context | Reason |
| --- | ---: | --- |
| real linear vector | 39 digits | one correctly rounded division; five guard digits before Real34 conversion |
| complex linear vector | 75 digits | each quotient component may subtract two products of 34-digit inputs |
| quadratic or cubic with zero constant | 75 digits | the shared stable quadratic formula needs more than 51 digits at a repeated root |
| general cubic | 159 digits | triple-root conditioning divides the effective digit count by three |
| root sorting | 39 digits | ordering does not alter a root, and distinguishable Real34 magnitudes remain distinguishable at p39 |

Working arithmetic uses half-even rounding. The final scalar or matrix conversion uses `ctxtReal34`, so all seven user rounding modes apply to every stored component. Differences caused solely by p39-to-p34 double rounding are outside this audit.

## Linear routes

For real coefficients, the root is `-b/a`. A correctly rounded p39 division has relative error at most `u39 = 0.5e-38` for a normal result. This leaves five decimal guard digits for Real34. Subnormal rounding occurs only at the Real34 conversion, whose active user mode supplies the required direction.

For complex coefficients, the integrated scaled complex-division kernel avoids avoidable overflow and underflow. Its component numerators contain sums or differences of products. Two Real34 factors can require 68 significant digits before cancellation, so p39 and p51 are not sufficient for a componentwise guarantee. The retained p75 route accommodates those exact products and seven further digits.

## Quadratic dependency

The quadratic solver uses a stable first root and obtains the second through Vieta's product. Its discriminant starts with exact products of Real34 coefficients at p75. Near a repeated root, a discriminant error of order `u75` gives a root perturbation of order `sqrt(u75)`, about 37.5 reliable decimal digits. Thus p75 provides a Real34 margin, while p51 would provide only about 25.5 digits. A cubic with an exact zero constant is now factored as `x(ax^2+bx+c)`, which gives an exact zero and avoids unnecessary cubic work.

## Cubic conditioning and normalisation

For a simple root `r`, the first-order sensitivity is

`delta r = -delta p(r) / p'(r)`.

No internal context can remove conditioning already present in the supplied coefficients. Internal round-off must nevertheless remain below that input uncertainty. At a root of multiplicity `m`, an arithmetic perturbation `epsilon` can become `O(epsilon^(1/m))`. A cubic therefore needs at least 102 working digits to retain 34 root digits at a triple root. The established p159 kernel gives about 53 digits in this worst case, while p75 gives only about 25.

Previously, `b/a`, `c/a`, and `d/a` were rounded at p75 before entry to the p159 kernel. For

`343x^3 - 147x^2 + 21x - 1 = (7x-1)^3`,

that early rounding produced a conjugate pair with imaginary magnitude `1.3905780605393656e-26`. Normalisation now occurs inside the p159 allocation. All finite Real34 coefficient ratios and the degree-six Cardano intermediates remain far inside the extended `+/-999999` exponent limits.

The Real34-origin coefficients are copied exactly into their p159
temporaries. Applying a p159 unary rounding operation to each source value
was redundant and has been removed. The later divisions and cubic work remain
at p159, and the computed roots still receive their established p39 rounding.

For real coefficients, the homogeneous discriminant

`D = b^2 c^2 - 4ac^3 - 4b^3d - 27a^2d^2 + 18abcd`

is evaluated from the original coefficients at p159. Each degree-four product has at most 138 significant digits before summation. Four rounded additions give an absolute error below a small multiple of `u159` times the sum of term magnitudes. A negative value within `1e-150` of that sum is treated as unresolved. Even cubic-root amplification then leaves roughly 50 digits, so the affected complex separation is below Real34 resolution. A positive or unresolved discriminant permits all imaginary components to be set to exact zero. A clearly negative discriminant retains the conjugate pair.

The former root-type test inspected the imaginary component of `q^3+r^2` instead of its real component. Signed zero sometimes concealed the error. The p75 fallback now inspects the real component; the p159 route uses the homogeneous test above.

## Roots with widely separated magnitudes

Direct Cardano reconstruction forms two roots by subtracting quantities on the scale of the largest root. At p159 this still fails when root exponents differ by thousands. For

`x^3 - 1e6000 x^2 + 1e6000 x - 1`,

the former result was `1e6000` and two values near `4.605e5844`; the Real34 roots are `1e6000`, `1`, and `1e-6000`.

The revised route selects the largest-magnitude Cardano root `r`, then deflates through

`v = -d/r`,

`u = (v-c)/r`,

so that the other roots solve `x^2+ux+v=0`. This form avoids `u=b+r`, whose cancellation can span the full input exponent range. The residual quadratic chooses the larger of `-u+sqrt(u^2-4v)` and `-u-sqrt(u^2-4v)`, halves it, and obtains the companion root from `v/q`. The selected cubic root is then reconstructed from the sum identity. All these operations remain at p159.

The old absolute rule that erased every imaginary component with adjusted exponent below `-159` was invalid because root scale was absent. For `x^3+1e-600`, it erased the genuine pair

`5e-201 +/- 8.660254037844386467637231707529362e-201 i`.

That rule has been removed. Structural real-root classification is used instead.

## Domain and special values

An all-zero leading part still reports a domain error, and an invalid coefficient type leaves the stack unchanged. A zero cubic leading coefficient redirects to the quadratic route and supplies a NaN third root. Decimal NaNs and infinities continue through the arithmetic helpers and the existing result-adjustment policy. Signed zero in the constant term selects exact factorisation; its zero root remains exact after sorting and Real34 conversion.

## Regression evidence

The file-driven `slvc.txt` cases cover exact zero factors, an exact triple root, genuine small complex pairs, full-range separated roots, a non-terminating real linear quotient, and scalar/vector dispatch. Before this change, the zero-factor cases contained `1e-159` artefacts, the triple-root case acquired an imaginary component, the small pair became real, and the separated roots were wrong by thousands of decimal exponents.

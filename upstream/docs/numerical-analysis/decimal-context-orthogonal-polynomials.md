# Decimal context analysis for orthogonal polynomials

## Scope and selected contexts

The public functions `fnLegendre`, `fnLaguerre`, `fnLaguerreAlpha`, `fnHermite`, `fnHermiteP`, `fnChebyshevT`, and `fnChebyshevU` all invoke
`WP34S_OrthoPoly`. They accept a finite real abscissa and a nonnegative integral degree. Generalised Laguerre also requires a finite parameter greater than
minus one.

Degree zero is exact at p34. Degree one also uses p34 for Legendre, ordinary Laguerre, both Hermite forms, and both Chebyshev forms. These results are a copy,
one addition or subtraction, or multiplication by two, so the assumed correctly rounded elementary operation supplies the final decimal128 result directly.
Generalised Laguerre degree one stays at p75 unless its parameter is zero because its three-term sum can expose a small term after cancellation.

Every degree of two or more uses p75. P51 is not sufficient near polynomial zeros. The wider context keeps half-even work rounding; conversion to `real34_t`
applies the selected calculator rounding mode. Differences confined to a p75-to-p34 double-rounding boundary are outside this analysis.

There is no matrix or complex dispatch in this family. `getOrthoPolyParam` reports an invalid-data-type error for either input type. The existing scalar helper is
not applied element by element.

## Recurrences

With degree index `k`, the common helper evaluates these forward recurrences:

| Function | Recurrence |
| --- | --- |
| Chebyshev T | `T[k] = 2*x*T[k-1] - T[k-2]` |
| Chebyshev U | `U[k] = 2*x*U[k-1] - U[k-2]` |
| Legendre | `P[k] = ((2*k-1)*x*P[k-1] - (k-1)*P[k-2])/k` |
| Laguerre | `L[k] = ((2*k-1+alpha-x)*L[k-1] - (k-1+alpha)*L[k-2])/k` |
| Probabilists' Hermite | `He[k] = x*He[k-1] - (k-1)*He[k-2]` |
| Physicists' Hermite | `H[k] = 2*x*H[k-1] - 2*(k-1)*H[k-2]` |

Write a recurrence as

`y[k] = (A[k]*y[k-1] - B[k]*y[k-2])/C[k]`.

For p-digit round-to-nearest arithmetic, `u = 5*10^-p`. If `E[k]` bounds the absolute error in `y[k]`, a first-order forward bound is

`E[k] <= (|A[k]|*E[k-1] + |B[k]|*E[k-2] + coefficient error + gamma(3)*S[k])/|C[k]|`,

where `S[k] = |A[k]*y[k-1]| + |B[k]*y[k-2]|` and `gamma(3) = 3*u/(1-3*u)`. The optional division contributes one further `u*|y[k]|`.
This bound can be accumulated for a fixed input, but no uniform relative bound exists. The local cancellation factor

`(|A[k]*y[k-1]| + |B[k]*y[k-2]|)/|A[k]*y[k-1] - B[k]*y[k-2]|`

is unbounded at a zero. A decimal128 abscissa adjacent to a zero can therefore produce a result around `1e-35` from recurrence terms of order one. Five or
seventeen guard digits cannot then retain 34 significant result digits.

## Width adversaries

The exact value of `T[20](x)` at

`x = 0.7604059656000309381745943648449020`

is obtained by rational coefficient evaluation because the input is an exact decimal rational:

`3.42607647361650514621097586416417112782749810114735865355163673849988557170020585558309856e-36`.

The original p39 calculation differs from the nearest decimal128 result by `-5.923526383494853789024135835829e-39`. Multiplication of that difference by
`1e70` produces the nonzero file-test residual `-5.923526383494853789024135835829e31`. A p51 candidate still differs by
`2.0146210975864164171e-50`; its scaled residual is `2.0146210975864164171e20`. P75 returns the independently computed 34 digits.

Exact rational evaluation gives matching p75 results for decimal128 inputs adjacent to degree-20 zeros of Chebyshev U, Legendre, ordinary Laguerre, and both
Hermite forms. P39 fails every one. P51 also fails every one. The generalised Laguerre degree-40 case

`L[40]^1(144.1888701553949841058681094488866) = 0.002177245014391624803761061727750215...`

has a p51 error of `-1.8738938272249785e-20`; p75 returns all 34 asserted digits. Thus p75 is the narrowest established context that succeeds across the public
degree-two-and-higher routes.

This is a faithful 34-digit result for the tested domain, not a universal correct-rounding claim for an unlimited degree. The recurrence condition can grow without
bound, and the public degree has no configured maximum. Very large degrees can exhaust any fixed number of guard digits before their run time becomes practical.

## Generalised Laguerre degree one

The exact linear polynomial is

`L[1]^alpha(x) = 1 + alpha - x`.

The former order first formed `1 + alpha`. At `alpha = x = 1e100`, both p39 and p75 discard the unit term and return zero instead of one. The revised calculation
forms both `alpha - x` and `1 - x`, then adds the unused term to the difference with smaller magnitude. This chooses `alpha - x + 1` when alpha and x cancel,
and `1 - x + alpha` when one and x cancel. The added regression asserts the exact result one.

## Result rounding and tests

The exact Chebyshev T adversary has nonzero digits after result digit 34. The cases assert all seven calculator rounding modes by exact subtraction followed by
scaling. Modes 0, 1, 2, 4, and 6 return

`3.426076473616505146210975864164171e-36`,

while modes 3 and 5 return

`3.426076473616505146210975864164172e-36`.

The seven existing function-specific files contain the near-zero cases. They also cover the exact generalised-Laguerre cancellation, NaN and infinity behaviour,
and rejection of a real matrix. The focused reading executes 233 checks.

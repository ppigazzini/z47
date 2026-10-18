# Decimal contexts for matrix eigenvalues and eigenvectors

## Scope

This audit covers `fnEigenvalues`, `fnEigenvectors`, their real and complex matrix routes, the finite eigensystem kernels, Householder QR work shared by those routes, and eigenvector normalisation. SVD and the public QR decomposition are separate audits. Matrix square root consumes the eigensystem result but has its own result analysis.

The result types are Real34 and Complex34. A matrix with badly conditioned or defective eigenvalues cannot have a universal 34-digit forward-error guarantee at any fixed work width. The choices below provide ample backward-error margin for well-conditioned finite problems and retain the widest established context on the condition-sensitive routes.

## Context selection

| Route | Context | Reason |
|---|---:|---|
| One by one matrix | Real34 copy | The sole entry is the eigenvalue and the vector is exactly one. |
| Two by two and three by three eigenvalues | p159 coefficient and root work, p75 conversion, one p39 cleanup | Products of Real34 entries can contain 68 digits. Determinant and discriminant subtraction can expose those low digits before the quadratic or cubic root operation. |
| Exact real symmetric matrices larger than three | p75 cyclic Jacobi rotations, one p39 cleanup | Orthogonal rotations give a backward-stable symmetric route and remove dependence on the general QR convergence tests. |
| Other finite matrices larger than three | p75 Householder and matrix products, p51 state reduction, p39 convergence sums and cleanup | p75 protects the inner products; p51 leaves 17 digits above the result width after each QR iteration; p39 is too narrow for repeated state updates. |
| Real and complex eigenvector solve | p75 solve and Euclidean normalisation, p39 eigenvalues | Eigenvector sensitivity contains the inverse spectral separation. Five guard digits in the eigenvalues and 41 work guard digits reduce avoidable amplification. |
| Public result conversion | Real34 or Complex34 | The selected result rounding mode is applied here. The accepted p39 to p34 boundary rule applies. |

A p34 arithmetic step is not used in a work chain. Such a step requires wide-value unpacking and repacking and offers no speed gain over p39. It can also be slower. The former p34 rounding of every eigenvalue before the p75 vector solve discarded useful guard digits and made the solve depend on the selected result mode, so it was removed.

The p159, p75, p51 and p39 work contexts retain their fixed internal rounding. Each of the seven selectable result modes is applied only by the Real34 or Complex34 conversion. Signed zero is untouched by decimal power scaling. A one by one matrix returns its zero, infinity or NaN entry directly and returns the exact vector one. For a larger matrix containing a special component, scaling is disabled and the existing arithmetic propagation remains in effect; the finite-input bounds below do not cover that case.

## Decimal power scaling

The previous absolute tolerances classified

```
1E-100 * tridiagonal(1, 2, 1)
```

as diagonal. It consequently returned four copies of `2E-100`.

For a finite nonzero matrix, let `s = 10^e`, where `e` is the largest adjusted exponent among its real and imaginary components, and let `B = A/s`. Changing the stored decimal exponents computes `B` exactly. The identities

```
lambda(A) = s * lambda(B)
v(A) = v(B)
```

show that all absolute convergence tests may operate on `B`. Adding `e` to each computed eigenvalue exponent is also exact. Zero components, including signed zeros, are unchanged. Special components disable this finite-input argument and are not scaled.

This transformation keeps every threshold relative to the largest input component without introducing an arithmetic rounding point. It also makes the Householder `1E-digits` test meaningful across the Real34 exponent range. That threshold is now formed from an exact one and an exponent change rather than parsing text at run time.

## Real symmetric route

The general QR route returned only about 20 correct digits for the smallest eigenvalue of the scaled four by four Toeplitz matrix. The new exact-real-symmetric route uses stable Jacobi parameters

```
tau = (aqq - app) / (2 apq)
t   = sign(tau) / (abs(tau) + sqrt(1 + tau^2))
c   = 1 / sqrt(1 + t^2)
s   = t c
```

which avoid subtracting two nearly equal values in the rotation parameter. Each algebraic rotation is orthogonal. The iteration stops when every off-diagonal magnitude is below `1E-60 * max(1, max(abs(diagonal)))`.

At termination, write the rotated matrix as `D + E`, with `D` diagonal. The bound

```
norm2(E) <= normF(E) <= sqrt(n * (n - 1)) * max_off_diagonal
```

limits the eigenvalue error caused by the termination test. Symmetric eigenvalues have absolute condition number one. Correctly rounded p75 additions, multiplications, divisions, fused operations and square roots add first-order error proportional to p75 unit roundoff for each rotation. Even the 12-bit dimension field and the configured iteration limit leave more than the required 34-digit margin. Values extremely close to zero can still have poor relative accuracy because the mathematical problem itself is relatively ill-conditioned there.

## General QR route

One QR update contains Householder norms, complex products and matrix inner products. A p34 input product can have 68 significant digits before subtraction. P75 is retained inside each update so cancellation in those products does not discard digits needed by a p34 result. The state is reduced to p51 between updates. With at most 10000 QR iterations, p39 state would provide at most about 31 decimal digits after a first-order `iteration_count * n * u` estimate, before eigenvalue conditioning. P51 keeps roughly twelve or more digits of margin under the same coarse estimate for practical matrix sizes.

P75 is retained rather than p51 for the local products because a nonnormal eigenvalue can amplify a backward perturbation by an arbitrarily large eigenvalue condition number. No fixed context removes that limitation. A deliberate p51 build completed the current matrix cases but took 102 seconds on the 14 by 14 general case, compared with 75 seconds at p75 on the same host. This measurement supplies no performance reason to narrow the route.

The post-QR block threshold divides the diagonal-magnitude sum by `n`; changing its exponent by `n` divided by `10^n`, not by `n`. Its relative factor is `1E-30`. This is separate from the `1E-40` iteration-change threshold: the final scan must recognise the numerically decoupled blocks left by the QR termination rule. A `1E-40` final threshold rejects converged companion matrices after the multiple-block solver changes on master. The `1E-30` threshold still puts second-order effects below the p39 cleanup boundary.

## Eigenvectors

The vector solve uses `(A - lambda I)v = 0`, so an eigenvalue perturbation `delta lambda` can be amplified in proportion to the inverse spectral separation. Eigenvalues used by this solve therefore retain p39. P75 is retained for the augmented solve and for the norm

```
sqrt(sum(real(vj)^2 + imag(vj)^2)).
```

The real route already applied this norm. The complex route omitted it and returned columns of norm `sqrt(2)` for `[[2,i],[-i,2]]`. Both routes now use the same p75 helper.

Defective matrices and nearly defective nonnormal matrices remain conditional limitations. The existing zero-column check rejects some defective cases, while a nonzero pseudo-vector can still evade that check. A residual-based rejection rule needs a separate policy for scaling the residual against both the matrix norm and the eigenvalue condition estimate.

## Regression cases

The file-driven matrix coverage now includes:

* the four by four symmetric Toeplitz spectrum at scales `1E-100` and `1E6000`, with independently derived values `(5 plus or minus sqrt(5))/2` and `(3 plus or minus sqrt(5))/2`;
* the complex Hermitian matrix `[[2,i],[-i,2]]`, whose vector columns have entries of magnitude `1/sqrt(2)`.

Before the source change, the small-scale case returned four copies of `2E-100`, and the complex vector case returned components of magnitude one. The focused file reported 73 successful cases and two failures. With the change, all 76 focused cases succeed.

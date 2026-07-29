Which of the 5 files (PACKAGE 1 ... PACKAGE 4 or dmcp5) do I load?

## Short answer

- **DM42n**: load **dmcp5**
- **Original DM42 (non-n)**: Choose **PACKAGE 1** or **PACKAGE 2** or **PACKAGE 3** or **PACKAGE 4**

## Long answer

On the DM42n there is sufficient flash storage, so there is no package choice to make: all functions are always available.  
**dmcp5** is the full C47 firmware and is the correct and only option. It does not fit on the original DM42.

On the original DM42, flash space is constrained. To make C47 fit, the firmware is built in four mutually exclusive variants:

- **PACKAGE 1** retains all distributions, Bessel and Orthogonal polynomial functions, fast financial functions, ELEC functions and IR printing; omits Elliptic and eigenvalue functions.
- **PACKAGE 2** retains all distributions and the full X.FN menu (Elliptic, Bessel, Orthogonal); financial functions are slower and lower precision; omits eigenvalues, eigenvectors, matrix sqrt, ELEC functions and IR printing.
- **PACKAGE 3** loses some distributions (keeps Normal, StdNormal, LogNormal, gev, Pareto, Uniform, Discrete Uniform); retains Bessel and Orthogonal polynomial functions, fast financial functions, eigenvalues, eigenvectors, matrix sqrt, ELEC functions and IR printing; omits Elliptic functions.
- **PACKAGE 4** has no distributions; omits Elliptic, Bessel and Orthogonal polynomial, eigenvalue and ELEC functions; financial functions are slower and lower precision; includes IR printing.


Apart from these exclusions, the packages are functionally identical. None is “better”; each simply trades one feature set for another to meet the memory limit.

If you have two original DM42 units converted to C47, installing different packages could make sense and effectively gives you access to the complete function set across the two machines.

The precise feature balance may vary slightly between releases as code size fluctuates, but this split is deliberate and should be expected on the original DM42.

## Feature matrix: 2026-07-22

```
Info 2026-07-22 00.109.04.00b0.RC1

   Pkg │ DIST    │ X.FN     │ FIN  │ EIGEN │ ELEC │ IR
  ─────┼─────────┼──────────┼──────┼───────┼──────┼────
    1  │ all     │ no ellip │ fast │   ❌  │  ✅  │ ✅
    2  │ all     │ full     │ slow │   ❌  │  ❌  │ ❌
    3  │ limited │ no ellip │ fast │   ✅  │  ✅  │ ✅
    4  │ none    │ no e-B-O │ slow │   ❌  │  ❌  │ ✅


  DIST   all      every distribution
         limited  Normal, StdNormal, LogNormal, gev, Pareto, Uniform, Discr Uniform
         none     no distributions
  X.FN   full     includes elliptic, Bessel, Orthogonal
         no ellip without elliptic
         no e-B-O none of elliptic, Bessel, Orthogonal
  FIN    fast     financial funcs at full precision/speed
         slow     financial funcs available, but lower precision and slower
  EIGEN  ✅       EIGVAL + EIGVEC (est. > 16 digits) + MSQRT
         ❌       none of the above
  ELEC   ✅       Star/Delta, Impedance, phase-sequence, parallel funcs
         ❌       none of the above
  IR     ✅       IR printing
         ❌       no IR printing
  All C47 / DM42 packages (common to 1–4): no 2D/3D VECTOR conversions (matrix functions stay), no number editing, no 1000-digit XFN math.

---

The differences are detailed here:  
https://gitlab.com/h2x/c47-wiki/-/wikis/home#differences-between-models

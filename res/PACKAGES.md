Which of the 3 files (PACKAGE 1, PACKAGE 2 or dmcp5) do I load?

## Short answer

- **DM42n**: load **dmcp5**
- **Original DM42 (non-n)**: Choose **PACKAGE 1** or **PACKAGE 2** or **PACKAGE 3** or **PACKAGE 4**

## Long answer

On the DM42n there is sufficient flash storage, so there is no package choice to make: all functions are always available.  
**dmcp5** is the full C47 firmware and is the correct and only option. It does not fit on the original DM42.

On the original DM42, flash space is constrained. To make C47 fit, the firmware is built in two mutually exclusive variants:

- **PACKAGE 1** retains probability and distribution functions, omits Elliptic, Bessel and Orthogonal polynomial, and eigenvalue functions including IR printing.
- **PACKAGE 2** looses some distributions, retains all Elliptic, Bessel and Orthogonal polynomial functions and omits IR printing.
- **PACKAGE 3** looses more distributions, omits Elliptic, Bessel and Orthogonal polynomial functions, retains eigenvalues and elec functions, and omits IR printing.
- **PACKAGE 4** has no distributions, omits Elliptic, Bessel and Orthogonal polynomial, eigenvalues and elec functions, and includes IR printing.

Apart from these exclusions, the packages are functionally identical. Neither is “better”; each simply trades one feature set for another to meet the memory limit.

If you have two original DM42 units converted to C47, installing different packages could make sense and effectively gives you access to the complete function set across the two machines.

The precise feature balance may vary slightly between releases as code size fluctuates, but this split is deliberate and should be expected on the original DM42.

## Feature matrix: 2026-07-17

```
 Pkg │ DIST    │ X.FN     │ FIN  │ EIGEN │ ELEC │ IR
─────┼─────────┼──────────┼──────┼───────┼──────┼────
  1  │ all     │ stripped │ fast │   ·   │  ·   │ ✓
  2  │ half    │ full     │ slow │   ·   │  ·   │ ·
  3  │ limited │ stripped │ slow │   ✓   │  ✓   │ ·
  4  │ none    │ stripped │ slow │   ·   │  ·   │ ✓

DIST   all      every distribution
       half     Normal, StdNormal, LogNormal, cauchy, chi, expo, logis, t, weibull
       limited  Normal, StdNormal, LogNormal only
       none     no distributions
X.FN   full     includes Elliptic, Bessel, Orthogonal
       stripped none of Elliptic, Bessel, Orthogonal
FIN    fast     financial functions at full precision/speed
       slow     financial functions available, but lower precision and slower
EIGEN  ✓        EIGVAL + EIGVEC (est. > 16 digits)
       ·        no EIGVAL, EIGVEC or MSQRT
ELEC   ✓        Star/Delta, Impedance, phase-sequence, parallel functions
       ·        none of the above
IR     ✓        IR printing enabled
```

Common to all C47 / DM42 packages: no 2D/3D VECTOR conversions (matrix functions stay), no number editing, no 1000-digit XFN math.

---

The differences are detailed here:  
https://gitlab.com/h2x/c47-wiki/-/wikis/home#differences-between-models

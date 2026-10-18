Which of the 5 files (PACKAGE 1 ... PACKAGE 4 or dmcp5) do I load?

## Short answer

- **DM42n**: load **dmcp5**
- **Original DM42 (non-n)**: Choose **PACKAGE 1** or **PACKAGE 2** or **PACKAGE 3** or **PACKAGE 4**

## Long answer

On the DM42n there is sufficient flash storage, so there is no package choice to make: all functions are always available.  
Some features are carried only by **dmcp5** and by the simulator, because they do not fit any of the four original-DM42 packages: the 1000 digit X.FN engine, the 2D/3D vector conversions, the 159 digit cubic, quadratic and eigenvalue paths, and **x→POLY / V→Σ=0**, the algebraic number identification commands (3,896 bytes).  
**dmcp5** is the full C47 firmware and is the correct and only option. It does not fit on the original DM42.

On the original DM42, flash space is constrained. To make C47 fit, the firmware is built in four mutually exclusive variants:

- **PACKAGE 1** retains all distributions, Bessel and Orthogonal polynomial functions, fast financial functions, ELEC functions and IR printing; omits Elliptic and eigenvalue functions.
- **PACKAGE 2** retains the three Normal distributions and the six of group 2, and the full X.FN menu (Elliptic, Bessel, Orthogonal); financial functions are slower and lower precision; omits the eleven distributions of groups 3 and 4, eigenvalues, eigenvectors, matrix sqrt, ELEC functions and IR printing.
- **PACKAGE 3** keeps the three Normal distributions and no others; retains Bessel and Orthogonal polynomial functions, fast financial functions, eigenvalues, eigenvectors, matrix sqrt, ELEC functions and IR printing; omits Elliptic functions.
- **PACKAGE 4** has no distributions; omits Elliptic, Bessel and Orthogonal polynomial, eigenvalue and ELEC functions; financial functions are slower and lower precision; includes IR printing.


Apart from these exclusions, the packages are functionally identical. None is “better”; each trades one feature set for another to meet the memory limit.

If you have two original DM42 units converted to C47, installing different packages could make sense and effectively gives you access to the complete function set across the two machines.

The precise feature balance may vary slightly between releases as code size fluctuates, but this split is deliberate and should be expected on the original DM42.

## Which distribution is in which package

The distributions are selected in groups. A package takes a whole group or none of it.

*Table 1. Every distribution, the group it belongs to, and the packages it reaches.*

| Distribution | Group | P1  | P2  | P3  | P4  |
|--------------|-------|-----|-----|-----|-----|
| Norml        | 1     | ✅  | ✅  | ✅  | ❌  |
| LgNrm        | 1     | ✅  | ✅  | ✅  | ❌  |
| StdNorml     | 1     | ✅  | ✅  | ✅  | ❌  |
| Cauch        | 2     | ✅  | ✅  | ❌  | ❌  |
| chi2         | 2     | ✅  | ✅  | ❌  | ❌  |
| Expon        | 2     | ✅  | ✅  | ❌  | ❌  |
| Logis        | 2     | ✅  | ✅  | ❌  | ❌  |
| t            | 2     | ✅  | ✅  | ❌  | ❌  |
| Weibl        | 2     | ✅  | ✅  | ❌  | ❌  |
| F            | 3     | ✅  | ❌  | ❌  | ❌  |
| NBin         | 3     | ✅  | ❌  | ❌  | ❌  |
| Hyper        | 3     | ✅  | ❌  | ❌  | ❌  |
| Binom        | 3     | ✅  | ❌  | ❌  | ❌  |
| Poiss        | 3     | ✅  | ❌  | ❌  | ❌  |
| Geom         | 3     | ✅  | ❌  | ❌  | ❌  |
| GEV          | 4     | ✅  | ❌  | ❌  | ❌  |
| Prto         | 4     | ✅  | ❌  | ❌  | ❌  |
| Prto2        | 4     | ✅  | ❌  | ❌  | ❌  |
| Unfm         | 4     | ✅  | ❌  | ❌  | ❌  |
| DisU         | 4     | ✅  | ❌  | ❌  | ❌  |

## What each group costs

Every figure below is the change in the PACKAGE 1 image when that group is left out, measured one build at a time.

*Table 2. Flash cost of each distribution group, measured in PACKAGE 1.*

| Group | Distributions                       |  Flash |
|-------|-------------------------------------|-------:|
| 1     | Norml, LgNrm, StdNorml              |  5,768 |
| 2     | Cauch, chi2, Expon, Logis, t, Weibl | 15,096 |
| 3     | F, Binom, NBin, Hyper, Poiss, Geom  | 17,008 |
| 4     | GEV, Prto, Prto2, Unfm, DisU        |  4,768 |
|       | every distribution                  | 42,640 |

Groups 3 and 4 and the whole set are each one build of PACKAGE 1 with that group left out. Group 2 is the difference between leaving out groups 2 and 3 together and leaving out group 3 alone. Group 1 is what the other three leave of the 42,640.

Three rules decide which groups can be left out on their own.

- Group 3 needs group 2. The group 3 distributions take their argument check, `checkRegisterNoFP`, from `chi2.c`.
- Groups 2, 3 and 4 need group 1. Poisson, F, chi2 and t start their quantile solvers from `WP34S_qf_q_est` in `normal.c`.
- Group 3 is one piece. `WP34S_Qf_Newton` in `f.c` and `WP34S_qf_discrete_final` in `geometric.c` are solvers the six of them share, and each solver calls the density and the distribution of each one by name. `f.c` and `negBinom.c` also call each other. No distribution of group 3 can be left out on its own.

## Feature matrix: 2026-09-21

```
Info 2026-09-21, read from the built objects of each package

   Pkg │ DIST    │ X.FN     │ FIN  │ EIGEN │ ELEC │ IR
  ─────┼─────────┼──────────┼──────┼───────┼──────┼────
    1  │ all 20  │ no ellip │ fast │   ❌  │  ✅  │ ✅
    2  │ 9, gp1-2│ full     │ slow │   ❌  │  ❌  │ ❌
    3  │ 3, gp1  │ no ellip │ fast │   ✅  │  ✅  │ ✅
    4  │ none    │ no e-B-O │ slow │   ❌  │  ❌  │ ✅


  DIST   all 20   every distribution, groups 1 to 4, listed in Table 1
         9, gp1-2 the three Normal distributions and the six of group 2
         3, gp1   the three Normal distributions
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

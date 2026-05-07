Which of the 3 files (PACKAGE 1, PACKAGE 2 or dmcp5) do I load?

## Short answer

- **DM42n**: load **dmcp5**
- **Original DM42 (non-n)**: load **PACKAGE 1** or **PACKAGE 2**

## Long answer

On the DM42n there is sufficient flash storage, so there is no package choice to make.  
**dmcp5** is the full C47 firmware and is the correct and only option. It does not fit on the original DM42.

On the original DM42, flash space is constrained. To make C47 fit, the firmware is built in two mutually exclusive variants:

- **PACKAGE 1** retains probability and distribution functions and omits Bessel and Orthogonal polynomial functions.
- **PACKAGE 2** retains Bessel and Orthogonal polynomial functions and omits probability and distribution functions.

Apart from these exclusions, PACKAGE 1 and PACKAGE 2 are functionally identical. Neither is “better”; each simply trades one feature set for another to meet the memory limit.

If you have two original DM42 units converted to C47, installing PACKAGE 1 on one and PACKAGE 2 on the other effectively gives you access to the complete function set across the two machines.

- Use **PACKAGE 1** if statistics and probability are more relevant to your work.
- Use **PACKAGE 2** if you require Bessel or Orthogonal functions.
- If you have a **DM42n**, ignore the packages entirely and install **dmcp5**.

The precise feature balance may vary slightly between releases as code size fluctuates, but this split is deliberate and should be expected on the original DM42.

---

The differences are detailed here:  
https://gitlab.com/h2x/c47-wiki/-/wikis/home#differences-between-models

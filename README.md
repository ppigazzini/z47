# TVM mod

This build of C47 has an addition to the TVM solver: the ability to enter a number of compounding periods per year different from the number of payments per year (PER/a).

In the existing solver these two numbers are assumed to be equal. The new item CPER/a in the TVM menu allows the annual number of compounding periods to be set separately from the annual number of payments. (rCper/a recalls its value).

Setting PER/a automatically sets CPER/a to the same value. This means that if no value is entered for CPER/a the solver behaves as it previously did.

The calculations needed to make this work involve finding an interest rate per payment period, \(i_M\), that satisfies
\[(1+i_M)^{\rm PER_a}=\left(1+{i_a\over\scriptstyle{\rm CPER_a}}\right)^{\rm CPER_a}.\]
\(i_M\) is a function of i%/a, PER/a, and CPER/a. So long as none of these change the calculation of \(i_M\) can be done once and then re-used in subsequent interations. This gives a noticeable speed increase on the physical calculator. However, if solving for i%/a (or either of the other two quantities) \(i_M\) has to be recalculated on each iteration. This is handled automatically, but the calculation takes a little longer than otherwise.

(Note that I've had to exclude "JM Graphics" from the build to get it to compile on my system. This was needed even before any code changes.)
# C47

The [C47 project](https://gitlab.com/rpncalculators/c43) is a fork of the [WP43 project](https://gitlab.com/rpncalculators/wp43), adapted to work on a standard Swiss Micros DM42 calculator with the standard keyboard layout.

The two shifted key positions (f and g) on the calculator are supported by applying the infamous cycling shift behaviour to the DM42's single shift key, which means a custom faceplate or overlay is all that is needed to convert the DM42 hardware into a C47 calculator. No key stickers are required on a DM42.

Building on the user experience of the legendary HP-42S, tapping into the unprecedented accuracy of the WP34S engine, and adding a quite few extra features of its own, the C47 is a thriving open source project aiming to make RPN calculators highly relevant for mathematicians, scientists and engineers of today.

C43 / C47: The C47 historically is based on the WP43, which was called WP43S before it was renamed to WP43. The C47 as such initially was forked and called WP43C, then renamed to C43, then renamed to C47. Many references in the source code and documents on GitLab still refer to any or all of the listed prior names! This makes no difference to the current (C47) state of the project.

The C47 Wiki can be found [here](https://gitlab.com/rpncalculators/c43/-/wikis/home).
The C47 Community Wiki, which every user can help to create, can be found [here](https://gitlab.com/h2x/c47-wiki/-/wikis/home).

The page where you can order the bezel to glue it on a DM42 to make it a C47 can be found [here](https://47calc.com).

A comprehensive reference to all functions of the C47 as PDF downloads can be found [here](https://47calc.com/documentation/combined/doc.html).

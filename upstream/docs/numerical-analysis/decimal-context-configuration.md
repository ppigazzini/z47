# Decimal context analysis for configuration numeric state

## Scope

This audit covers context initialisation and numeric configuration in
`config.c`, the numeric item dispatch in `items.c`, the two native-integer
parameter converters used only by configuration setters, and the rounding
mode field loaded by `saveRestoreCalcState.c`. Short- and long-integer
arithmetic, plotting, graph state, and native floating-point sensor or
platform calculations are outside this audit.

## Context roles

`ctxtReal34` is initialised as decimal128: 34 digits, decimal128 exponent
limits, no traps, and half-even rounding. It is the public Real34 result and
storage context. The selected rounding mode changes only its `round` field.
That is required because a Real34 primitive must apply the user's selected
mode.

`ctxtReal39`, `ctxtReal51`, and `ctxtReal75` use 39, 51, and 75 digits with
the extended exponent interval from -999999 to +999999. They retain
half-even rounding. These contexts serve internal work where the final
Real34 conversion applies the selected mode. Changing all four contexts
with RMODE would therefore be incorrect.

`ctxtReal4` is the existing six-digit limited context. No ordinary numeric
configuration result is evaluated in it. Its users are comparisons,
specialised numerical work, and excluded native or plotting routes, so this
audit makes no change to it.

## Rounding-mode invariant

Let `r` be the public mode index and let `R[r]` be its decimal-library entry
in `roundingModeTable`. The required invariant is

```
roundingMode = r  and  ctxtReal34.round = R[r].
```

The public `RMODE` item invokes `fnSetRoundingMode`. The former setter wrote
only the index. Configuration reset and the JM profile also wrote the index
without updating the context. The state loader reset the configuration and
then loaded only the index. These routes could consequently display one mode
while direct Real34 arithmetic used another.

The setter now writes the index and context together after validating the
table bound. `fnRoundingMode`, configuration reset, the profile, and state
loading use that setter. P39, p51, and p75 stay half even.

An exact midpoint exposes the mismatch. At precision 34 the adjacent values
at one are

```
1
1.000000000000000000000000000000001
```

and `1 + 5e-34` is their exact midpoint. Half even selects the first value;
half up, away from zero, and ceiling select the second positive value. The
other four modes select the first. The regression invokes the public setter
for all seven modes and compares the stored Real34 bits with the independently
derived neighbour. A separate reset case and state-load case verify the same
invariant. This is one p34 operation implementing public result semantics, so
p34 is necessary and cost-neutral. No p39-to-p34 boundary is involved.

## Numeric configuration parameters

The register parameter route converts a Real34 value exactly to `real_t`,
truncates a fractional value explicitly towards zero, and constructs the
corresponding GMP integer. The explicit direction makes parameter selection
independent of RMODE. NaN and either infinity are rejected before integer
conversion. Negative zero becomes integer zero, which is valid for the
non-negative configuration setters.

The former native conversion then used `mpz_get_ui` or `mpz_get_si` and
narrowed the result without checking the destination range. For example,
Real34 `4294967296` became uint32 zero, so ADM and display-format setters
accepted an out-of-range value. Real34 `4294967295` became int32 -1 on the
host build, so the integer-sign setter selected a valid mode from an invalid
parameter. Large negative values could similarly become zero.

The conversion now compares the GMP integer with `UINT32_MAX`, `INT32_MIN`,
and `INT32_MAX` before the native conversion. The comparisons are exact and
add no decimal rounding. Values outside the native interval return the
configuration out-of-range error. Values through `UINT32_MAX` remain valid
native inputs; DMX and NDEC then apply their documented setting-specific
upper clamp. `fnSetISM` now reports the same out-of-range error when signed
conversion fails without an earlier datatype error.

## Exact configuration storage

Profile data in `Sett` is a signed native integer. Every such value has at
most ten decimal digits, so `int32ToReal34` represents it exactly. The former
route first built a wide `real_t` and then converted it to Real34. Direct
Real34 construction removes that intermediate value with zero numerical
error. It is one storage conversion, not chained p34 arithmetic.

Zero initialisation, Real34 copies, and the item table's bounded integer
parameters require no arithmetic context. The I/J snapshot in `items.c`
uses explicit truncation for matrix indices and does not produce a public
numeric result. No context change is appropriate there.

## Verification

The initial exact rounding cases produced 54 successful results from 57:
the item setter, configuration reset, and state loader each returned the
numeric failure indicator zero. With the rounding correction present and
the native range checks deliberately removed, the expanded set produced 61
successful results from 67; six Real34 values outside uint32 or int32 were
accepted after native truncation.

The focused files cover all seven rounding modes, reset and state reload,
the exact uint32 upper endpoint, both signed overflow directions, negative
zero, NaN, infinity, setting-specific upper clamps, and ordinary values. The
rounding checks compare exact Real34 values inside the test driver and do not
use the suite's relative tolerance.

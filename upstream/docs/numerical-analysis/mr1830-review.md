# MR 1830: exact arithmetic review

## Scope

Review of [MR 1830](https://gitlab.com/rpncalculators/c43/-/merge_requests/1830), at commit `b6a23d38c3e27058b768e374ceac53e003d0ed6b`.
The detailed review covers the shared scaled-integer conversion, mixed integer/Real34 arithmetic, and comparison code.
The MR changes 564 files. This review is not a correctness certification of all those files.

## Numerical defects fixed

1. **Reduced significant digits incorrectly reduce the subnormal range.**
   `exactResultContext()` reduces precision without adjusting `emin`.
   At `SDIGS 1`, Real34 `1e-6144` divided by integer `1` becomes zero in round-to-nearest mode.
   The local context now keeps `etiny = emin - digits + 1 = -6176`.
   This preserves the Real34 quantum limit while applying the requested significant digits.
   The shared fix also applies to exact addition and multiplication results.
2. **Mixed addition and subtraction lose the sign of exact zero.**
   The previous rule makes every exact zero negative under rounding towards negative infinity, including `+0 + +0`.
   It also loses negative zero in `Real34(-0) - integer(0)` under other rounding modes.
   The new rule preserves equal effective operand signs for two zero operands.
   Opposite signs and nonzero cancellation use the rounding-mode rule.
3. **Integer zero divided by a negative real can lose its negative sign.**
   The integer-first division helper supplies a positive-zero sign unconditionally.
   Scalar integer `0` divided by real matrix `[-2]` exposes this defect.
   The helper now supplies the real divisor's sign for a zero numerator.

Existing scaled-integer helpers and `longInteger*` wrappers are the implementation precedent.
The changes use those helpers; they do not introduce another decimal arithmetic system.

## Is scaled-integer arithmetic required?

Exact information is required. This representation is not the only possible implementation, but replacing it with the existing fixed 39- or 75-digit contexts is unsafe.

- For integer `10^79 + 1` plus Real34 `-1e79`, the exact result is `1`.
  Converting the integer to either working context first loses the unit and produces zero after addition.
  The simulator confirms that the retained exact route produces `1`.
- With round-to-nearest, ties-to-even, consider `1 / 810000007290000066339000603684905538075`.
  Rounding first to 39 digits and then to 34 gives `1.234567890123456789012345678901234e-39`.
  Direct rounding of the exact rational value to 34 digits gives `1.234567890123456789012345678901235e-39`.
  The quotient/remainder route retains the information needed to avoid this double rounding.
- Comparisons must also distinguish large integers that fixed-precision conversion makes equal.
  An alternative exact decimal comparison was tested, but decimal string conversion made the 1000-digit case about 158 times slower in an initial host measurement.
  That alternative is removed. The comparison implementation is unchanged.

The retained arithmetic therefore needs exact coefficients, exponent alignment, and remainder information.
Several temporary integer copies and exact digit counts are not required.

## Smaller implementation and rounding argument

`addSubtractScaledLongIntegers()` now borrows the unchanged input and scales only the input that needs exponent alignment.
The mixed integer/Real34 addition helper uses this common implementation instead of duplicating it.
The output remains a newly initialised integer, as in the existing interface.
The local scale integer is freed before return; the caller frees the output.

The GMP decimal digit estimate is either the exact count or one greater.
Conversion now retains one or two guard digits, plus a nonzero remainder marker when needed.
Thus the estimate cannot remove the first rounding digit.
The marker distinguishes an exact tie from a value beyond the tie and preserves directed-rounding decisions.
The exponent adjustment preserves the place values of all retained digits.
This argument also applies when the final quantum is limited by the subnormal range.

Division uses scale `precision + 2 + estimated_denominator_digits - estimated_numerator_digits`.
The two possible one-digit estimate errors leave at least `precision + 1` quotient digits.
One quotient/remainder operation is therefore sufficient; the exact-count checks and conditional second division are removed.
The final conversion still uses the requested rounding mode, not a wider intermediate rounded result.

Conversion frees its leading coefficient, remainder, and power-of-ten integers within the truncation branch.
Small coefficients need none of those temporary integers.
The remaining exact digit-count helper compares absolute values through a new wrapper, without copying the coefficient.
No working decimal precision is increased.

## Measurements

The production source change removes 29 lines overall, including the new wrapper and numerical fixes.

| DM42 package-4 build | Before | After | Reduction |
|---|---:|---:|---:|
| `C47.pgm` | 698,996 bytes | 698,932 bytes | 64 bytes |
| Flash section | 698,976 bytes | 698,912 bytes | 64 bytes |

RAM remains 7,296 bytes and QSPI remains 1,703,848 bytes.
These are linked ARM Cortex-M4 measurements with GCC 15.3.1, size optimisation, and LTO, not estimates from source line counts.
No physical calculator deployment or hardware timing is performed.

Host division measurements use process CPU time, 20,000 operations per case, and the median of five runs:

| Exact division case | Before, ns/op | After, ns/op | Time reduction |
|---|---:|---:|---:|
| `1 / 3` | 1,704 | 1,477 | 13.3% |
| Large numerator / 39-digit denominator | 1,889 | 1,545 | 18.2% |
| Same numerator / 999-digit denominator | 2,588 | 1,917 | 25.9% |

The changed translation unit is compiled with `-Os`; unchanged dependencies use the test build configuration.
These measurements describe the helper on this host, not total calculator execution time.

## Verification

- The new `scaled_integer.txt` suite contains 87 cases across all seven supported rounding modes.
  The original executable fails 40 cases; the revised executable has zero failures.
- A separate 448-case computation uses exact rational arithmetic for mixed addition, subtraction, multiplication, and division.
  It covers all seven rounding modes, precisions 1, 7, 33, and 34, and exponents -6176, -40, 0, and 40.
  The revised executable has zero failures.
- Targeted test runs report zero bytes owned by GMP after completion.
- Simulator screen capture confirms `1e-6144 / integer(1)` at `SDIGS 1`; a separate simulator run confirms exact large-integer cancellation.
- Final `make repeattest`: 19,097 cases, zero failures, 384.22 seconds, and zero bytes owned by GMP after completion.

Local evidence and measurement scripts are in `/Users/pauli/tmp/mr1830-review`.
The regression cases are included in the normal test list.
No unexplained numerical differences are accepted through a relaxed tolerance.

The local ARM build needs temporary build configuration workarounds: avoid duplicate `nosys.specs`, build only the DMCP target, and use GNU `stat` for the packaging size query because GNU `find` is absent.
Those workarounds are outside the checkout and apply equally to both size measurements.
Existing linker warnings concern `_gettimeofday`, an RWX segment, and host alignment; no new C compiler warning is identified.

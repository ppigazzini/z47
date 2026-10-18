# Decimal context analysis for error-code conversion

## Scope and result

This audit covers `fnErrorMessage` in `src/c47/error.c`.  Integer arithmetic beyond
conversion into the public error-code route is outside scope.

`fnErrorMessage` needs no extended decimal context.  A Real34 operand is already on
the result lattice.  Its two range comparisons and its conversion to an error code
are direct storage semantics, so p34 is both sufficient and cost-neutral.  The long
integer route now avoids decimal conversion entirely: exact integer comparisons
establish the range before conversion to `uint32_t`.

## Real34 error codes

The valid interval is

```text
1 <= x < NUMBER_OF_ERROR_CODES = 129.
```

`129` is exactly representable at p34.  Comparisons with stored Real34 values are
exact predicates; no rounding operation precedes them.  `real34ToUInt32` then uses
`DEC_ROUND_DOWN`, which truncates towards zero.  Every accepted value is positive,
so this selects the integer part.  Examples are `1.999... -> 1` and
`128.999... -> 128`.  This selection is independent of the user's rounding mode.

Zero of either sign, negative finite values, positive and negative infinity, and
NaN do not satisfy the interval and produce `ERROR_OUT_OF_RANGE`.  An angular tag
changes the public data type meaning and remains `ERROR_INVALID_DATA_TYPE_FOR_OP`.
No widening to p39 can change any of these results.

A single p34 operation is cost-neutral.  This route has no dependent p34 arithmetic
chain, so p39 would add no accuracy or conversion benefit.

## Long integer error codes

The former route converted every long integer to a decimal string and then rounded
that string into Real34 before the range test.  Integers in the accepted interval
are small enough to be represented exactly, so the result was accurate, but the
decimal context and shared text buffer were unnecessary.

The revised route reconstructs the GMP value from the register, compares it exactly
with `1` and `129`, and converts it to `uint32_t` only after those bounds are true.  The cast is
therefore restricted to `1` through `128`.  Values with thousands of bits take the
same exact rejection route and never enter decimal arithmetic.  The GMP value is
freed after both the accepted and rejected comparisons.

## Verification coverage

`src/testSuite/tests/error_cov.txt` covers:

- accepted and rejected long integers, including an input far wider than Real34;
- fractional Real34 truncation at both ends of the valid interval;
- signed zero, infinities, NaN and an angular tag.

The test parser now accepts the complete three-digit error-code interval 0 through
128.  Its former two-digit grammar could not assert status messages 100 through
128, and its upper-bound check admitted the invalid index 129 if that grammar were
extended without correcting the comparison.

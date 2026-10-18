# Decimal contexts in result post-processing

## Scope

`adjustResult` applies the common policy to a result that is already stored as
Real34, Complex34, or a matrix of those types. This audit covers SDIGS rounding,
special values, zero signs, result registers other than X, and the subsequent
error or stack action. Indirect addressing and integer arithmetic are outside
this audit.

## Context selection

Each input component is a Real34 value and therefore has at most 34 coefficient
digits. For an SDIGS setting `s` from 1 through 33,
`roundToSignificantDigits` changes the exponent so that the requested closing
coefficient is integral, applies one integral rounding, and changes the
exponent back. The exponent changes are exact. The integral result has at most
`s` digits, so the p34 context cannot discard a coefficient digit before or
after the selected rounding operation. Conversion back to Real34 is exact for
a finite result in range.

This gives the following context choices:

| Route | Context | Reason |
|---|---:|---|
| Real34 | p34 | One selected-rounding operation on a Real34 coefficient |
| Each Complex34 component | p34 | The stored rectangular components are independent Real34 values |
| Each real-matrix element | p34 | The same scalar operation, applied in place |
| Each complex-matrix component | p34 | The same componentwise operation, applied in place |
| Infinity, NaN, and zero policy | none | Classification and sign-bit changes need no decimal arithmetic |

A p39 context has no extra source digit to use at this stage. The p34 operation
is a single result operation and is cost-neutral. The unpack and repack concern
for chained p34 arithmetic does not apply because no decimal operation follows
the rounding before exact Real34 storage.

An upstream function that still has a wider result should use the result
conversion helpers. If a caller first narrows a wide value directly to Real34,
`adjustResult` cannot recover discarded digits. Differences caused only by the
accepted p39-to-p34 closing boundary are excluded from this audit.

## Result order and exponent ceiling

The largest finite positive Real34 value is

```text
9.999999999999999999999999999999999E6144
```

At SDIGS 1, nearest rounding and the magnitude-increasing directed modes produce
`1E6145`, which is outside the Real34 finite range. Toward-zero rounding produces
`9E6144`; ceiling and floor select between these outcomes according to the sign.
These results follow directly from the decimal coefficient and establish the
expected values for all seven rounding modes.

The public special-result policy must classify the value after SDIGS rounding.
Otherwise a finite stored input can become infinity after the infinity check and
escape the `FLAG_SPCRES=0` overflow error. `adjustResult` now rounds first, then
checks each resulting component. An error invokes `undo` before CPXRES or stack
drop actions. With `FLAG_SPCRES=1`, the rounded infinity remains available as a
special result.

The NaN branch in `adjustRealRegister` remains disabled, matching the existing
common result policy. With special results disabled, existing infinity produces
the appropriate signed overflow error and every zero encountered by the scan is
made positive. No context is involved in these operations.

## Result-register independence

The matrix SDIGS helpers operate on register X. They are valid for the explicit
RSD command but cannot implement `adjustResult(res, ...)`, because `res` can be
Y, Z, T, or another stack register. Using those helpers rounds X and leaves the
requested matrix unchanged.

The common result route now links the matrix in `res` and applies the proved p34
component operation directly. This also avoids temporary register allocation.
Automatic scalar and matrix post-processing now use the same rectangular,
componentwise SDIGS definition.

## Regression coverage

The existing `src/testSuite/tests/round_cov.txt` file checks:

- the positive and negative Real34 exponent ceiling under all seven rounding
  modes;
- overflow rejection with special results disabled and infinity retention with
  special results enabled;
- scalar, complex, real-matrix, and complex-matrix components;
- in-place matrix rounding of Y while X stays unchanged.

The ceiling expectations are derived from the exact Real34 coefficient above.
The matrix cases also detect any return to an X-specific helper.

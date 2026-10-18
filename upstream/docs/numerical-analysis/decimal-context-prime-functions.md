# Decimal context analysis for prime functions

## Scope

This analysis covers Real34 inputs to the prime functions and the Real34
factor matrices used by the sigma and Euler-phi functions. Long-integer prime
search and factorisation use GMP and require no decimal context.

## Generalised sigma exponent

The generalised sigma function accepts an exponent in the inclusive range
`0..3321`. A Real34 parameter is truncated towards zero before this range is
tested, matching the established decimal-input rule. The conversion routine
reports NaN, infinity and values outside the signed 32-bit range separately.

The former Real34 route ignored that report and accepted the returned zero.
For example, `k=1e40` selected `sigma_0` and returned `6` for the factors of
`12`. The integer route rejected the corresponding out-of-range parameter.
The Real34 route now checks both conversion status and the same `0..3321`
range before changing the stack.

This route performs no rounded decimal arithmetic. It classifies the stored
Real34 value, extracts its integral part exactly within the accepted range,
and supplies the resulting integer exponent to GMP.

## Factor-matrix precision

Factor matrices store Real34 elements. A factor with more than 34 significant
digits is not necessarily representable exactly in that format. Returning a
rounded factor can make reconstruction, sigma and Euler phi produce an
incorrect integer. Exact factor-matrix representation therefore remains a
separate design requirement for inputs beyond the Real34 coefficient limit.

## Verification

The focused prime-function cases cover the accepted upper exponent `3321`,
the rejected adjacent value `3322`, and a Real34 exponent outside the signed
32-bit range. The last case formerly returned `6`; it now reports the same
parameter error as the integer route and leaves the input unchanged.

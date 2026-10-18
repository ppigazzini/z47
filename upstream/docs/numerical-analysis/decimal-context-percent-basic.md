# Decimal context analysis for basic percentage functions

## Scope

This analysis covers `fnPercent` and `fnPercentT` for real inputs.  The
statistics-based percentage functions are covered by
`decimal-context-percent-transforms.md`; margin and mean-rate calculations are
covered by their own audits.

Both public functions use `getRegisterAsReal`.  A complex scalar with a zero
imaginary component is accepted exactly as a real value.  A non-real complex
scalar and either matrix type produce the established invalid-data error before
arithmetic or stack mutation.  There is therefore no complex-valued or matrix
arithmetic context to select for these commands.

## `fnPercent`

`percentReal` evaluates `x*y/100`.  Division by 100 is an exact decimal exponent
adjustment, so the only rounded operation is multiplication.  Scaling one
operand before multiplication makes the rounded operation equal to

```
fl34((x * 10^-2) * y) = RN34(x*y/100).
```

This order also keeps range decisions at the final value.  For example,
`x = 9.999999999999999999999999999999999E6144` and `y = 100` have the exact
result `x`.  Forming `x*y` first overflows a real34 temporary, after which an
exponent adjustment cannot recover the finite answer.  Scaling `x` first
returns the exact endpoint.  At the lower endpoint, scaling `1E-6176` before
multiplication by 100 likewise returns `1E-6176`.

A single correctly rounded multiplication in `ctxtReal34` returns the required
real34 result directly.  In each of the three nearest modes its error is at
most one half ulp; in each of the four directed modes it is less than one ulp.
A context below 34 digits cannot represent every real34 result.  The p34
operation is cost-neutral because it is the sole arithmetic operation and
directly implements the public real34 rounding.  The `ctxtReal34` call is
therefore minimal.

This direct argument assumes both inputs are already exact Real34 values. A
long integer can contain more than the 75 digits used by the generic real
getter. For a percentage with a long operand, both finite inputs are instead
represented by exact integer coefficients and decimal exponents. Their
coefficients are multiplied without a bound, the result exponent is decreased
by two, and the scaled product is converted once to Real34. Applying the scale
before conversion also preserves the finite upper endpoint and the minimum
subnormal when the other operand is exactly 100.

NaNs, infinities and signed zeros use the multiplication wrapper semantics.
In particular, zero times infinity produces NaN and the sign of a finite zero
result is the multiplication sign.  Final overflow and subnormal rounding are
also selected by that one p34 operation.

## `fnPercentT`

`percentTReal` evaluates `100*x/y`.  Multiplication by 100 is again an exact
exponent adjustment.  The division is the sole rounded operation.  Under the
requested correctly rounded division assumption,

```
fl34(100*x/y) = RN34(100*x/y).
```

The error is at most one half ulp in nearest modes and less than one ulp in a
directed mode.  The former p39 operation added five working digits before a
second conversion to real34, but those digits cannot improve the result model
once 39-to-34 conversion differences are excluded.  The public call now uses
`ctxtReal34`.

Scaling the numerator changes only its decimal exponent.  The division
determines real34 overflow or underflow, including inputs at both real34
exponent limits.  The added file-driven cases exercise those limits.

Zero-denominator and special-result branches are selected before the division
and are independent of coefficient width.

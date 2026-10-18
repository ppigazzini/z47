# Decimal contexts for random real values

## Scope and result

This analysis covers the decimal arithmetic in `realRandomU01` and the real
route of `RANI#`.  The long-integer route is outside scope.  The PCG state
transition and the bounded integer sampler are unchanged.

The selected contexts are:

| Calculation | Context | Reason |
|---|---:|---|
| decimal construction of `RAN#` | p34 | every addition is exact |
| `RANI#` span | p75 | a finite affine cancellation can depend on 68 input digits |
| `RANI#` fused affine value | p34 | this is the final selected-mode rounding |

The p75 span replaces p39 for correctness.  The p34 construction and fused
operation replace p39 without losing information.

## Uniform decimal construction

Four independently sampled chunks have ranges

```
B0, B1 in [0, 10^8)
B2, B3 in [0, 10^9)
```

and the generated real is

```
U = (((B0 * 10^8 + B1) * 10^9 + B2) * 10^9 + B3) * 10^-34.
```

The integer coefficient before the final scale is between zero and
`10^34-1`.  The three additions therefore contain at most 16, 25, and 34
digits.  Each p34 addition is exact under every calculator rounding mode, and
the exponent adjustment is exact.  A wider decimal context cannot change the
value.

Subject to the existing bounded-sampler model, `U` is uniform on the decimal
lattice `{k * 10^-34: 0 <= k < 10^34}`.  The sampler's pre-existing finite
fallback has probability below `2^-320`; this audit does not alter it.

## Real interval mapping

For finite endpoints, define

```
L = min(X, Y)
H = max(X, Y)
T = H - L
R = L + U*T.
```

The final operation is one fused multiply-add.  Under the task assumption for
fused arithmetic, p34 applies the selected calculator rounding mode directly
to `L + U*T_hat`.  A p39 fused result followed by decimal128 conversion adds
work but provides no useful digit once final p39-to-p34 boundary differences
are excluded.

The span needs more precision.  When affine cancellation can make `R` small,
the endpoint magnitude ratio is within the range represented by `U` and
`1-U`, namely about `10^-34` through `10^34`.  Alignment of two decimal128
coefficients in this range can require 68 digits.  P75 represents that span
exactly.  For a wider endpoint ratio there is no small affine cancellation;
the p75 span rounding is more than 40 decimal places below the required result
precision.  The `U=0` case returns `L` through the fused operation regardless
of the span approximation.

P51 is not sufficient globally.  The decimal lattice contains `U=10^-34`.
For any 34-digit coefficient `A`, choose

```
H = A
L = -A * 10^-34.
```

Then `T=A*(1+10^-34)` can require 68 digits, while
`L+U*T=A*10^-68`.  A p51 span retains only 17 digits from the low copy of
`A`, so the small result can retain only those 17 digits.  P75 is the narrowest
project context among p34, p39, p51, and p75 that represents every such span.

P34 is also unsuitable for the span exponent range.  With opposite maximum
finite decimal128 endpoints, `H-L` is finite in the wider contexts but
overflows in p34, even though every affine result remains between the finite
endpoints.

## File-driven discriminators

Seed `853171` produces

```
U = 0.0000004877239210834499830504487972.
```

For

```
L = -1246406709166367291051921569.364857
H =  2555556632316048886314046525939287
```

an integer evaluation of the affine numerator gives `R=4e-40`.  The former
p39 span gives approximately `1.46317176325035e-12`; the revised p75 span
gives `4e-40`.

Seed `12345` produces

```
U = 0.1142595267481666652178874759295643.
```

With opposite maximum finite endpoints, the independently evaluated value is

```
-7.7148094650366666956422504814087132285190534963333304357749518591286e6144.
```

The existing file-driven suite checks the 34th digit under all seven result
rounding modes by subtraction and scaling.  It also checks the deterministic
unit-interval value, an exact affine cancellation, the p39 failure above, and
the long-integer route's existing behaviour.

## Accuracy claim

For finite real endpoints, the revised route retains the endpoint information
needed for a faithful 34-digit affine result and applies the selected rounding
mode in the final p34 fused operation.  This is not a universal
correct-rounding claim for effects caused by the preceding p75 span rounding.
The accepted p39-to-p34 double-rounding class is outside the comparison with
the former route.

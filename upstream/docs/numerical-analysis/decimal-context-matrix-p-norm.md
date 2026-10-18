# Decimal context analysis for matrix p-norms

## Scope

This analysis covers the real and complex matrix route selected by
`fnPNorm(p)` for integer `p >= 2`, including the Euclidean and Frobenius case
`p=2`.  The zero, one, and infinity selectors use the non-zero count, column
norm, and row norm kernels respectively and require separate analyses.

The selected algorithm retains p39 throughout.  P39 is the narrowest suitable
established context among p34, p39, p51, and p75.  Scaling by the largest
element magnitude removes an avoidable dependency between the integer power
and the wide Real34 exponent range.

## Scaled algorithm

For element magnitudes `a_j`, positive integer `p`, and
`M=max(a_j)`, the norm is evaluated as

```text
M * (sum((a_j/M)^p))^(1/p).
```

Zero matrices return zero before division.  Finite non-zero ratios lie in
`[0,1]`, their powered sum lies in `[1,n]`, and only the final multiplication
returns to the input scale.  Consequently the working exponent no longer
grows in proportion to `p`.

The integer powers use exponentiation by squaring.  A 16-bit positive exponent
requires at most 31 correctly rounded multiplications.  The `p=2` closing root
uses the correctly rounded square root directly.  Other closing roots use
the audited p39 logarithm and exponential after division by the exact integer
value of `p`.

An underflowed scaled term is below the p39 minimum working magnitude relative
to the unit term.  Even the largest permitted matrix cannot make such a term
relevant to a Real34 result.

## Error bounds

For a real matrix, `M` is one exact Real34 magnitude.  For a complex matrix,
each magnitude uses the separately audited p39 `complexMagnitude` kernel with
relative error below `1.01E-38`.  Selecting a nearby computed maximum does not
increase this bound because all candidates approximate their corresponding
exact magnitudes by the same relative factor.

Let `u39=5E-39`.  One scaled ratio has relative input error at most `u39`.
Raising it to `p` amplifies that contribution by at most `p`, while the
exponentiation tree adds at most `gamma_31`.  Both contributions are reduced
by the factor `1/p` when the positive p-th root is taken.  Summing at most
16384 non-negative real terms contributes at most

```text
gamma_16384 < 8.20E-35
```

before the root, and therefore at most `4.10E-35` for every routed `p >= 2`.
The complex storage limit is smaller.  The closing p39 logarithm and
exponential bounds are established separately in
`decimal-context-ln.md` and `decimal-context-exp.md`; on the bounded interval
`1 <= sum <= 16384`, their contribution remains below the Real34 half-ulp
scale with more than one decimal order of margin.  The division, complex
magnitude when present, and final multiplication add only a small fixed
multiple of `u39`.

The resulting claim is faithful 34-digit accuracy rather than universal
correct rounding.  Differences caused solely by the final p39-to-p34
shortening are excluded under the requested double-rounding policy.

## Why p34 is unsuitable

Scaling makes the p34 exponent range sufficient, but not its precision.
A p34 ratio can begin with relative error `u34=5E-34`, which survives the
p-th root, and the closing multiplication introduces another p34 rounding.
For `p=2`, the positive sum can also contribute roughly
`gamma_16384/2` at p34.  These terms exceed the Real34 half-ulp scale before
any logarithm or exponential error is included.  P34 therefore has no
supported final-digit margin.  P51 and p75 reduce an already adequate p39
bound without improving the output format.

## Former range loss

The earlier algorithm formed `a_j^p` before taking the root.  For example,

```text
norm_200([1E5000, 1]) = 1E5000 to Real34 precision,
```

but the intermediate `1E1000000` exceeds the p39 maximum exponent.  The real
route reports an overflow and leaves the input matrix unchanged.  The same
failure affects a complex matrix containing `1E5000+0i`.

At the opposite scale, a powered term can fall below the working exponent
range even though the final norm remains a normal Real34 value.  Scaling keeps
the dominant term equal to one in both cases.

## Special values and tests

A NaN magnitude has priority and produces NaN.  Otherwise an infinite
magnitude produces positive infinity.  A zero matrix produces positive zero.
These cases avoid an indeterminate infinity-over-infinity ratio.

The new cases are incorporated into the existing `matrix.txt` file.  They
cover large and small real and complex matrices at `p=200`, plus zero, NaN,
and infinity.  The former unscaled code succeeds in one of the four range
checks.  The selected implementation succeeds in all eight focused checks and
in all 198 checks from the complete matrix file.

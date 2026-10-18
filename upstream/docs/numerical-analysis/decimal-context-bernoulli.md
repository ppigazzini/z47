# Decimal context analysis for Bernoulli numbers

## Scope and result

This analysis covers `B_n`, the positive even-index sequence `B*_n`, and their
real entry routes. Complex and matrix inputs are rejected by the existing
conversion gate.

| Route | Selected context | Reason |
| --- | ---: | --- |
| `B_0`, `B_1`, and odd `B_n` | context-independent | the results are copied constants or exact zero |
| positive even `B_n` | 39 | zeta is evaluated only at negative odd integers, away from its ill-conditioned zero classes |
| `B*_n = abs(B_(2n))` | 39 | the same negative-odd zeta route applies after an exact index doubling |

P39 uses round-to-nearest, ties-to-even. Decimal128 conversion applies the
selected calculator mode. Differences caused solely by the accepted
p39-to-p34 boundary effect are outside this context choice.

## Formula and conditioning

For an even positive integer `n`, the helper uses

```text
B_n = -n * zeta(1-n).
```

For a positive integer `k`, the starred entry uses

```text
B*_k = abs(-2k * zeta(1-2k)) = abs(B_(2k)).
```

The supplied zeta arguments are therefore negative odd integers. They do not
approach the negative-even trivial zeros or the non-real zeros that require
p75 in the public zeta entry. The functional equation maps the calculation to
positive integral zeta, Gamma, an integral power of `2*pi`, and a sine at an
odd multiple of `pi/2`.

For every finite decimal128 Bernoulli result considered here, the effective
even index is below 2,800. Index doubling, subtracting one, and the final
integer multiplications are exact at p39. The p39 error in the half-integer
angle is below about `2,800*pi*u39`; because sine is evaluated at an extremum,
its relative effect is second order and below `4e-71`.

The 60-term Borwein eta approximation has absolute truncation error below
`3.50e-46`. Its direct-half-plane arithmetic allowance from the zeta audit is

```text
40 * 60^(3/2) * u39 < 9.30e-35.
```

The eta denominator is at least one half for positive integral arguments at
least two. The audited integral-power route contributes at most `1e-38`
relative error, and the Gamma kernel uses p75 Lanczos work before its p39
outer conversion. The remaining multiplications add only a small multiple of
`u39`. The conservative combined scale remains below one decimal128 unit and
supports faithful 34-digit accuracy outside the accepted final-boundary case.

P34 is unsuitable. Repeating the Borwein arithmetic allowance at p34 is near
`9.30e-30`, with no 34-digit margin. Its decimal128 exponent range also
overflows the Gamma factor before multiplication by the small power of
`2*pi`. A deliberate p34 entry produced four focused failures: both precise
`B_20` checks were two decimal128 units wrong, and the finite values `B_2760`
and `B*_1380` reported range errors. P39 is the narrowest established project
context. P51 and p75 reduce an already sub-decimal128 error without a measured
output benefit on this integer subset.

## Zero index of the starred sequence

The implementation and existing positive-index values define

```text
B*_n = abs(B_(2n)).
```

Consequently `B*_0=abs(B_0)=1`. The former zero branch returned NaN even
though its diagnostic required a non-negative integer. The helper now returns
one for zero in both sequences, and the diagnostic consistently describes the
non-negative integer domain.

## Range and special values

Odd ordinary indices above one return exact positive zero before zeta work.
Negative or non-integral inputs produce the established function-domain error.
Inputs beyond the finite Bernoulli range may overflow at the final conversion;
the p39 exponent range prevents premature overflow throughout the sampled
finite region. NaN and infinity fail the integer-domain check.

The result sign is set exactly from the Bernoulli parity. The starred sequence
then sets a positive sign explicitly. No complex or matrix arithmetic is
performed.

## Regression evidence

The two existing file-driven files contain 44 checks after this change. The
former zero rule succeeds for 42 of 44 and fails both `B*_0` cases. The revised
p39 implementation succeeds for all 44. A deliberate p34 substitution
succeeds for 40 of 44; scaled subtraction exposes its two-unit error at
`B_20`, while the high-index cases expose premature range failure.

Exact rational references agree with p39 for every even index through 500 and
for indices 600, 700, 800, 900, and 1,000. P39 and p75 give identical
decimal128 values at sampled indices from 1,200 through 2,760. An independent
160-digit Euler-formula calculation gives

```text
B_2760 = -5.0170376741224697222673680190923218325768141...e6097,
```

which rounds to the value in both file-driven high-index cases. The
repository-wide result is recorded with the change commit.

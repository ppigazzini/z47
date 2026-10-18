# Decimal context analysis for register-range parameters

## Scope

`getRegParam` decodes the Real34 value used by `R-CLR`, `R-SORT`, `R-COPY`, `R-SWAP` and the two `PRN_REGS` routes. `indirectAddressing` decodes a Real34 value stored
in an indirect parameter register. The packed range form is
`sss.NNDDD`: `sss` is the public source-register number, `NN` is a count, and `DDD` is the public destination-register number when the caller requests it.
`R-COPY` also requests the sign bit, using a negative value for partial state loading.

The public number bands are the keystroke-program bands already defined in `defines.h`:

- 0 through 99: numbered global registers;
- 100 through 111: X through K;
- 112 through 210: local registers .00 through .98;
- 211 through 224: M through W.

Each valid source and destination is converted with `regKStoC` after range validation. A zero count selects the entries from the source through the end of its
current band. A range cannot cross between bands. Local-register validation uses the currently allocated count, and negative local sources remain unavailable to the
partial state-load route.

## Defects in the former validation

The former code compared public fields with internal C register numbers. Its local-register branch began at internal number 7000, which a three-digit field cannot
encode. Public 112 therefore selected internal 112, register M, instead of local .00; public 211 through 224 selected unrelated or unavailable internal numbers. Values
between the internal global block and 999 were also accepted despite not identifying a public range entry.

The former Real34 indirect route admitted undefined public values 225 through 255 and local-register values with no corresponding allocation. NaN evaded both ordered
comparisons and reached integer conversion, where it became register 0. Explicit special-value rejection and public-range validation now precede the public-to-internal
conversion. Numeric named-variable values remain valid only when the corresponding named variable exists.

The former upper-bound test used `start + count >= end`. Since `count` is a quantity and each iteration stops before `start + count`, equality is valid. The old test
rejected `99.01`, a one-entry register range ending at R99, and rejected an otherwise valid destination of R99. The replacement validates the half-open
interval with `start + count <= end`.

## Decimal error bound

The Real34-to-`real_t` conversion is exact. For a finite accepted input, `abs(x) < 1000` and the coefficient has at most 34 digits. Each field uses these steps at p39:

1. truncate towards zero with the explicit `DEC_ROUND_DOWN` argument;
2. subtract that integer exactly;
3. increase the decimal exponent by two or three, which changes scale without arithmetic rounding;
4. truncate the next field.

The subtraction result is a suffix of the original decimal coefficient and therefore has at most 34 significant digits. No operation rounds at p39. P34 is also wide
enough for the values, but this is chained work and p34 has no performance advantage over p39. P39 is consequently the narrowest useful established working context.
P51 and p75 preserve no additional source information.

The explicit truncation makes field selection independent of calculator rounding modes 0 through 6. Digits after the requested fields are ignored and cannot round a
field upwards. A Real34 angular tag does not alter the numeric packed form.

NaN and either infinity fail the magnitude check. Negative zero retains its sign when the caller requests the partial-load selector; callers without that selector
reject it in the same way as other negative parameters. The output conversion is entirely integral: accepted public values are at most 224, counts are at most 100,
and `regKStoC` produces at most 7098, all exactly representable by the destination integer types.

The indirect route compares one stored Real34 value with exact integral bounds and converts it to an integer with explicit truncation. These are individual p34
operations on a Real34 value and directly implement the public parameter semantics, so p34 is appropriate and cost-neutral. The conversion has no rounding dependency.
Signed zero becomes public register 0; NaN and either infinity are rejected before conversion. Real34 tags have no effect on the numeric register number.

## Verification

`regmgmt_cov.txt` covers R99 as source and destination, every public-number band, both ends of the local band, zero counts, ranges crossing a band boundary, M/W
translation, an angular tag, negative zero, NaN, infinity, a complex input and a nonzero suffix beyond the selected fields. The direct `R-CLR` and `R-COPY` cases prove
the corrected R99 boundary through the public entry points. Further indirect-addressing cases cover valid global, local and M values, an unavailable local value,
undefined public codes, a finite fractional value under a directed rounding mode, signed zero and NaN.

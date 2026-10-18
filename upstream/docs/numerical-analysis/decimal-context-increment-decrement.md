# Decimal context analysis for increment and decrement

## Scope

This analysis covers the real34, complex34 and time branches of `fnInc` and
`fnDec`.  Integer branches are excluded.

## Error analysis

Each branch changes one stored real34 value by an exactly represented real34
constant:

```
real:          x + 1 or x - 1
complex real:  Re(z) + 1 or Re(z) - 1
time:          x + 3600 or x - 3600
```

Under the requested correctly rounded addition and subtraction assumption, a
single operation in `ctxtReal34` returns the required stored value.  The error
is at most one half ulp in nearest modes and less than one ulp in a directed
mode.  A context below 34 digits cannot represent every possible unchanged
input component, so p34 is minimal.

The former implementation converted the component to `real_t`, operated in
`ctxtReal39`, and converted it back.  The five intermediate digits provided no
accuracy benefit under the accepted result model.  The direct real34 wrappers
also remove three wide temporaries and six conversions across these branches.

The complex imaginary component is not modified.  Time values use seconds
internally, so the exact constant 3600 retains the existing one-hour step.
NaNs, infinities, signed zero, overflow and underflow continue through the
real34 wrapper semantics.

## Decision

Use `real34Add` and `real34Subtract` directly in `incDecReal`, `incDecCplx` and
`incDecTime`.  The existing file-driven miscellaneous suite now includes the
complex-component and time branches in addition to its real cases.

"""Which `zig build` steps are lanes, read off their names.

A build step is a lane when its name ends in one of the suffixes the tree uses:
`_parity` for a differential against c43, `_oracle` for a focused worker-level
one, `_diff` for a script-extracted reference, `_suite` for a grouped set,
`_test` for a Zig test root with its own step, `_spec` for a check against
specified values (a closed form, hand-written expectations, libc), `_golden`
for one against hand-verified recorded values, `_fuzz` for a malformed-input
corpus run through a real load path, and `_asan` for a sanitizer build. `_spec`
and `_golden` are not differentials against c43, and the name says so.

check-parity-lanes-gated.py asks whether each lane is run; the oracle negative
control asks whether each lane can fail. Both read this one list, so a lane one
of them can see the other can too.
"""

import re

LANE_RE = re.compile(
    r"^\s{2}([\w-]+(?:_parity|_oracle|_diff|_suite|_test|_spec|_golden|_fuzz|_asan|-parity|-test))\s",
    re.M,
)

# Steps whose names carry a lane suffix but which check nothing. Each says why.
NOT_LANES: dict[str, str] = {
    "saveload_golden": (
        "Rewrites build/tests/calc_state/save_load_golden.sav from the current build;"
        " it writes the golden saveload_roundtrip reads and asserts nothing itself."
    ),
}


def lane_steps(help_text: str) -> set[str]:
    """The lanes `zig build --help` declares."""
    return set(LANE_RE.findall(help_text)) - set(NOT_LANES)

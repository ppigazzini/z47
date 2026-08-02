# z47-owned generated-artefact baselines

`testPgms.bin` here is **z47's own regeneration baseline**, not a build input.

`zig build testpgms` regenerates it from the item table through z47's port of
upstream's `generateTestPgms`, and CI's "Compare tracked generated artifacts" step
`git diff --exit-code`s it. That makes it a self-regression check on the ported
generator: it fires when z47's generator output changes, whatever the cause.

It is NOT a parity claim, and it deliberately lives outside `upstream/`. It used to
be written into `upstream/res/testPgms/testPgms.bin`, which meant a z47 build product
sat inside the vendored tree and the imported tree could never match its pin.

**Open question, unresolved:** z47's generator emits 22179 bytes; upstream's committed
`res/testPgms/testPgms.bin` is 22205. The item table is byte-identical to upstream's
(2871 rows, held by `audit-item-table-parity.py`), so either z47's port of
`generateTestPgms` diverges from upstream's, or upstream's committed image is stale
against its own generator. Worth settling — it is a 26-byte difference in an artefact
that ships to calculators. The full testSuite passes on either image.

What actually runs and ships is upstream's copy: the host package stages it from the
imported tree, and the simulator and testSuite open `res/testPgms/testPgms.bin`
relative to the imported root.

# Creating my first test

1. Log in to the test server, open **New test** (`/tests/run`).
2. **Base / patch:** branches or commits to compare (e.g. `master` vs your
   feature branch). Both engines are built from source by the workers with
   the net embedded.
3. **Signatures (anti-cheat):** run `./owen2 bench 6` on each build and paste
   the `nodes` counts. Reference for the release net: `32000 nodes,
   bestmove e2e4` at depth 6. Workers reject builds whose bench differs.
4. **Book:** `owen200.epd` (200 varied openings). Time control, threads and
   game count: start small (e.g. STC `10+0.1`, a few hundred games) for a
   smoke test, then scale up.
5. **Submit.** Approval: approvers and 500+ game contributors start
   instantly; otherwise one manual approval.
6. Watch Elo/SPRT live on the test page. Green SPRT = your patch wins and
   can be merged.

Tips: keep one idea per test, use separate tests for STC and LTC, and never
edit a running test's core parameters (it un-approves the run).

Every field and flag is documented in [[Commands]].

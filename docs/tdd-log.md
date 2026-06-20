# TDD audit log

This repository follows **strict test-driven development**. Every behavioral or
interface change to the library is preceded by a test that is first shown to
**fail** — either it does not compile (the interface does not exist yet) or it
fails an assertion (the behavior is wrong) — and only then is the code written to
make it pass. This log records each cycle so the test-first ordering can be
audited (cross-check against the git history of `tests/` vs `src/`).

Each entry: the date, what changed, the **RED** evidence (the failing test and
the exact compiler/AUnit failure), and the **GREEN** evidence (the code change
and the passing result).

---

<!-- newest entries on top -->

_(Protocol established 2026-06-20. First entry will accompany the first
behavioral change made under it.)_

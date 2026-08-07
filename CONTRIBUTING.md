# Contributing to Universal SQL Transpiler

Thanks for your interest in improving UST. This guide covers the local setup, project conventions, and how to submit a change.

## Getting set up

See [RUNNING_LOCALLY.md](RUNNING_LOCALLY.md) for backend/frontend setup, or run `setup.ps1` (Windows) / `setup.sh` (Linux/macOS) from the repository root for a one-command install.

## Project structure

See the [Project Structure](README.md#project-structure) section of the README for an overview of `backend/app/dialects/`, the IR layer, and the frontend component tree.

## Adding or fixing a dialect

Each dialect lives in `backend/app/dialects/<name>/` as a `parser.py` (source SQL → IR) and `generator.py` (IR → target SQL). Both extend the shared base classes in `backend/app/dialects/base.py`.

- **Type mappings** live in `backend/app/type_mappings/type_mappings.yaml`. When adding a native type string as an `aliases` entry for reverse (source→generic) parsing, check it doesn't collide with another `GenericType`'s primary `type` string for the same dialect — if a dialect's native type space is coarser than the generic type system (e.g. BigQuery has one integer type covering four generic widths), mark the narrower entries `reverse_match: false` so only the canonical (usually widest) entry claims that string on parse.
- **View/MV body function conversion** happens via the regex helpers in `base.py` (`_convert_*`, `_apply_*_view_conversions`). These run against text that has been masked by `_mask_protected_spans`/`_unmask_protected_spans` so string literals, quoted identifiers, and comments are never rewritten — any new converter that needs to *read* a literal's actual content (e.g. a quoted date-part name) must run **before** masking in its `_apply_*_view_conversions` chain, not after; see the comments at the top of `_apply_tsql_view_conversions` for the reasoning and an example.
- Every dialect's parser should handle **both** inline column-level `PRIMARY KEY` (`exp.PrimaryKeyColumnConstraint`) and table-level `PRIMARY KEY (col, ...)` (`exp.PrimaryKey`) — check `oracle/parser.py` or `bigquery/parser.py` for the pattern if you're adding a new dialect.

## Tests

```bash
cd backend
.\.venv\Scripts\Activate.ps1   # or source .venv/bin/activate on Linux/macOS
pytest -q
```

- Golden-file snapshot tests (`test_phase6_golden.py`) compare generated SQL against files in `backend/tests/golden/`. If your change intentionally alters generated output, regenerate with `pytest tests/test_phase6_golden.py --regen-golden` and **review the diff carefully** before committing — a passing regen doesn't mean the new output is correct, only that it's now the recorded baseline.
- Add a regression test for any bug fix, not just a manual repro — the fastest way for a fix to silently regress later is for it to have no test.
- Run the full suite (not just the file you touched) before opening a PR; cross-dialect changes (e.g. to `base.py` or `type_mappings.yaml`) can affect generators you didn't directly edit.

## Submitting a change

1. Fork and branch from `main`.
2. Keep PRs focused — one fix or feature per PR is easier to review than a bundle of unrelated changes.
3. Make sure `pytest -q` (backend) and `npm run build` (frontend, if you touched it) both pass.
4. Describe *why* the change is needed, not just what changed — link to the bug/issue if there is one.
5. CI (`.github/workflows/ci.yml`) runs automatically on your PR; fix any failures before requesting review.

## Reporting bugs

Open an issue with: the source SQL, source and target dialect, the actual output, and what you expected instead. For translation-correctness bugs, a minimal repro (a few columns, not your full production schema) is much easier to act on than a large real-world DDL dump.

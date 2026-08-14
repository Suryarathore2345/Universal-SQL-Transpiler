# Git & GitHub Workflow — Mandatory for Every Change

These rules are mandatory for every change made to this repository: every feature,
enhancement, bug fix, refactor, documentation update, UI change, configuration
change, or any other modification.

> **Note on branch naming:** this repository's trunk branch is `master`, not `main`.
> Every rule below that references `main` applies to `master` here — read `main` as
> `master` throughout. Do not create a `main` branch to match the letter of these
> rules; follow their intent against the actual trunk.

## 1. Never work directly on the trunk branch (`master`)

Never make changes directly on `master`. Do not:
- edit files and commit on `master`
- create commits on `master`
- push changes directly to `master`
- use `git commit` while currently checked out on `master`
- use `git push origin master` for development changes

`master` must always remain the stable/integrated branch.

Before making ANY modification, verify the current branch:

```bash
git branch --show-current
```

If the current branch is `master`, create and switch to a feature branch before
modifying files.

## 2. Always create a feature branch first

Every piece of work starts with a new feature branch.

Branch naming format:

```text
feature/<short-concise-name>
```

The name must:
- start with `feature/`
- be lowercase
- use hyphens
- be short
- clearly describe the change
- avoid unnecessary words

**Good:** `feature/landing-animation`, `feature/readme-redesign`, `feature/sql-editor-ui`, `feature/warning-panel`, `feature/dialect-selector`, `feature/api-validation`, `feature/conversion-history`

**Bad:** `feature/my-new-feature`, `feature/update`, `feature/changes`, `feature/fixing-stuff`, `feature/this-is-a-very-long-feature-branch-name`

## 3. Create the branch from an updated trunk

```bash
git checkout master
git pull origin master
git checkout -b feature/<concise-feature-name>
```

Example:

```bash
git checkout master
git pull origin master
git checkout -b feature/landing-animation
```

Only after this step may modifications begin.

## 4. Do all work on the feature branch

All code, UI, documentation, configuration, tests, assets, and other changes happen
on the feature branch. Never switch back to `master` during development unless
necessary for the merge workflow.

## 5. Verify the branch before committing

```bash
git branch --show-current
```

If the result is `master` — **stop**. Do not commit. Switch to the appropriate
feature branch first.

## 6. Commit message format

Commit messages must be short, simple, and descriptive. Use one of these prefixes,
followed by a space and a concise description:

```text
feat- add landing animation
fix- resolve editor loading issue
refactor- simplify conversion flow
docs- redesign project readme
style- improve editor layout
test- add dialect validation tests
chore- update frontend dependencies
```

Valid prefixes: `feat-`, `fix-`, `refactor-`, `docs-`, `style-`, `test-`, `chore-`.

**Bad:** `feat- added a really cool and amazing landing animation to make the website look better`, `fix- fixed some bugs`, `update everything`, `changes`, `final changes`, `minor changes`, `new stuff`

## 7. Never use co-authored commits

This repository must never contain `Co-authored-by: Claude`, `Co-authored-by:
Anthropic`, or any equivalent AI attribution in git commit messages or trailers.
All commits must be authored under the repository owner's configured git identity.

Verify before committing if needed:

```bash
git config user.name
git config user.email
```

Do not change the user's git identity unless explicitly instructed. Claude must
never represent itself as a co-author.

## 8. Test before committing

Before the final commit:
1. Review the changed files.
2. Run the appropriate tests (`pytest` in `backend/` for backend changes).
3. Run the frontend build if frontend code changed (`npm run build` in `frontend/`).
4. Check for lint/type/build errors where applicable.
5. Verify the application still works — use the browser preview for UI changes.

Then inspect:

```bash
git status
git diff
```

## 9. Commit only the intended changes

Before committing, make sure the working tree contains only changes related to the
current feature/fix. Review `git status` and `git diff`. Do not accidentally commit
`.env`, credentials, secrets, API keys, temporary files, build artifacts, IDE files,
unrelated modifications, debugging files, or local configuration.

## 10. Push the feature branch

```bash
git push -u origin feature/<branch-name>
```

Never push development changes directly to `origin/master`.

## 11. Merge into the trunk branch

Once the feature branch is complete and validated, merge it into `master`.

If working entirely through the local git workflow and explicitly instructed to
perform the merge:

```bash
git checkout master
git pull origin master
git merge --no-ff feature/<branch-name>
git push origin master
```

If the repository uses Pull Requests, prefer: push branch → create PR → review/
validation → merge PR → `master`. Do not bypass repository branch protection.

## 12. The trunk branch must only receive completed work

`master` should contain only completed features, tested fixes, reviewed changes,
stable documentation, and validated configuration. Do not merge unfinished,
broken, or purely experimental work.

## 13. After merging

```bash
git checkout master
git pull origin master
git status
git branch --show-current
```

The final state should be on `master` with a clean working tree, unless there are
intentional uncommitted changes.

## 14. Feature branch cleanup

After a successful merge, delete the feature branch if no longer needed:

```bash
git branch -d feature/<branch-name>
git push origin --delete feature/<branch-name>
```

Only delete after confirming the changes reached `master`.

## 15. Multiple changes

If a task contains multiple logically separate features, do not put everything
into one giant branch — use one branch per coherent change (e.g.
`feature/landing-animation`, `feature/readme-redesign`,
`feature/dialect-selector` as separate branches). If multiple changes are tightly
coupled and must ship together, one feature branch is acceptable.

## 16. Do not create random branches

Do not create branches such as `dev`, `development`, `testing`, `temp`, `test`,
`changes`, `work`, `claude`, `ai`, `experimental`, `new-version`, `final`,
`final-final`. Use the required `feature/<concise-name>` format.

## 17. Emergency / hotfixes

Even for urgent fixes, do not modify `master` directly unless the repository owner
explicitly instructs bypassing this workflow. Normally use
`feature/<concise-fix-name>` (e.g. `feature/fix-api-timeout`), then follow the same
branch → change → test → commit → push → merge workflow.

## 18. Required workflow summary

```text
1. Check current branch
2. Update master
3. Create feature/<concise-name>
4. Switch to feature branch
5. Implement changes
6. Test & validate
7. Review git diff
8. Commit with feat-/fix-/etc.
9. Push feature branch
10. Create PR / merge feature
11. Update local master
12. Verify clean master
```

## 19. Absolute rules

**Never:** commit directly to `master` · push directly to `master` during
development · work on `master` · use vague commit messages · add
`Co-authored-by: Claude` or `Co-authored-by: Anthropic` or any AI attribution ·
commit secrets · merge untested work · create unnecessarily long or generic
branch names.

**Always:** create `feature/<concise-name>` · work on the feature branch · test
before committing · review `git diff` · use concise conventional commit prefixes ·
use the user's configured git identity · push the feature branch · merge the
completed feature into `master` · verify `master` after merging.

**Golden rule:** No change goes directly into `master`. Every change follows:
Feature Branch → Build → Test → Commit → Push → Review/Merge → `master`.

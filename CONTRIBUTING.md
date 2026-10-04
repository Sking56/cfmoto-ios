# Contributing

Read the MVP brief, `docs/engineering/STATUS.md`, `MVP_TASKS.md`, and `PRODUCT_REQUIREMENTS.md` before changing code. Inspect Git status, branch, recent history, tags, and existing tests first.

Use small Conventional Commit changes on short-lived `research/`, `docs/`, `feat/`, `fix/`, or `test/` branches. Concurrent agents use separate worktrees. The coordinator owns integration. Keep behavior tests and affected engineering documentation with each implementation change.

Every completed task records requirements, dependencies, branch, owner, acceptance criteria, tests, documentation, independent review, and its merge SHA. Verification records identify the tested commit and actual environment. Do not label unavailable Xcode or hardware checks as passing. Add milestone tags only when the documented gate is reviewed and verified.

Promote capabilities into product features only after verification, including physical hardware checks where needed. Preserve meaningful research history; do not rewrite shared history or force push. Never commit credentials, real pairing passwords, recordings, or private diagnostics. Fixtures must be synthetic or explicitly sanitized and have provenance.

Before completion, run relevant checks, update status and tasks, inspect the diff, and commit coherent work. Licensing is pending: record upstream references and reuse decisions before importing code or dependencies. There is no contributor license grant or dual-license policy yet.


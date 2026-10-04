# Gate 0 research review and integration record

2026-10-04. Scope: repository/research assignment; user requested a committed handoff to Mac. Architecture and implementation are future tasks.

| Workstream | Reviewed revision | Independent reviewer / evidence | Merge |
|---|---|---|---|
| Foundation | 51df63b86002f749b2ae5d93e3b4fa3837a7d7a9 | Capture researcher; clean archive, generator consistency, 8 tests; CROSS_REVIEW | Direct commits retained |
| Protocol | 842f8a5fdf316268b782d2de7d1202274de3c0f4; attribute follow-up ac5988d7ecf6a07c19f770d90e96d29ce2e97dc8 | Coordinator; pinned headers/media handlers/RsaKeys inspected, generator/test code reviewed, 17 tests and canonical source hashes pass | 9aab7be1831b674c06ae47dc6109eb05ae5c09a5 |
| Capture | 0225415ed475fafaa7e9070d806a06710e02d0bd | Coordinator; Apple iOS sample/background pages independently fetched; metadata and device probe reviewed | 4dfa9cf8c38967337b8acda1492df9b1bb1a128e |
| Networking | ea29a98e54801039116d9f0f377184dbf44a3a5e | Coordinator; joinOnce/TN3179 independently fetched; listener role, entitlement, consent/routing caveats checked; 8 tests pass | 0ddff39c576c8087e94059ef6459152465c5b83d |
| Licensing | 7b4d8b9d475c25e1aec1799ec9ffaea49108de60 | Capture researcher; matching clean LICENSE/NOTICE/README/dependencies/headers audit; CROSS_REVIEW | 9c6686360a1dd9c05e49ba3d180ca2ac8ff455ef |
| Cross-review record | 7d36ff4b6613b99af4670ea4dbb82151f490a60a | Coordinator reviewed report/targets | 7c1a0af1db673da4fdd056be67777c28ebcb2ce0 |

Protocol merge conflicts in fixture README/attributes were resolved preserving provenance and byte-preservation rules. All 17 tests and deterministic checks passed after resolution. No shared history was rewritten.

Resolved research findings: licensing's false QrData SPDX-header claim was corrected in a follow-up commit; RSA lifetime wording now describes a process-memory singleton spanning sessions. No unresolved actionable research-review defect remains. Native/hardware questions remain explicit in [RISKS.md](../RISKS.md).

Source integration tested: 9aab7be1831b674c06ae47dc6109eb05ae5c09a5. Environment: Windows / PowerShell / Python 3.14.3; no local Xcode/Swift/SDK/iPhone runtime.

- Repository validation: PASS.
- All 17 portable tests: PASS (8 foundation/selection, 9 research fixture).
- All 36 deterministic artifacts: match, including 33 binary vectors.
- Canonical upstream hashes: PASS against 0abbe2a70119d6dd46ac6b8a0715ff267fcdb316 Git blob bytes.
- Native build/analyzer/UI/signing: UNVERIFIED; native verifier reports unavailable environment.
- Production protocol core, Dash Simulator session, authenticated reply, actual decoded video, phone/bike tests: NOT IMPLEMENTED / NOT RUN.
- Hosted CI: NOT RUN; no remote configured.

After the handoff commit, a verifier checks a fresh detached worktree. Its exact SHA/results are recorded in the annotated mvp-gate-0 tag, created only after portable checks pass. Use git show mvp-gate-0 for that immutable record. This research milestone does not certify a native build or hardware feasibility.

Required Gate0 documents exist: PRODUCT_REQUIREMENTS, OPENCFMOTO_RESEARCH, EASYCONNECT_PROTOCOL, IOS_PLATFORM, RISKS, LICENSING. Four research workstreams are reviewed/merged. The repository license decision placeholder is retained as the brief permits; no distribution grant or release is asserted.

Next: [MAC_HANDOFF.md](../MAC_HANDOFF.md), native foundation checks, then architecture from merged research and staged protocol/simulator/video/capture/hardware implementation. Architecture placeholders are not approved specifications.

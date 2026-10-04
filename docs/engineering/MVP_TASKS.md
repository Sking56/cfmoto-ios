# MVP task tracking

Every row records Task ID, requirements, description, dependencies, branch, owner, acceptance criteria, tests, documentation, review status and merge commit. Pending values are intentional.

| Task | Requirements | Description / acceptance | Dependencies | Branch | Owner | Tests / docs | Review | Merge |
|---|---|---|---|---|---|---|---|---|
| MVP-001 | REQ-DOC-001, REQ-GIT-001, REQ-TEST-002 | Repository foundation; portable checks pass; native build separately recorded | None | main | Coordinator | repository checks; indexes/status | Pending | Pending |
| MVP-002 | REQ-PAIR-001, REQ-PROJ-001 | Pin upstream; document QR, framing, session, heartbeat, video and fixture provenance | MVP-001 | research/easyconnect-protocol | Protocol researcher | fixtures; OPENCFMOTO_RESEARCH, EASYCONNECT_PROTOCOL | Pending | Pending |
| MVP-003 | REQ-CAP-001, REQ-CAP-002, REQ-VID-001 | Establish iOS 27 API and background-capture evidence with unknowns | MVP-001 | research/ios-screen-capture | Capture researcher | IOS_PLATFORM; later device probe | Pending | Pending |
| MVP-004 | REQ-NET-001, REQ-NET-002, REQ-NET-003 | Document join, local permission, Wi-Fi routing and cellular limits | MVP-001 | research/ios-networking | Network researcher | NETWORKING; later device probe | Pending | Pending |
| MVP-005 | REQ-DOC-001 | Audit upstream license/notices and record reuse boundary | MVP-001 | research/licensing | Coordinator | LICENSING; source audit | Pending | Pending |
| MVP-006 | REQ-DOC-001, REQ-GIT-001 | Independently review all research; record verified Gate 0 revision | MVP-002..005 | docs/research-verification | Reviewer / coordinator | review records; risks; status | Pending | Pending |
| MVP-007 | REQ-DOC-001 | Architecture from merged research only | MVP-006 | docs/system-architecture | Architecture agent | SYSTEM_ARCHITECTURE, STATE_MACHINE, VIDEO_PIPELINE, TEST_ARCHITECTURE | Pending | Pending |
| MVP-008 | REQ-PAIR-001, REQ-PROJ-001, REQ-TEST-001 | Gate 1: protocol core, state machine, fixtures, simulator handshake | MVP-007 | feat/easyconnect-core | Pending | Native tests plus independent simulator | Not started | Pending |
| MVP-009 | REQ-VID-001, REQ-TEST-001 | Gate 2: synthetic projection to simulator | MVP-008 | feat/synthetic-projection | Pending | Deterministic frame integration | Not started | Pending |
| MVP-010 | REQ-CAP-001, REQ-CAP-002 | Gate 3: real capture to simulator with Waze foreground | MVP-009 | feat/screen-capture | Pending | Physical iPhone evidence | Not started | Pending |
| MVP-011 | REQ-PROJ-005 | Gate 4: HELLO 450NK test pattern on TFT | MVP-009 | test/450nk-pattern | Pending | Hardware record | Not started | Pending |
| MVP-012 | REQ-PROJ-005, REQ-TEST-003 | Gates 5/6: full mirroring, 30 minutes, interruption, diagnostics, clean install | MVP-010, MVP-011 | test/mvp-hardware | Pending | Independent hardware acceptance | Not started | Pending |

# Project status

Updated 2026-10-04 for the user's requested move from Windows to Mac.

Current stage: Gate 0 research reviewed and integrated. The first Mac baseline is recorded in [MAC_BASELINE.md](verification/MAC_BASELINE.md); candidate architecture has been written on `codex/architecture-protocol-core`, with independent review pending. Gate 1 implementation is next. The existing annotated mvp-gate-0 tag records its original tested revision/results and certifies research, not native build or hardware feasibility.

Completed: dependency-free SwiftUI launch skeleton, shared Xcode scheme/UI launch test, engineering/product documentation, stable requirements/tasks, CI configuration, and four independently reviewed research branches with merge history. Protocol/licensing pin upstream zanderp/open-cfmoto at 0abbe2a70119d6dd46ac6b8a0715ff267fcdb316. There are 33 invented binary protocol vectors, three metadata/QR outputs, a deterministic generator, and 42 Apple DocC metadata records. Synthetic video is non-decodable; no production protocol core or Dash Simulator exists.

Source integration revision: 9aab7be1831b674c06ae47dc6109eb05ae5c09a5. Final handoff documentation follows it. See [Gate 0 evidence](verification/GATE_0.md) and [independent cross-review](verification/CROSS_REVIEW.md) for exact review/merge revisions.

Verification on Windows / PowerShell / Python 3.14.3: repository validation PASS; all 17 portable tests PASS; all 36 generated artifacts match; pinned canonical upstream blob digests PASS. No unresolved actionable research-review findings remain after recorded corrections.

UNVERIFIED: Xcode/Swift compilation, analyzer, UI launch, signing, capture, association/routing, crypto interoperability, projection, recovery, stop/restoration and 30-minute endurance. Hosted CI results must be checked for the specific uploaded revision. Native verifier explicitly reports this unavailable Windows environment.

The user reports Mac, physical iPhone and 450NK availability and requested committing before moving. Origin is git@github.com:Sking56/cfmoto-ios.git. On the requested retry, SSH succeeded with the newly configured identity; the remote was empty. Main at e751ca14e899da8b625b825fb7b1f6b9f56d5163, all four research branches and mvp-gate-0 were atomically uploaded, tracking branches configured, and remote refs independently read back. This documentation update follows that verified upload. Clone directly on the Mac using [MAC_HANDOFF.md](MAC_HANDOFF.md). The historical Gate 0 verification/tag still identifies its original tested revision and environment; upload does not verify native or hardware behavior.

Mac baseline: portable repository check and all 17 tests PASS with Python 3.12.14 on `cd5d9a47aada71f211b0d8f73eff180dd89f87e5`. Xcode 16.2 (16C5032a) provides iOS 18.2; native verifier exits 2, UNVERIFIED because iOS 27+ SDK is absent. Swift 6.0.3 is available for host core tests. Preserve the iOS target and use host testing to implement protocol core/independent simulator before synthetic video, real capture and hardware gates.

Open questions: 450NK AP/P2P mode and firmware, Android identity/RSA mapping, raw-video/trailer acceptance, video-only background lifetime, cellular coexistence and TFT restoration. See [RISKS.md](RISKS.md). Owner license choice remains pending before distribution. Main is the integration branch; four research branches are retained. No implementation PR, installable build or alpha release exists.

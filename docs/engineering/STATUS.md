# Project status

Updated 2026-10-04 for the user's requested move from Windows to Mac.

Current stage: Gate 0 research reviewed and integrated. Architecture and Gate 1 implementation have not started. The annotated mvp-gate-0 tag is created only after fresh-checkout portable verification; its message records the exact tested revision and results. It certifies research, not native build or hardware feasibility.

Completed: dependency-free SwiftUI launch skeleton, shared Xcode scheme/UI launch test, engineering/product documentation, stable requirements/tasks, CI configuration, and four independently reviewed research branches with merge history. Protocol/licensing pin upstream zanderp/open-cfmoto at 0abbe2a70119d6dd46ac6b8a0715ff267fcdb316. There are 33 invented binary protocol vectors, three metadata/QR outputs, a deterministic generator, and 42 Apple DocC metadata records. Synthetic video is non-decodable; no production protocol core or Dash Simulator exists.

Source integration revision: 9aab7be1831b674c06ae47dc6109eb05ae5c09a5. Final handoff documentation follows it. See [Gate 0 evidence](verification/GATE_0.md) and [independent cross-review](verification/CROSS_REVIEW.md) for exact review/merge revisions.

Verification on Windows / PowerShell / Python 3.14.3: repository validation PASS; all 17 portable tests PASS; all 36 generated artifacts match; pinned canonical upstream blob digests PASS. No unresolved actionable research-review findings remain after recorded corrections.

UNVERIFIED: Xcode/Swift compilation, analyzer, UI launch, signing, capture, association/routing, crypto interoperability, projection, recovery, stop/restoration and 30-minute endurance. Hosted CI NOT RUN; no remote configured. Native verifier explicitly reports this unavailable Windows environment.

The user reports Mac, physical iPhone and 450NK availability and requested committing before moving. No SSH connection was requested or used. Transfer build/OpenCFMoto-iOS-handoff.bundle and follow [MAC_HANDOFF.md](MAC_HANDOFF.md).

Next on Mac: inspect repository/tasks; run portable and native foundation checks; record exact environment/SHA; then assign architecture from merged research. Architecture files remain placeholders. Implement protocol core/independent simulator before synthetic video, real capture and hardware gates.

Open questions: 450NK AP/P2P mode and firmware, Android identity/RSA mapping, raw-video/trailer acceptance, video-only background lifetime, cellular coexistence and TFT restoration. See [RISKS.md](RISKS.md). Owner license choice remains pending before distribution. Main is the integration branch; four research branches are retained. No implementation PR, installable build or alpha release exists.

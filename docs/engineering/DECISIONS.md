# Architecture decisions

ADR-001 — Research before implementation. Context: the brief mandates staged protocol/platform/licensing research. Decision: initialize a minimal dependency-free SwiftUI skeleton and independent workstreams before protocol or capture implementation. Alternative: implement guessed protocol immediately. Consequences: no advertised mirroring capability until verification. Status: accepted.

ADR-002 — Deployment target. Context: brief targets iOS 27+. Decision: preserve 27.0 in the project; require matching SDK/runtime and record unavailable builds honestly. Alternative: silently lower the target. Consequences: contributors need suitable Xcode. Status: accepted pending SDK/device validation.

ADR-003 — License pending. Context: owner has not selected a license. Decision: keep an explicit placeholder and audit reference obligations before reuse. Alternative: choose an arbitrary license. Consequences: no redistribution grant is asserted. Status: pending owner decision for later distribution.

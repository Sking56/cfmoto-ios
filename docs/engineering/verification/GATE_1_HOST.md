# Gate 1 host candidate verification

Date: 2026-10-04. Implementation revision tested: `7a377f0e06dee79c989609bdd87e0c1df868bf11`. Architecture candidate: `ca5553507a8ff304a2232ac74aa210b2b6ab178e`. Integration base: `cd5d9a47aada71f211b0d8f73eff180dd89f87e5`.

Historical baseline: the later bounded-writer revision, current toolchain results and independent review are recorded in [Gate 1 hardening](GATE_1_HARDENING.md). The original results/disposition below describe this earlier snapshot, not current pending-review or SDK status.

A fresh detached checkout of the implementation commit was created at `.worktrees/gate1-verification`. Its tracked/untracked status was empty before testing and remained empty afterward; generated caches/builds are ignored. The original checkout's pre-existing untracked Xcode workspace was not included or modified. This is coordinator verification and self-review, not independent approval.

Environment: macOS 14.6.1 (23G93), Xcode 16.2 (16C5032a), Apple Swift 6.0.3, macOS SDK 15.2, iOS/iOS Simulator SDK 18.2, bundled Python 3.12.14. The shell's Python 3.8 is below the documented prerequisite. Local socket tests required sandbox escalation for loopback bind/connect; no dashboard, phone or external network endpoint was contacted.

## Results

| Check | Result |
|---|---|
| `python3 Tools/verify_repository.py` | PASS: structure, documentation links, scheme and core Xcode references |
| `python3 -m unittest discover -s Tests -p 'test_*.py' -v` | PASS: 22 tests; includes fixture regeneration/hash checks and independent peer rejection tests |
| `python3 Tools/verify_gate1.py` | PASS: fresh Swift compile, 15 XCTest tests and seven independent socket cases |
| `python3 Tools/generate_xcode_project.py`, then `git status --porcelain` | PASS: no source/project/scheme changes; deterministic regeneration |
| `plutil -lint OpenCFMoto.xcodeproj/project.pbxproj` | PASS: OpenStep project syntax; not an app build |
| `python3 Tools/verify_xcode.py` | UNVERIFIED, exit 2: active Xcode has no iOS 27+ simulator SDK |

The Swift suites exercise every valid/negative committed wire fixture, every split point, coalesced/one-byte reads, signed tokens, reserved/unknown command fields, bounded lengths and 1,500 deterministic malformed-input cases. QR tests cover the reviewed fixtures, UTF-8, form decoding, missing/invalid fields and redaction. Negotiation/state tests cover typed Boolean wake, exact fixture replies, geometry/encoder rejection, missing identity, complete evidence, stale generations and first-failure preservation.

The independent Python peer accepts wake and initiates two PXC plus media-control/data callbacks. Socket cases: successful complete negotiation with one-byte writes; successful negotiation with coalesced requests; rejected wake; invalid XOR; duplicate PXC channel; DATA_START before complete readiness; callback disconnect. Both peers use the explicit `synthetic-no-crypto` profile. A success ends after DATA_START and an empty DATA_NEXT, with zero video frames; connection closure is probe termination, not the proposed production idle/pull policy.

## Disposition

MVP-007 architecture and MVP-008 core/simulator are reviewable candidates on `codex/architecture-protocol-core`. No independent architecture or implementation reviewer has approved them, no merge to main occurred, and no Gate 1 milestone tag was created. New CI configuration is committed but hosted runs have not been checked or triggered by this session. This local branch has not been pushed.

UNVERIFIED: native iOS app compilation/analyzer/UI launch, signing, iOS unit-test target, production phone transport and recovery timers, hardware CLIENT_INFO/RSA, association/cellular routing, capture/background lifetime, decodable video, 450NK projection/restoration and 30-minute endurance. Pure state generation checks are not proof of transport/capture teardown. The Swift core is included in the Xcode app's source phase, but the UI remains the launch skeleton.

Next work: independent architecture/protocol review; run the native verifier on a matching iOS 27+ toolchain; resolve the identity/provider and device feasibility probes; then implement Gate 2 encoded synthetic media, pull delivery and IDR recovery. Keep product support claims at research/prototype status until the applicable native and hardware gates pass.

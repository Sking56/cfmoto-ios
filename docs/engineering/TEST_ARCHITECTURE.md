# Test architecture

MVP-007 candidate specification, 2026-10-04; independent review pending. REQ-TEST-001, REQ-TEST-002. Keep research fixtures, Swift behavior and the independent peer distinct.

## Layers

| Layer | Tests | What a pass establishes |
|---|---|---|
| Portable foundation | Python repository/link/project checks and fixture regeneration/hash tests | Structure and pinned synthetic evidence only |
| Swift host core | Dependency-free package XCTest suites on the installed Swift toolchain | QR, wire bytes, incremental parser safety, negotiation and pure state behavior |
| Independent peer | Python standard-library dashboard implementation, without importing Swift/research codecs | Independent framing, channel roles and synthetic handshake expectations |
| Host integration | Swift phone listeners/outbound wake against Python dashboard on loopback | Real socket callback directions, split/coalesced bytes, typed rejection and bounded exit |
| Native foundation | `Tools/verify_xcode.py` build/analyze/UI test with iOS 27+ SDK/runtime | App compilation and skeleton launch at the exact SHA |
| Synthetic video | Decode actual encoded output and exercise pulls/drop/keyframe recovery | Gate 2 media path, not hardware compatibility |
| Physical | Signed iPhone plus recorded OS/450NK firmware/consent/routing/background/restoration/endurance | Only the named device cases tested |

Host tests compile the same core files intended for the app; platform adapters remain separate. Use Swift 6 and Foundation, with XCTest and no downloaded packages. The project generator must keep app source membership in sync as core files arrive. Preserve the iOS deployment target; macOS host testing cannot certify iOS 27 framework availability.

## Adversarial coverage

QR tests cover reviewed examples, duplicate/case-normalized keys, form `+` semantics, password whitespace, UTF-8, missing fields, malformed percent escapes, oversized input and redacted descriptions. Wire tests consume every committed valid/negative fixture, all split points, one-byte chunks, multiple complete messages plus a partial tail, nonzero reserved/token fields, unknown commands, invalid lengths/XOR, EOF and terminal decoder failure. Encoded output is checked against independent frozen bytes, not only round trips.

Negotiation tests require the complete evidence set, reject bad capture fields and identity absence, distinguish parsed JSON Boolean true from text containing true, enforce channel command policy and stale-generation cancellation. Writer tests hold completion indefinitely to prove in-flight bytes still consume capacity, enforce byte/count limits, preserve FIFO and atomic multi-reply admission, isolate connection budgets, and reject writes/completions after close. This deterministic test does not rely on operating-system socket-buffer sizes to simulate a stall.

Integration includes rejected/delayed wake, malformed XOR, oversized header, truncated EOF, unknown command, missing/duplicate PXC channel, duplicate media callback, early DATA_START/DATA_NEXT and disconnect. Verify typed termination reasons, not merely a nonzero exit that could hide a timeout. Later fault cases add production deadlines, changed IP, stalled pulls, encoder drops and consent revocation.

Record exact tested SHA, dirty-state qualification, tool/OS versions, commands, pass counts and unavailable checks. A test executable using synthetic identity must label it explicitly and cannot satisfy hardware authentication. Independent reviewer/verifier approval remains a separate gate from coordinator self-review. No milestone tags or product promotion while required evidence is absent.

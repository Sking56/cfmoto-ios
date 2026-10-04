# OpenCFMoto protocol research

MVP-002; REQ-PAIR-001 / REQ-PROJ-001, with findings for REQ-VID-001 / REQ-REC-001 / REQ-TEST-001. Audited 2026-10-04. No iPhone or motorcycle was used. This is a source audit, not an interoperability result.

## Pinned evidence

Primary reference: [zanderp/open-cfmoto](https://github.com/zanderp/open-cfmoto), `main` at **`0abbe2a70119d6dd46ac6b8a0715ff267fcdb316`**, upstream commit dated 2026-09-15. Licensing research uses the same revision. Local clone: ignored `.research/open-cfmoto`; no upstream application source was vendored. To reproduce, clone upstream and check out this SHA. [Fixture provenance](../../Tests/Fixtures/protocol-provenance.json) records source SHA-256 digests and generation method; fixtures validate without the clone.

Evidence IDs used in [EASYCONNECT_PROTOCOL.md](EASYCONNECT_PROTOCOL.md):

| ID | Pinned primary source | Evidence |
|---|---|---|
| S1 | [QrData.kt](https://github.com/zanderp/open-cfmoto/blob/0abbe2a70119d6dd46ac6b8a0715ff267fcdb316/app/src/main/java/dev/zanderp/opencfmoto/QrData.kt) | QR parser/action mask |
| S2 | [EasyConnDiscovery.kt](https://github.com/zanderp/open-cfmoto/blob/0abbe2a70119d6dd46ac6b8a0715ff267fcdb316/app/src/main/java/dev/zanderp/opencfmoto/EasyConnDiscovery.kt) | NSD/endpoint/fallback scan |
| S3 | [EasyConnProber.kt](https://github.com/zanderp/open-cfmoto/blob/0abbe2a70119d6dd46ac6b8a0715ff267fcdb316/app/src/main/java/dev/zanderp/opencfmoto/EasyConnProber.kt) | TCP roles, media framing, pull video, stop/retry/heartbeat |
| S4 | [PxcFrame.kt](https://github.com/zanderp/open-cfmoto/blob/0abbe2a70119d6dd46ac6b8a0715ff267fcdb316/app/src/main/java/dev/zanderp/opencfmoto/PxcFrame.kt) | CmdBaseHead and constants |
| S5 | [PxcHandshake.kt](https://github.com/zanderp/open-cfmoto/blob/0abbe2a70119d6dd46ac6b8a0715ff267fcdb316/app/src/main/java/dev/zanderp/opencfmoto/PxcHandshake.kt) | Callback dispatch/CLIENT_INFO/CHECK_SN |
| S6 | [BikeProfile.kt](https://github.com/zanderp/open-cfmoto/blob/0abbe2a70119d6dd46ac6b8a0715ff267fcdb316/app/src/main/java/dev/zanderp/opencfmoto/BikeProfile.kt) | Identity/capabilities/profile/rounding |
| S7 | [RsaKeys.kt](https://github.com/zanderp/open-cfmoto/blob/0abbe2a70119d6dd46ac6b8a0715ff267fcdb316/app/src/main/java/dev/zanderp/opencfmoto/RsaKeys.kt) | RSA HUID transformation |
| S8 | [VideoPipeline.kt](https://github.com/zanderp/open-cfmoto/blob/0abbe2a70119d6dd46ac6b8a0715ff267fcdb316/app/src/main/java/dev/zanderp/opencfmoto/VideoPipeline.kt) | Encoder/Annex-B/keyframes/queue |
| S9 | [AndroidAutoService.kt](https://github.com/zanderp/open-cfmoto/blob/0abbe2a70119d6dd46ac6b8a0715ff267fcdb316/app/src/main/java/dev/zanderp/opencfmoto/AndroidAutoService.kt) | Separate Android Auto watchdog |
| S10 | [01-REVERSE-ENGINEERING.md](https://github.com/zanderp/open-cfmoto/blob/0abbe2a70119d6dd46ac6b8a0715ff267fcdb316/docs/01-REVERSE-ENGINEERING.md) | Author's historical packet observations |
| S11 | [05-DEBUG-KNOWLEDGE.md](https://github.com/zanderp/open-cfmoto/blob/0abbe2a70119d6dd46ac6b8a0715ff267fcdb316/docs/05-DEBUG-KNOWLEDGE.md) | Absence of raw captures/first-IDR failure |
| S12 | [SUPPORTED-BIKES.md](https://github.com/zanderp/open-cfmoto/blob/0abbe2a70119d6dd46ac6b8a0715ff267fcdb316/docs/SUPPORTED-BIKES.md) | Community 450NK claim |

**Source-observed** means executable behavior at this SHA, not accepted hardware bytes. **Upstream-reported** means the author's described live observation; referenced capture artifacts are absent from this snapshot (S11) and were not independently inspected. **Proposed** means a defensive constraint for later implementation. **Unverified** means unresolved on iOS/450NK. Source determines emitted bytes/defaults when old prose differs; reports do not count as this project's verification.

## Findings

Pairing (S1): classic Carbit URLs carry `ssid`, `pwd`, optional `auth`, `mac`, `name`, `action`, `modelid`, `sn`, `channel`. Keys are lowercased, values URL-decoded as UTF-8, duplicate keys use the last value, and classic parsing stops before `#`. `+` becomes space. SSID is trimmed but password spaces remain; malformed percent encoding is retained upstream. AP masks 1/2, P2P mask 8 and phone-hotspot mask 128 are upstream interpretations; `action=9` permits both AP and P2P rather than proving which one a 450NK needs. QR configuration does not supply the required TCP endpoint. Upstream reports QR `sn` is unused in setup; source CHECK_SN uses the later message's `sn`. Multi-brand QR variants exist but do not expand MVP scope.

Topology (S2/S3): **phone hosts TCP servers 10922/10921/10920** bound to its bike-interface IPv4 before sending an outbound wake probe. The dash then calls back. Separate CAR_CTRL/CAR_DATA connections can both use 10922; CAR_DATA is not the video socket at 10920. Discovery uses `_EasyConn._tcp.` NSD (12-second timeout), then gateway TCP 10930, then 10915–10935 TCP scan. The TCP application command named MDNS_RESPOND is distinct from mDNS transport. No UDP video path is present. Gateway is resolved, not permanently hardcoded. Android binding/multicast/VPN mechanisms must not be inferred to exist on iOS.

Control (S3–S7): wake `0x70000010/11`, callbacks CAR_CTRL `0x10000/01`, CAR_DATA `0x20000/01`, CLIENT_INFO `0x10010/11`, QUERY_SPEED `0x10690/91`, CHECK_SN `0x103e0/e1` followed by result `0x201c0/c1`. CLIENT_INFO is JSON with Android/package identity, phone UUID, RSA public key and transformed HUID. S7’s Kotlin singleton generates a process-memory 1024-bit RSA keypair once, potentially spanning reconnects/projection sessions; it exports Base64 X.509 public key, and applies RSA PKCS#1 v1.5 private-key encryption to UTF-8 HUID. This is not a SHA256-with-RSA signature. No key/token material was copied. The private-key decryption helper is not called in this dispatcher. Unverified: accepted iPhone identity, Apple API mapping, target firmware auth requirements, and whether Android-personality interoperability is viable. Consult [LICENSING.md](LICENSING.md) before code reuse. Plain TCP here is not encrypted screen transport.

Capabilities (S3/S6): runtime media config supplies geometry, requested encoder/FPS and extension flag. Only selected fields are consumed; requested FPS is logged, not applied. Dimensions round down to multiples of 16. A nonzero encoder ID is echoed although encoding remains H.264; later code must reject unsupported IDs. Profile selection/clock/extra notification handling differ across dash families. Source legacy default is not proof of a 450NK profile or panel size.

Video (S3/S8): 112 starts/attaches video and gets 113; each dash 114 pulls one access unit. The reply is LE four-byte byte count + Annex-B bytes with no ReqBase/timestamp/trailer added. **S10 itself calls the framing inferred and retains uncertainty about an `INT_ZERO` terminator**. Emission is observed; exact target acceptance is unverified. Encoder caches SPS/PPS and prepends them to each keyframe. Data start/restart flushes queue, drops non-keyframes until IDR and requests an immediate sync frame. Queue capacity eight, congestion drops oldest. Default Android profile: H.264 Baseline 3.1, 2.5 Mbps, 30 FPS, one-second IDR; configuration may fall back to encoder default. These are choices, not proven decoder limits. Current static-repeat setting is **900,000 microseconds**; S10's older prose says 100,000.

Liveness (S3/S5): answer PXC `0x70000000` with `0x70000001`, and proactively send every two seconds on **each selected 10922 socket**. Media 64/65 is separate. Five-second `hb#` logging sends no wire heartbeat. Roughly seven-second idle teardown described upstream concerns another family; it is not a 450NK measurement. Android Auto service's eight-second frame-stall watchdog (S9) does not prove universal mirror recovery.

Recovery/shutdown (S3): when all callbacks close after a prior connection, listeners remain and cached IP/network are re-probed for up to 20 outer attempts. Backoff begins at 1 second, increases 500 ms and caps at 4 seconds; each attempt includes inner probes and a 2.5-second callback wait. Any accepted callback resets retries. This does not resolve a changed Wi-Fi IP. Force reconnect closes callbacks. Stop clears flags, interrupts heartbeat workers, closes callbacks/listeners and stops owned video; shared Android Auto video has another owner. **No explicit standard-Car stop packet is sent.** Defined RV MIRROR_STOP `0x30030` is unused here; restoration of ordinary TFT mode requires hardware evidence.

## Fixtures and validation boundaries

See [fixture README](../../Tests/Fixtures/README.md), [manifest](../../Tests/Fixtures/protocol-manifest.json), [generator](../../Tools/generate_protocol_fixtures.py), and [tests](../../Tests/test_protocol_fixtures.py). All values were invented. No real credentials, identities, captures, private keys or screen contents are present. Video markers are deliberately non-decodable and prove only framing. Tests check frozen bytes/hashes, provenance, two length semantics, reply content, config offsets, split/coalesced reads and malformed declarations. They validate research artifacts, not a production Swift parser, live simulator session, RSA compatibility, native build or hardware.

Run `python -m unittest discover -s Tests -v` and `python Tools/verify_repository.py`. Native build requires a separate macOS/Xcode environment. Independent review/coordinator merge are required before architecture per brief section 52; no milestone is declared here.

## Required further evidence

1. Record target 450NK year/region/firmware, real sanitized QR, AP/P2P requirement, endpoint and callback addresses. S12's community Android support is insufficient for iOS verification.
2. Capture a sanitized control/media transcript with direction, ports, timing and revision. Establish identity/auth fields and mandatory ordering; separate sockets have no demonstrated global ordering guarantee.
3. Verify geometry/profile/level, SPS/PPS/IDR startup, exact raw frame/trailer boundary, static screens and fresh-decoder reconnection.
4. Measure heartbeat expiry, backpressure, partial sockets, malformed lengths and changed Wi-Fi addresses. Upstream parsers lack adequate allocation limits.
5. Verify stop restores TFT behavior and allows a clean new session; explicit stop commands remain open.
6. Resolve background capture/listener feasibility in iOS research/device probes; source audit cannot fulfill 30-minute acceptance.

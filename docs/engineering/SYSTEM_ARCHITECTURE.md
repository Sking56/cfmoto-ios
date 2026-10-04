# System architecture

MVP-007, 2026-10-04. Specification based on reviewed Gate 0 research on `main` at `cd5d9a47aada71f211b0d8f73eff180dd89f87e5`. Architecture independently approved for the synthetic Gate 1 scope at `fde4c817ce75514d973f00820e21498f35ade4b6`; see [review/evidence](verification/GATE_1_HARDENING.md). Gate 2 video additions are under review. Future capture/network adapters remain implementation plans, not established device compatibility.

## Ownership and boundaries

| Module | Responsibility | Boundary |
|---|---|---|
| App | SwiftUI state, user commands, system-picker presentation | Main actor; no protocol parsing in views |
| Pairing | Parse classic URL QR data, hold credentials in memory | Pure parser; never fetch the QR URL or log credentials |
| Network | Persistent hotspot configuration, endpoint discovery, listeners and TCP lifecycle | Apple APIs; explicit production Wi-Fi policy and separate host-test policy |
| EasyConnect | Bounded codecs, command dispatch, negotiation and session state | Foundation-only Swift core, testable on macOS without iOS capture APIs |
| Capture | System-selected full-display stream or synthetic frame source | A frame-source boundary; capture consent belongs to the active generation |
| Video | Geometry conversion, H.264 encoding, Annex-B access units and bounded admission | No socket or UI ownership |
| Diagnostics | Sanitized counters, typed failure reasons and export | No QR, credentials, HUID, tokens, screen bytes or destinations |

Use a dependency-free Swift package to compile the same Pairing/EasyConnect/Video sources in host unit tests. Pure core and Apple-framework video targets remain separate. The host-only ProtocolHarness adapter is testable through injected send completions; ProtocolProbe is its thin CLI. VideoInspector has no producer target dependency and independently parses/decodes received video. The app retains its iOS 27 deployment target and compiles the video sources without invoking them from the skeleton UI. Host tests do not replace the Xcode app build, signed-device checks or the installed ScreenCaptureKit SDK audit.

## Session topology

The phone owns listeners on TCP 10922 (two distinct PXC callbacks), 10921 (media control) and 10920 (media data). Prepare all listeners before connecting to the resolved dashboard wake endpoint, commonly TCP 10930. The dashboard then connects back to the phone. Media delivery is a response to DATA_NEXT on the media-data socket. Do not create an unsolicited phone-to-dash video stream.

An attempt owns its listeners, callbacks, decoders, write queues, deadlines and generation ID. One session coordinator serializes transitions. Each connection owns a separate decoder and serialized writer; channel classification is based on the listener and CAR_CTRL/CAR_DATA selection, rather than callback arrival order. Bind callbacks to the intended peer/session and reject duplicate channel selection. Unknown commands are observable unsupported events, never generic command-plus-one acknowledgements.

Wake success, TCP acceptance, protocol readiness and displayed video are different observations. Readiness requires the complete negotiated channel set and validated capabilities. CLIENT_INFO identity/RSA interoperability is unresolved: inject an identity provider, and fail explicitly when a hardware identity is unavailable. A synthetic provider may exist only in a host-test executable, with a simulator that explicitly accepts that profile. Never report its success as authentication to a TFT.

## Data and resource policy

The PXC header uses a total length, media uses a body length, and raw video uses a four-byte access-unit length. Read complete bounded messages across arbitrary TCP chunks. Validate a full header before buffering its declared body; malformed/oversized input terminates that decoder/connection, and EOF with pending bytes is an error. Keep unknown command bits and reserved fields intact at the framing layer; apply channel/command policy above it.

Initial defensive limits are 1 MiB total PXC bytes, 65,535 media-body bytes, and 1 MiB raw access-unit bytes. These are local safety limits, not measured firmware maxima. Transport receive chunks and queued writes must also be bounded. The future video policy is specified in [VIDEO_PIPELINE.md](VIDEO_PIPELINE.md).

The host probe's control writers admit at most 64 writes and 256 KiB, including the single in-flight write. Gate 2 media-data writers admit at most four writes/1 MiB plus the raw header; the separate encoded queue defaults to three frames/1 MiB. Multi-reply exchanges are admitted atomically and sent FIFO. Completion releases capacity; writer overflow fails the probe rather than discarding replies. Closing purges the queue and prevents reuse or late completion. These are defensive prototype limits, not firmware measurements. Pending pre-wake evidence is a bounded set. The one-shot success summary waits for queued writes to complete and for partial inbound frames to finish; send completion alone does not prove peer consumption/display. Gate 2 separately verifies decoded pixels in the receiver.

Stop invalidates the generation before resource teardown, stops frame admission, purges encoded output, cancels deadlines and writers, closes callbacks/listeners and stops owned capture/encoder work. Removing an app-owned Wi-Fi configuration is a separate explicit disconnect/forget action. Standard-Car stop has no verified wire command; TFT restoration needs hardware evidence.

## Implementation order and evidence

1. Gate 1: QR parser, framing, typed negotiation/state logic, synthetic-only identity boundary, independent Python dashboard peer, unit/adversarial tests and host socket integration.
2. Gate 2: real encoded synthetic images, decoder inspection, dash-pulled delivery and keyframe recovery.
3. Gate 3: installed iOS 27 SDK audit, signed full-display consent/background probe, then capture to simulator.
4. Gates 4-6: parked 450NK pattern, real navigation mirroring, recovery/restoration and 30-minute physical results.

Architecture and implementation changes stay on short-lived branches with exact-revision verification records. No gate tag until independent review and the required native/integration checks pass. [EASYCONNECT_PROTOCOL.md](EASYCONNECT_PROTOCOL.md), [IOS_PLATFORM.md](IOS_PLATFORM.md), [NETWORKING.md](NETWORKING.md) and [LICENSING.md](LICENSING.md) retain their source/unknown boundaries.

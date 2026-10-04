# Video pipeline

MVP-007/MVP-009, 2026-10-04. REQ-VID-001, REQ-PROJ-005. Gate 2 synthetic implementation is under independent review; capture and hardware projection remain unimplemented/unverified.

`ScreenFrameSource -> geometry/format conversion -> VideoToolbox H.264 -> Annex-B access unit -> bounded queue -> DATA_NEXT response`

Real and synthetic sources expose the same frame boundary with strong pixel-buffer ownership, increasing presentation timestamps and generation IDs. Add conversion only when delivered geometry/format requires it. The boundary permits later composition; MVP has no compositor, telemetry or audio.

Validate CONFIG_CAPTURE before acknowledging: require all consumed fields, H.264 encoder 2 (wire 0 selects default 2), nonzero dimensions after 16-pixel rounding and a bounded frame rate/geometry policy. Initial host-test policy caps dimensions at 4096 and FPS at 60; these are defensive prototype limits, not 450NK capabilities. The invented 800x386 fixture rounds to 800x384; never label it measured TFT geometry. Actual device support must come from negotiation plus encoder creation/property results.

Initial encoder candidates from the reference are Baseline 3.1, 2.5 Mbps, 30 FPS, one-second IDR and no frame reordering. Negotiate/measure suitability, check every VideoToolbox status and avoid asserting these as target firmware limits. Convert length-prefixed output to Annex-B with bounds-checked NAL lengths and obtain SPS/PPS from the format description. Every startup/recovery keyframe carries SPS/PPS before IDR.

DATA_START clears encoded output and waits for fresh IDR. DATA_NEXT consumes at most one access unit. Write `[UInt32 LE length][Annex-B bytes]` as one serialized response, without ReqBase 115, token, timestamp or invented trailer. If no unit exists, a bounded wait can expire without a frame response, matching the researched path. Repeated pulls must not create unbounded waiting tasks.

Use bounded encoder in-flight ownership and a small bounded encoded queue. When overload drops predictive output, clear the remaining chain, force IDR and discard dependent frames until recovery; simply dropping the oldest P-frame is insufficient. Stop/generation changes purge all units. Reset or recreate encoding on dimensions/orientation changes according to actual delivered metadata and negotiation.

## Synthetic Implementation

`OpenCFMoto/Video/SyntheticFrameSource.swift` owns an 800x384 BGRA test image with three color bars and a moving marker. `H264Encoder.swift` checks session creation/properties/submission/flush/output and uses Baseline 3.1, 2.5 Mbps, negotiated FPS and no reordering. This is an on-demand, single-in-flight, synchronously flushed prototype, not an asynchronous capture pipeline or a sustained 30 FPS result. Any submission, flush or output failure invalidates the encoder; it cannot resume a possibly broken predictive chain. Deterministic injected-failure tests cover this terminal policy.

`AnnexB.swift` validates 1/2/4-byte length prefixes, NAL bounds and forbidden bits, prepends SPS/PPS to IDR and caps each resulting access unit at 1 MiB. `FrameQueue.swift` defaults to three frames/1 MiB. Count/byte overflow clears the entire predictive chain and waits for a fresh keyframe. Stop/start changes purge output; stale-generation admission is ignored. These queue failure cases are deterministic unit tests, not claims of naturally occurring Network.framework congestion in this on-demand probe.

`Tools/ProtocolHarness/HostProbe.swift` lazily creates the source/encoder after negotiated readiness and DATA_START. Each DATA_NEXT encodes and pulls at most one frame, with no unsolicited raw output. Repeated DATA_START requires an empty media writer, starts a new queue generation and forces IDR. A changed active capture configuration is explicitly rejected. The media writer admits at most four writes/1 MiB plus the four-byte raw header, including in-flight output. The test exits only after twelve writes drain; it is not a production session/Stop watchdog.

The Python dashboard collects at most twelve bounded raw units in memory and invokes `Tools/VideoInspector/main.swift` in a separate process. That executable has no encoder/core dependency and independently parses framing/NALs, constructs the decoding format and decodes through VideoToolbox. Checks require dimensions, RGB samples, marker movement, Baseline 3.1 and startup/restart SPS/PPS/IDR. Both ends share Apple's codec engine, so this is independent parser/receiver evidence, not cross-codec or firmware interoperability. No screen/video files are saved by default.

The old framing-only fixture remains non-decodable and is not used as the video proof or HELLO 450NK. Raw-video trailer acceptance, production capture ownership/async backpressure, physical encoder performance, thermal behavior, protected content and 30-minute projection remain open.

# Video pipeline

MVP-007 candidate specification, 2026-10-04; independent review pending. REQ-VID-001, REQ-PROJ-005. No encoder/capture implementation is verified yet.

`ScreenFrameSource -> geometry/format conversion -> VideoToolbox H.264 -> Annex-B access unit -> bounded queue -> DATA_NEXT response`

Real and synthetic sources expose the same frame boundary with strong pixel-buffer ownership, increasing presentation timestamps and generation IDs. Add conversion only when delivered geometry/format requires it. The boundary permits later composition; MVP has no compositor, telemetry or audio.

Validate CONFIG_CAPTURE before acknowledging: require all consumed fields, H.264 encoder 2 (wire 0 selects default 2), nonzero dimensions after 16-pixel rounding and a bounded frame rate/geometry policy. Initial host-test policy caps dimensions at 4096 and FPS at 60; these are defensive prototype limits, not 450NK capabilities. The invented 800x386 fixture rounds to 800x384; never label it measured TFT geometry. Actual device support must come from negotiation plus encoder creation/property results.

Initial encoder candidates from the reference are Baseline 3.1, 2.5 Mbps, 30 FPS, one-second IDR and no frame reordering. Negotiate/measure suitability, check every VideoToolbox status and avoid asserting these as target firmware limits. Convert length-prefixed output to Annex-B with bounds-checked NAL lengths and obtain SPS/PPS from the format description. Every startup/recovery keyframe carries SPS/PPS before IDR.

DATA_START clears encoded output and waits for fresh IDR. DATA_NEXT consumes at most one access unit. Write `[UInt32 LE length][Annex-B bytes]` as one serialized response, without ReqBase 115, token, timestamp or invented trailer. If no unit exists, a bounded wait can expire without a frame response, matching the researched path. Repeated pulls must not create unbounded waiting tasks.

Use bounded encoder in-flight ownership and a small bounded encoded queue. When overload drops predictive output, clear the remaining chain, force IDR and discard dependent frames until recovery; simply dropping the oldest P-frame is insufficient. Stop/generation changes purge all units. Reset or recreate encoding on dimensions/orientation changes according to actual delivered metadata and negotiation.

Gate 2 must prove decoding of actual synthetic access units, SPS/PPS/IDR startup, no stale generations, backpressure and pull-only delivery. The existing framing-only fixture is non-decodable and cannot serve as HELLO 450NK. Raw-video trailer acceptance, physical encoder performance, thermal behavior, protected content and 30-minute projection remain open.

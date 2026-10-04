# Dash Simulator

`dash_simulator.py` is an independent Python standard-library, one-session synthetic dashboard peer. It accepts outbound wake and opens all four callbacks to the phone, checks negotiation/heartbeat replies, and supports delayed/rejected wake, invalid XOR, oversized/truncated PXC, unknown commands, missing/duplicate channels, early DATA_START/DATA_NEXT and disconnect cases. Video mode pulls and independently decodes twelve synthetic H.264 frames. It does not import the Swift codecs, research parser or fixture generator.

Run the full host check with Python 3.10+ on macOS with Swift 6:

```sh
python3 Tools/verify_gate2.py
```

The verifier runs 33 Swift tests, 14 legacy loopback cases, two video cases and four independent-decoder rejection cases, with bounded subprocess/socket deadlines and explicit failure-reason checks. Local TCP bind/connect and VideoToolbox access are required. Build/cache output stays under ignored `build/`. Control writers admit at most 64 writes/256 KiB; the media-data writer allows four writes/1 MiB plus the raw header, including in-flight bytes. Core and adapter tests hold completion pending and deliver it after teardown. `verify_gate1.py` remains available for just the legacy socket cases and package tests.

For a manual probe, run these in separate terminals after the verifier has built the executable:

```sh
python3 Tools/DashSimulator/dash_simulator.py
build/SwiftPM/debug/ProtocolProbe
```

Ports default to wake 10930, PXC 10922, media control 10921 and media data 10920. Override all four with `--ports WAKE PXC CONTROL DATA` on the Python peer and four positional ports on ProtocolProbe. `--chunk-size` controls writes; `--fault` selects a test case (`delayed-wake` is a successful out-of-order case). Binding is loopback by default; alternate Python bind/phone addresses are explicit, but the current Swift probe remains loopback-only.

To run the video pair manually after building, add `--video --inspector build/SwiftPM/debug/VideoInspector` to the Python command and `--video` to ProtocolProbe. Video mode requires the decoder and does not accept `--fault`. Frames stay in bounded memory; there is no output recording option or saved screen/video content.

Both peers label identity `synthetic-no-crypto`. CLIENT_INFO is deliberately invented and is not an RSA or firmware authentication test. Legacy mode exits after an empty DATA_NEXT; video mode exits after twelve drained frame responses, with a forced restart before frame seven. These are test termination policies, not a live phone's media timeout policy. No long-running receiver, screen capture, production iPhone networking or 450NK behavior is verified. [Gate 2 evidence and remaining coverage gaps](../../docs/engineering/verification/GATE_2_HOST.md) record exact-revision independent approval and checkpoint state.

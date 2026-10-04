# Dash Simulator

`dash_simulator.py` is an independent Python standard-library, one-session synthetic dashboard peer for the Gate 1 host probe. It accepts outbound wake and opens all four callbacks to the phone, checks negotiation/heartbeat replies, and supports delayed/rejected wake, invalid XOR, oversized/truncated PXC, unknown commands, missing/duplicate channels, early DATA_START/DATA_NEXT and disconnect cases. It does not import the Swift codecs, research parser or fixture generator.

Run the full host check with Python 3.10+ on macOS with Swift 6:

```sh
python3 Tools/verify_gate1.py
```

The verifier builds/tests the core and runs 14 isolated loopback cases, with bounded subprocess/socket deadlines and explicit failure-reason checks. Local TCP bind/connect access is required. Build/cache output stays under ignored `build/`. The Swift probe serializes replies through per-connection queues limited to 64 writes/256 KiB, including the in-flight write; deterministic unit tests exercise stalled completion and overflow.

For a manual probe, run these in separate terminals after the verifier has built the executable:

```sh
python3 Tools/DashSimulator/dash_simulator.py
build/SwiftPM/debug/ProtocolProbe
```

Ports default to wake 10930, PXC 10922, media control 10921 and media data 10920. Override all four with `--ports WAKE PXC CONTROL DATA` on the Python peer and four positional ports on ProtocolProbe. `--chunk-size` controls writes; `--fault` selects a test case (`delayed-wake` is a successful out-of-order case). Binding is loopback by default; alternate Python bind/phone addresses are explicit, but the current Swift probe remains loopback-only.

Both peers label identity `synthetic-no-crypto`. CLIENT_INFO is deliberately invented and is not an RSA or firmware authentication test. The probe exits and closes sockets after DATA_START plus an empty DATA_NEXT; this is test termination, not a live phone's media timeout policy. The simulator does not yet accept/decode/record video or provide a long-running receiver, capture, iPhone networking or 450NK verification. Gate 2 must add real encoded synthetic access units. Independent code review and native checks remain pending before a gate tag.

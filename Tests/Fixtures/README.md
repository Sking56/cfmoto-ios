# Synthetic protocol research fixtures

Only synthetic or sanitized fixtures may be committed. Each fixture set must record upstream revision or generation method, interpretation, byte order, sanitization, and limits. Research fixtures describe observed Android behavior; they do not prove iPhone or 450NK compatibility.

MVP-002, REQ-PAIR-001 / REQ-PROJ-001. Upstream source pinned at `0abbe2a70119d6dd46ac6b8a0715ff267fcdb316`. **No live capture or hardware verification is included.**

`protocol-provenance.json` records pinned primary URLs and SHA-256 digests of canonical Git blob bytes, avoiding checkout line-ending differences. `protocol-manifest.json` records each binary's SHA-256, size, role, direction, framing, evidence IDs and expected values. Every credential/identity is invented. No upstream code, private key, real token, screen content or real QR was copied.

Categories: `qr/`, `handshake/`, `heartbeat/`, `capabilities/`, `video/`, `malformed/`. They are independent message examples, not a verified ordered session transcript. CLIENT_INFO is request-only; its invented fields are not an accepted 450NK identity and there is no authenticated reply. QR cases cover classic URL input only; multi-brand/P2P support is not implied.

Control uses 16-byte LE CmdBaseHead with total length and command-XOR-length. Media uses 8-byte LE ReqBase with body length and token. Video reply uses four-byte LE byte count followed by Annex-B markers. `video/framing-only.bin` is **not decodable H.264**: SPS/PPS/IDR NAL bodies are invented ASCII. It tests framing, not codec output or TFT paint, and must not be used as a hardware test frame. Raw video framing is emitted by upstream source but still described as inferred in upstream notes; firmware acceptance/trailer behavior remains unverified.

Malformed vectors test defensive interpretation rather than packets emitted upstream. Research validator's 1 MiB PXC/video guard is not a hardware maximum. It rejects total length below 16, unlike the permissive upstream reader. No production parser/client or simulator is implemented here.

From repository root:

```text
python Tools/generate_protocol_fixtures.py --check
python -m unittest discover -s Tests -v
python Tools/verify_repository.py
```

To regenerate intentionally: `python Tools/generate_protocol_fixtures.py`. Optional source provenance verification with an ignored pinned clone: `python Tools/generate_protocol_fixtures.py --check --verify-upstream .research/open-cfmoto`. Offline output checks need no clone or external packages. Tests validate artifact consistency, known bytes, distinct framing lengths, bodies, provenance and fragmented/coalesced reads; they do not prove native iOS compilation, RSA interoperability or bike behavior.

See [research](../../docs/engineering/OPENCFMOTO_RESEARCH.md) and [candidate specification](../../docs/engineering/EASYCONNECT_PROTOCOL.md). Keep future real sanitized captures separate with device/firmware, capture method, timestamps, direction/ports, revision and redaction provenance.

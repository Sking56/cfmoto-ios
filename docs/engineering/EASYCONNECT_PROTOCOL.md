# EasyConnect candidate protocol specification

MVP-002 / REQ-PAIR-001 / REQ-PROJ-001. Source-derived standard Car PXC research; target-450NK verification pending. Revision `0abbe2a70119d6dd46ac6b8a0715ff267fcdb316`, audited 2026-10-04. Evidence IDs refer to pinned primary links in [OPENCFMOTO_RESEARCH.md](OPENCFMOTO_RESEARCH.md). Wire statements are source-observed unless marked reported/proposed/unverified. This is not a manufacturer specification.

## Pairing and transport

Invented classic input:

```text
https://pairing.example.invalid/?modelid=SYNTHETIC&sn=SYNTHETIC-NONCE&action=9&ssid=CFMOTO-TEST-000001&pwd=fixture-only-0001&auth=wpa2-psk&mac=02:00:00:00:00:01&name=Synthetic%20Bike
```

S1 accepts normalized keys/URL-decoded values; duplicate keys take the last value, SSID is trimmed, password spaces retained, `+` decoded to space. URL is input data, not a page to visit. QR `sn` does not define CHECK_SN result. Endpoint discovery is separate. AP 1/2, P2P 8 and phone-hotspot 128 are upstream mask interpretations; actual 450NK mode is unverified. Multi-brand variants are outside MVP scope.

| Connection | Initiator → listener | Framing |
|---|---|---|
| Wake | Phone → discovered dash IPv4/port, commonly TCP 10930 | CmdBaseHead |
| PXC | Dash → phone TCP 10922; separate CAR_CTRL/CAR_DATA sockets | CmdBaseHead |
| Media control | Dash → phone TCP 10921 | ReqBase |
| Media data | Dash → phone TCP 10920 | ReqBase requests; raw frame replies |

S3 lines 191–227 bind all three listeners to the bike interface **before** probe. S2/S3 discover NSD `_EasyConn._tcp.` → gateway 10930 → nearby TCP scan. Application MDNS_RESPOND is TCP; mDNS discovery is separate. No UDP screen transport is implemented. IPv4 only in this path; IPv6 unverified. Gateway must not be assumed permanently `192.168.0.1`. Proposed: constrain callback peers to the intended network/session; source accepts any reachable peer.

TCP segment boundaries are not message boundaries. Accumulate complete header/body, preserve following frames and serialize writes per connection so heartbeat/reply bytes cannot interleave. Cancel by closing listeners and callbacks. These are framing/concurrency constraints, not measured hardware timing.

## CmdBaseHead: 16-byte control header

S4 `PxcFrame.write/read`:

| Offset | Size | LE field |
|---|---|---|
| 0 | 4 | UInt32 command bit pattern |
| 4 | 4 | UInt32 **total length = 16 + payload bytes** |
| 8 | 4 | UInt32 command XOR total length |
| 12 | 4 | Reserved, zero on write; reader does not enforce zero |
| 16 | total − 16 | Payload, often UTF-8 JSON |

No sync prefix/trailer. XOR is only a header check, not payload integrity/authentication. Empty CAR_CTRL header: `00 00 01 00 10 00 00 00 10 00 01 00 00 00 00 00`. JSON key order is not a demonstrated interoperation rule; synthetic fixture ordering is frozen only for regression tests.

Proposed parser rules: reject total < 16, XOR mismatch, oversized declarations before allocating, and EOF in header/body. Research validator uses a 1 MiB guard, not a measured firmware maximum. Upstream clamps negative body length to zero and allocates unbounded input: do not copy its safety behavior. Reserved values/unknown commands require explicit compatibility policy.

## Wake and control messages

| Request | Response | Payload / role |
|---|---|---|
| Phone `0x70000010` | Dash `0x70000011` | Wake JSON `{"phoneType":"Android","packageName":"com.cfmoto.cfmotointernational"}`; expected ack `{"status":true}` |
| Dash `0x10000` CAR_CTRL | Phone `0x10001` | Empty, one 10922 socket |
| Dash `0x20000` CAR_DATA | Phone `0x20001` | Empty, another 10922 socket |
| Dash `0x10010` CLIENT_INFO | Phone `0x10011` | Capability/identity JSON |
| Dash `0x10690` QUERY_SPEED | Phone `0x10691` | Source response empty |
| Dash `0x103e0` CHECK_SN | Phone `0x103e1`, then `0x201c0` | Empty ack, then separate JSON result |
| Phone `0x201c0` | Dash `0x201c1` | Source ignores result ack |
| Either `0x70000000` | Peer `0x70000001` | Empty PXC heartbeat |

S3 lines 514–523 accepts ack text containing `true`, not parsed Boolean. Proposed: require parsed `status: true`; an arbitrary substring may accept negative JSON containing `true` elsewhere. Accepted wake is not projection readiness.

S5 reports legacy sequence CAR_CTRL → CLIENT_INFO → QUERY_SPEED → CAR_DATA → CHECK_SN → media, but dispatches by command. No guaranteed global ordering across TCP sockets/all firmware is established; heartbeat can interleave. Readiness requires completed required exchanges rather than one callback.

S6 lines 288–309 emits CLIENT_INFO reply fields:

```text
pxcVersion="1.0.2", phoneUUID=<generated UUID>, phoneBrand/phoneModel=<Android device>,
phoneOsVersion=<Android API string>, phoneOs="Android", package="com.cfmoto.cfmotointernational",
versionCode=126, token=0, pubkey=<Base64 X.509 RSA public key>,
encryptedHUID=<Base64 private-key PKCS#1 operation on UTF-8 HUID>,
bluetoothName="OpenCfMoto", supportH264IFrame=true, supportFunction=<profile>,
supportSyncCorrectTime=false, appVersionFingerPrint="opencfmoto-poc"
```

Legacy `supportFunction=0`; other profiles differ. Do not advertise unsupported audio/touch/clock features. S7’s Kotlin singleton generates 1024-bit RSA once in process memory, potentially spanning reconnects/projection sessions, and uses RSA/ECB/PKCS1Padding private-key encryption, not digest signing. iOS personality, Apple cryptographic mapping and target firmware acceptance are unverified. Synthetic CLIENT_INFO fixture is request-only with invented identity; no valid reply/key/signature is supplied.

CHECK_SN result is `{"isOk":true,"errCode":0,"errMsg":"","id":<request sn>,"client_set":"easy_conn"}`. Upstream always approves; QR nonce is not validated here. Extra notifications exist (LOG_REPORT, OTA, media features, SOCK_SERVER_INFO, clock). Some other profiles ack selected commands; do not apply generic command-plus-one replies without target evidence. BLE, RV/MCULite/protobuf, OTA/audio are outside this candidate path.

## ReqBase: 8-byte media header

S3 lines 694–731:

| Offset | Size | LE field |
|---|---|---|
| 0 | 2 | Int16 media command |
| 2 | 2 | UInt16 **body length only**, excludes header |
| 4 | 4 | Int32 token; requests decoded, replies written as zero |
| 8 | body length | Body |

No XOR. Raw frame replies use neither header. Nonzero-token echo semantics are unverified; source always replies token 0. Proposed parsers bound per-command body sizes and validate required fields before access.

| Decimal request | Reply | Source behavior |
|---|---|---|
| 16 CONFIG_CAPTURE | 17 | Nine-byte capture reply |
| 48 GET_VERSION | 49 | Two LE Int32 values: 3, 1 |
| 64 HEARTBEAT | 65 | Empty |
| 96 CONFIGCAPTUREREXTEND | 97 | UTF-8 JSON `{"state":0}` |
| 128 START_H264 | 129 | Empty; handler itself does not start encoder |
| 112 DATA_START | 113 | Create/attach source, reset keyframes, empty |
| 114 DATA_NEXT | Raw frame | Poll up to 1500 ms; source sends nothing if no frame |
| 32 TOUCH | None | Android input path; arbitrary iOS injection excluded |

Empty media heartbeat header: `40 00 00 00 00 00 00 00`. DATA_NEXT does **not** receive ReqBase 115. Timeout-with-no-reply is source behavior, not a complete liveness policy.

## Capture negotiation

S3 lines 735–765 consumes UInt16 width at body 0, UInt16 height at 2, Int32 FPS at 4 (logged only), Int32 encoder at 8 (0 defaults to 2), extension byte at 29. Missing fields default upstream rather than causing rejection.

Upstream-reported S10 also labels supportCodec Int32 at 12, quality Int16 at 16/18, bitrate Int32 at 20, mode/touch/orientation/display/video bytes 24–28, reserved 30–31 and encryptedHUID UTF-8 from 32. Source does not consume those fields here; semantics/authentication effect are unverified.

Reply body: Int32 encoder at 0, UInt16 rounded width at 4, UInt16 rounded height at 6, extension byte at 8. Default rounding is `dimension & 0xFFF0`: invented request 800×386 → 800×384; this is not a measured 450NK canvas. Source may reply zero geometry/non-H.264 encoder although the pipeline is H.264. Proposed: reject unsafe geometry/unsupported encoder before acknowledging. Version/extension replies are not complete capability negotiation.

## Video reply and keyframe contract

S3 `sendFrameRaw` responds on media data connection:

```text
[4-byte LE access-unit byte count][exactly that many H.264 Annex-B bytes]
```

No ReqBase command/token, timestamp/sequence, fragmentation header/padding, or trailing zero is added. TCP may split anywhere. **S10 calls this wire format inferred and retains uncertainty about an INT_ZERO terminator.** Source emission is exact; target-firmware acceptance remains unverified.

S8 treats MediaCodec output as Annex-B. SPS/PPS is cached and prepended to every keyframe. DATA_START flushes queue, discards non-keyframes until IDR, and requests immediate sync. Synthetic `video/framing-only.bin` is deliberately **not decodable H.264**: invented NAL bodies test only framing. Do not use it as the hardware HELLO 450NK pattern; actual encoded synthetic frames/decoder inspection belong to Gate 2.

Default Android tuning: H.264 Baseline 3.1 (fallback encoder default), 2.5 Mbps, 30 FPS, one-second IDR, intended no B-frame reordering, 900,000 μs static repeat hint, queue eight/drop oldest. Prediction continuity after dropped access units is unproven; later code must restore a keyframe when dropped references invalidate the chain. Supported firmware limits on frame size/bitrate/duration are unverified.

## Heartbeat, stop and reconnect

PXC `0x70000000/01` and media 64/65 are separate. S3 sends PXC requests every two seconds per selected CAR_CTRL/CAR_DATA socket; handling only one socket does not reproduce source behavior. Five-second diagnostic ticker is not a wire heartbeat. Upstream roughly seven-second PXC/nine-second media idle observations concern other units and are not 450NK constants.

S3 lines 294–321 stop: clear flags, interrupt heartbeat workers, close callbacks/listeners, stop owned video. No explicit standard-Car stop packet is sent. S4 defines unused RV `0x30030`; TFT restoration on stop remains unverified.

S3 lines 616–661 reconnect after all callbacks close and a prior link existed: retain listeners/cached IPv4/network; 20 outer attempts; backoff `min(500 + 500 * attempt, 4000)` ms; wake two inner attempts, NSD fallback, optional out-of-scope Yunmo fallback, 2500 ms callback wait. Any accepted callback resets attempts. Force reconnect closes callbacks. This does not prove complete multi-socket negotiation or recovery after address change. S9's eight-second stall watchdog is Android Auto service logic. Proposed iOS behavior: cancel stale generations, re-resolve changed Wi-Fi addresses, resume with fresh SPS/PPS/IDR.

## Validation and open evidence

[Manifest](../../Tests/Fixtures/protocol-manifest.json) freezes synthetic bytes/expectations/hashes. [Tests](../../Tests/test_protocol_fixtures.py) check lengths/XOR, config offsets, replies, split/coalesced streams, malformed declarations and provenance. Its strict research checker rejects total length <16 that upstream clamps. This is neither production protocol core nor Dash Simulator.

Unverified: actual 450NK order/identity/authentication, nonzero token semantics, extra capability/clock fields, IPv6, H.264 limits/trailer, stop restoration, heartbeat deadlines, background capture/listeners and 30-minute endurance. Future integration needs sanitized captured traffic and hardware evidence alongside synthetic examples. [Hardware records](HARDWARE_INTEGRATION.md) remain pending.

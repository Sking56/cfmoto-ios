# Session state machine

MVP-007 specification, 2026-10-04; independently approved for the synthetic Gate 1 scope at fde4c81. REQ-PROJ-001, REQ-REC-001. A single coordinator owns transitions; UI displays snapshots and sends commands. Capture/recovery states below are future integration work, not verified runtime behavior; see [review/evidence](verification/GATE_1_HARDENING.md).

## Connection lifecycle

| State | Entry evidence | Allowed next states |
|---|---|---|
| idle | No attempt resources | joining, connecting (explicit host-test/manual network mode) |
| joining | Parsed configuration and user Connect | connecting, failed, idle |
| connecting | Prepare listeners, resolve endpoint and send wake | negotiating, failed, idle |
| negotiating | Parsed positive wake acknowledgement | ready only when required evidence is complete; failed, idle |
| ready | Both selected PXC callbacks, identity exchange, CHECK_SN exchange, media control/data and validated capture negotiation | capturing, reconnecting, failed, idle |
| capturing | User-initiated full-display selection or synthetic source start | projecting, ready (cancel), failed, idle |
| projecting | First access unit delivered in response to a pull | reconnecting, ready (capture stop), failed, idle |
| reconnecting | Previously ready connection lost; increment generation, discard old evidence/frames | connecting, failed, idle |
| failed(reason) | Typed bounded failure | joining/connecting by explicit retry, idle |

Evidence is a set per generation, not a presumed global TCP ordering. Heartbeats may interleave. A lone callback, successful wake or START_H264 acknowledgement does not establish readiness. Identity acceptance is not cryptographic verification unless the provider/peer actually performs that verification.

## Events, errors and stale work

Every async result carries its attempt generation. Ignore old wake completions, timeouts, callback selections, encoder results and capture outputs after Stop or retry. Reject impossible current-generation events with a typed transition error; do not trap or silently fabricate state. Stop is idempotent from every state and clears readiness evidence. Duplicate handshake evidence may be idempotent within the same attempt, but duplicate live sockets must be rejected by transport.

Failures distinguish `wifiJoinFailed`, `localNetworkDenied`, `listenerFailed`, `dashUnreachable`, `wakeRejected`, `identityUnavailable`, `handshakeRejected`, `unsupportedCapture`, `protocolViolation`, `capturePermissionDenied`, `encoderFailed` and `connectionLost`. Store a sanitized reason, not the raw payload or credential. Hardware transport will supply bounded connect/handshake/heartbeat deadlines through injected policy and a monotonic clock; research timing is not a firmware guarantee.

Reconnect re-resolves the Wi-Fi endpoint/address, prepares a fresh complete handshake and requests SPS/PPS/IDR before admitting new media. Retry count/backoff are configurable and bounded; Stop cancels immediately. System/user capture revocation disables automatic capture restart. Network recovery may reuse only consent that is still active; relaunch always requires user initiation. Physical tests must resolve the exact behavior.

Gate 1 implements and tests connection negotiation and stale-generation rules first. Capture/projecting transitions, clocks, automatic retry and full stop ownership are subsequent integration work; a pure-state test does not verify resource teardown.

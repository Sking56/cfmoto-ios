# EasyConnect

Gate 1 candidate core: `WireCodec.swift` contains bounded PXC/media/raw-video encoding and incremental decoding, `Negotiation.swift` contains typed replies and capture validation, and `SessionState.swift` tracks complete handshake evidence and generations. These Foundation-only files compile as `OpenCFMotoCore` and are included in the generated iOS app project.

Host tests cover the reviewed synthetic fixtures and adversarial input. Hardware identity/RSA, production Network.framework transport, automatic reconnect, video delivery and native iOS verification remain pending. `Tools/ProtocolProbe` is a separate synthetic-only host test adapter, not application transport. See [protocol research](../../docs/engineering/EASYCONNECT_PROTOCOL.md).

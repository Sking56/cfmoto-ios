# EasyConnect

Gate 1 candidate core: `WireCodec.swift` contains bounded PXC/media/raw-video encoding and incremental decoding, `Negotiation.swift` contains typed replies and capture validation, `SessionState.swift` tracks complete handshake evidence and generations, and `WriteQueue.swift` provides bounded FIFO admission including the in-flight write. These Foundation-only files compile as `OpenCFMotoCore` and are included in the generated iOS app project.

Host tests cover the reviewed synthetic fixtures and adversarial input. Native simulator build/analyze/skeleton launch pass; see [hardening evidence](../../docs/engineering/verification/GATE_1_HARDENING.md). Hardware identity/RSA, production Network.framework transport, automatic reconnect and video delivery remain pending. `Tools/ProtocolProbe` is a separate synthetic-only host test adapter, not application transport. See [protocol research](../../docs/engineering/EASYCONNECT_PROTOCOL.md).

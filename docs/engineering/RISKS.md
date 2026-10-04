# Risk register

Research disposition, 2026-10-04. Documented risks do not imply verified implementation.

| Risk | Evidence | Required mitigation / verification |
|---|---|---|
| iOS capture assumptions | Apple DocC documents iOS27 picker/stream and screen-capture; several macOS members lack iOS declarations | Installed SDK audit, compile and video-only physical background probe |
| 450NK pairing | Action bits allow AP/P2P; actual mode/firmware unknown | Sanitized real configuration; ordinary AP/group-owner association proof |
| Transport role | Three phone listeners and dash-pulled media in pinned source | Implement callback role, bound peers/channels, verify full negotiation |
| Identity/crypto | Android personality and process-memory RSA private-key PKCS#1 operation | Resolve iPhone identity, Security mapping and target acceptance |
| Video framing/recovery | Source raw length/Annex-B; upstream trailer uncertainty | Real encoded frame decoding, sanitized transcript, SPS/PPS/IDR startup and reference recovery |
| Wi-Fi/cellular | joinOnce background removal; scoped socket routes do not control Waze/Maps | Persistent join and actual background sockets/heartbeats; fresh online navigation; changed-IP recovery |
| Encoder/thermal/buffering | Android tuning is not an iPhone/450NK limit | Bounded ownership/queues, measured statuses/memory/thermal state and >=30-minute run |
| Stop/restoration | Standard-Car reference closes sockets; stop command unknown | TFT restoration and clean subsequent session |
| Licensing/provenance | AGPL repo notice, some missing per-file headers and lineage questions | Per-change provenance, owner license choice/obligations before distribution |
| Verification host | Windows session; user reports Mac/iPhone/450NK ready | Run native and later physical gates on exact revisions; hosted CI not run |

See [protocol](OPENCFMOTO_RESEARCH.md), [capture](IOS_PLATFORM.md), [networking](NETWORKING.md), [licensing](LICENSING.md) and [Mac handoff](MAC_HANDOFF.md).

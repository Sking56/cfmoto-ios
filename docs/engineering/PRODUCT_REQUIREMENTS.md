# Product requirements

Source: CFMoto_IOS_MVP_V1.md; iOS 27+, Swift/SwiftUI, physical iPhone, CFMoto 450NK only. These are requirements, not capability claims.

| ID | Requirement | Implementation / test / verification |
|---|---|---|
| REQ-PAIR-001 | Parse or receive sanitized MotoPlay pairing configuration | Classic parser: OpenCFMoto/Pairing/PairingConfiguration.swift; PairingTests pass on host; camera/app integration pending |
| REQ-NET-001 | Join the bike Wi-Fi with user consent | Pending physical iPhone |
| REQ-NET-002 | Establish bounded, Wi-Fi-scoped local transport | Pending |
| REQ-NET-003 | Preserve available cellular navigation connectivity | Pending field test |
| REQ-PROJ-001 | Negotiate the EasyConnect projection session | Core codecs/Negotiator/SessionStateMachine and synthetic host handshake implemented; native/identity/hardware verification pending |
| REQ-PROJ-005 | Transmit captured display frames to an established session | Pending hardware |
| REQ-CAP-001 | Obtain explicit full-display capture consent | Pending |
| REQ-CAP-002 | Continue capture when navigation app becomes foreground | Pending physical iPhone |
| REQ-VID-001 | Encode negotiated video without unnecessary compositing | Pending |
| REQ-REC-001 | Handle interruptions and bounded reconnect without crash | Pending |
| REQ-LOG-001 | Report FPS, bitrate, drops, queue, reconnects, duration and thermal state | Pending |
| REQ-LOG-002 | Exclude secrets, screen content, destinations and tokens from diagnostics | Pending |
| REQ-TEST-001 | Test protocol behavior independently using Dash Simulator | Tools/DashSimulator/dash_simulator.py and Tools/verify_gate1.py; seven host socket cases pass; video/device integration pending |
| REQ-TEST-002 | Verify fresh-checkout build and automated tests | Portable and Swift host checks available; native Xcode pending; exact revision evidence in verification records |
| REQ-TEST-003 | Sustain full projection for at least 30 minutes | Pending hardware |
| REQ-DOC-001 | Maintain research, requirements, architecture, decisions and evidence | Foundation documentation |
| REQ-DOC-002 | Advertise only verified product behavior | Research-stage product documents |
| REQ-GIT-001 | Preserve meaningful commits, review/merge records and gate tags | Foundation history |

Non-goals: CAN/OBD, telemetry/HUD, Apple CarPlay, input injection, handlebar controls, audio routing, extra motorcycle models, production App Store release, and legacy iOS support.

Later implementation must replace each Pending cell with implementation path, named test, verification record, and introducing/merge SHA. Hardware criteria may not be substituted with simulator success.

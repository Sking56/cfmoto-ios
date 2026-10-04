# OpenCFMoto iOS Mirroring MVP

## 1. Objective

Build a proof-of-concept native iOS application that can mirror the iPhone display onto a CFMoto 450NK TFT using the motorcycle's existing MotoPlay / Carbit / EasyConnect Wi-Fi projection interface.

The Android `zanderp/open-cfmoto` project is the primary behavioral and protocol reference.

The project must produce three equally important outputs:

1. **Working application code**
2. **Engineering and product documentation**
3. **A clean, traceable Git development history**

The project should be developed so that another Codex session, developer, or verification agent can determine:

- what was attempted;
- why architectural decisions were made;
- which requirements are implemented;
- which tests prove those requirements;
- which commits introduced each capability;
- what remains unresolved.

---

# 2. MVP Success Criteria

The MVP is successful when:

1. An iPhone can read or receive the CFMoto MotoPlay/EasyConnect pairing configuration.
2. The iPhone joins the motorcycle's Wi-Fi network.
3. The application establishes the required EasyConnect/Carbit projection session.
4. The user grants full-display screen-capture permission.
5. The user can switch to Waze, Apple Maps, Google Maps, or another application.
6. The selected iPhone display is projected onto the 450NK TFT.
7. Projection can operate continuously for at least 30 minutes during testing.
8. Connection interruptions are handled without crashing.
9. The application exposes useful diagnostic information.
10. Core behavior is covered by automated tests.
11. The projection stack can be tested without motorcycle hardware through a Dash Simulator.
12. Engineering documentation accurately describes the implementation.
13. Product documentation accurately describes supported user-visible behavior.
14. The Git history provides traceability from research → specification → implementation → testing → verification.

---

# 3. Explicit MVP Non-Goals

Do not implement:

- CAN/OBD integration
- RPM
- gear position
- motorcycle speed telemetry
- fuel level
- custom telemetry HUD
- Apple CarPlay
- arbitrary touch injection into iOS applications
- handlebar controls
- audio routing
- multiple motorcycle models
- production App Store release
- legacy iOS compatibility unless necessary to prove feasibility

Future architecture should permit these features, but they are outside the MVP.

---

# 4. Target Platform

Initial target:

```text
Platform: Native iOS
Language: Swift
UI: SwiftUI
Minimum iOS: iOS 27+
Primary device: Physical iPhone
Motorcycle: CFMoto 450NK
Display protocol: MotoPlay / Carbit / EasyConnect
Reference implementation: zanderp/open-cfmoto
```

Use Apple frameworks wherever possible.

Expected core frameworks include:

```text
ScreenCaptureKit
Network.framework
NetworkExtension
VideoToolbox
CoreMedia
CoreVideo
OSLog
Swift Concurrency
```

Do not introduce third-party dependencies unless their value is clearly documented and reviewed.

---

# 5. Core Architecture

Target data path:

```text
Foreground iOS Application
(Waze / Apple Maps / Google Maps)
            │
            ▼
     ScreenCaptureKit
            │
            ▼
      Capture Pipeline
            │
            ▼
      Video Pipeline
            │
            ▼
    EasyConnect Client
            │
            ▼
      Network.framework
            │
        Bike Wi-Fi
            │
            ▼
       CFMoto 450NK
```

The MVP should initially avoid unnecessary image compositing.

Future architecture should permit:

```text
Screen Capture
      │
      ▼
Navigation Frame
      │
      ├──────────────┐
      ▼              ▼
Navigation       Telemetry HUD
      │              │
      └──────┬───────┘
             ▼
         Compositor
             ▼
        EasyConnect
```

but the compositor is not required for MVP.

---

# 6. Repository Structure

Use the following general structure:

```text
OpenCFMoto-iOS/
│
├── OpenCFMoto/
│   ├── App/
│   ├── Pairing/
│   ├── Network/
│   ├── EasyConnect/
│   ├── Capture/
│   ├── Video/
│   └── Diagnostics/
│
├── OpenCFMotoTests/
├── OpenCFMotoUITests/
│
├── Tools/
│   └── DashSimulator/
│
├── Tests/
│   └── Fixtures/
│
├── docs/
│   ├── engineering/
│   └── product/
│
├── .github/
│   ├── workflows/
│   ├── pull_request_template.md
│   └── ISSUE_TEMPLATE/
│
├── .gitignore
├── README.md
├── CONTRIBUTING.md
└── LICENSE
```

---

# 7. Two Documentation Layers

The project must maintain two independent documentation surfaces.

## 7.1 Engineering Documentation

Location:

```text
docs/engineering/
```

Audience:

- Codex
- subagents
- engineers
- reviewers
- maintainers

Recommended structure:

```text
docs/engineering/
├── README.md
├── PRODUCT_REQUIREMENTS.md
├── SYSTEM_ARCHITECTURE.md
├── OPENCFMOTO_RESEARCH.md
├── EASYCONNECT_PROTOCOL.md
├── IOS_PLATFORM.md
├── NETWORKING.md
├── VIDEO_PIPELINE.md
├── STATE_MACHINE.md
├── TEST_ARCHITECTURE.md
├── DASH_SIMULATOR.md
├── HARDWARE_INTEGRATION.md
├── SECURITY_PRIVACY.md
├── LICENSING.md
├── RISKS.md
├── DECISIONS.md
├── MVP_TASKS.md
├── STATUS.md
└── AGENT_WORKFLOW.md
```

Engineering documentation defines:

> How the application works and how it must be built.

---

## 7.2 Product Documentation

Location:

```text
docs/product/
```

Audience:

- users
- motorcycle owners
- beta testers
- contributors
- stakeholders

Recommended structure:

```text
docs/product/
├── README.md
├── PRODUCT_OVERVIEW.md
├── FEATURES.md
├── REQUIREMENTS.md
├── COMPATIBILITY.md
├── INSTALLATION.md
├── SETUP_GUIDE.md
├── USER_GUIDE.md
├── TESTING_GUIDE.md
├── TROUBLESHOOTING.md
├── FAQ.md
├── PRIVACY.md
├── LIMITATIONS.md
└── ROADMAP.md
```

Product documentation defines:

> What the application does and how somebody uses or tests it.

---

# 8. Documentation Promotion Rule

An engineering capability must not appear as a supported product feature until it has passed verification.

Flow:

```text
Engineering hypothesis
        ↓
Technical specification
        ↓
Implementation
        ↓
Automated tests
        ↓
Independent review
        ↓
Integration verification
        ↓
Hardware verification if required
        ↓
Product documentation updated
```

For example:

Before hardware verification:

```text
ROADMAP.md

Experimental:
Waze screen projection
```

After verification:

```text
FEATURES.md

Supported:
Waze screen projection on tested 450NK configuration
```

---

# 9. Requirement Traceability

Engineering requirements must use stable identifiers.

Examples:

```text
REQ-PAIR-001
REQ-NET-003
REQ-PROJ-005
REQ-CAP-002
REQ-VID-007
REQ-REC-004
REQ-LOG-002
REQ-TEST-009
```

Example:

```text
REQ-PROJ-005

The application shall transmit captured iPhone display
frames to an established EasyConnect projection session.
```

Each requirement should eventually link to:

```text
Requirement
   ↓
Implementation
   ↓
Automated test
   ↓
Verification result
   ↓
Relevant Git commit(s)
```

---

# 10. Git Is Part of the MVP Architecture

Git history must be treated as project documentation.

Do not use Git merely as a backup mechanism.

The repository history should explain the evolution of the application.

The development workflow must preserve:

```text
research
↓
technical specification
↓
implementation
↓
tests
↓
review fixes
↓
integration
↓
hardware verification
```

through small, meaningful commits.

---

# 11. Git Initialization

At project creation:

```bash
git init
```

Create the initial structure before implementation.

The initial commit should contain:

```text
.gitignore
README.md
docs structure
basic Xcode project
CONTRIBUTING.md
initial MVP document
LICENSE decision or placeholder
```

Recommended commit:

```text
chore: initialize OpenCFMoto iOS project
```

Do not begin substantial implementation in an untracked workspace.

---

# 12. Branch Strategy

Use short-lived branches.

Recommended categories:

```text
research/
docs/
feat/
fix/
test/
refactor/
chore/
```

Examples:

```text
research/easyconnect-protocol
research/ios-screen-capture
research/450nk-network

docs/mvp-requirements

feat/easyconnect-core
feat/wifi-pairing
feat/screen-capture
feat/video-pipeline
feat/projection-session

test/dash-simulator
test/network-fault-injection

fix/heartbeat-timeout
```

Avoid long-running monolithic branches.

---

# 13. Agent Worktrees

When multiple Codex agents operate simultaneously, use independent Git worktrees where supported.

Example:

```text
main
 │
 ├── worktree-protocol
 │      branch: feat/easyconnect-core
 │
 ├── worktree-capture
 │      branch: feat/screen-capture
 │
 ├── worktree-simulator
 │      branch: test/dash-simulator
 │
 └── worktree-docs
        branch: docs/product-setup
```

Agents should not concurrently edit the same branch.

The coordinator owns merges and conflict resolution.

---

# 14. Commit Requirements

Commits should be:

- small;
- logically complete;
- buildable whenever practical;
- test-backed where applicable;
- descriptive.

Use Conventional Commit-style prefixes.

Examples:

```text
docs: document EasyConnect discovery flow

test: add client hello protocol fixture

feat: implement EasyConnect packet decoder

feat: add ScreenCaptureKit frame source

test: add socket disconnect fault injection

fix: reset heartbeat timer after reconnect

refactor: isolate projection state machine

docs: mark Waze projection hardware validated
```

Avoid:

```text
updates
stuff
changes
fix things
final
working version
codex edits
```

---

# 15. Commit Scope Rule

An implementation commit should ideally contain one coherent change.

Good:

```text
feat: implement EasyConnect packet header parser
```

Includes:

```text
PacketHeader.swift
PacketHeaderTests.swift
fixture update
relevant engineering documentation
```

Bad:

```text
feat: implement entire projection app
```

containing dozens of unrelated architectural changes.

---

# 16. Tests Must Travel With Code

Whenever a behavior is implemented, its automated tests should preferably be part of the same commit.

Example:

```text
feat: implement heartbeat decoder

EasyConnect/
    HeartbeatMessage.swift

Tests/
    HeartbeatMessageTests.swift
```

Do not leave testing until the end of development.

---

# 17. Documentation Must Travel With Code

If a change modifies documented behavior, update the relevant engineering document within the same branch.

Example:

```text
feat: implement negotiated display resolution
```

should update:

```text
EASYCONNECT_PROTOCOL.md
VIDEO_PIPELINE.md
```

in the same logical change set.

Product docs are updated only after verification establishes that the behavior is user-supported.

---

# 18. Research Commits

Research itself should be versioned.

Example:

```text
research: trace OpenCFMoto mirror-phone session handshake
```

May update:

```text
OPENCFMOTO_RESEARCH.md
EASYCONNECT_PROTOCOL.md
RISKS.md
```

This gives future agents a chronological record of protocol understanding.

If later research disproves something, commit the correction rather than rewriting history.

Example:

```text
research: correct EasyConnect heartbeat interpretation
```

The Git history should show how the understanding evolved.

---

# 19. Architecture Decision Records

Architectural decisions should receive explicit commits.

Example:

```text
docs: add ADR for iOS 27 minimum deployment target
```

`DECISIONS.md` or individual ADR files should explain:

```text
Context
Decision
Alternatives
Consequences
Status
```

Do not rely on commit messages alone for complex architectural reasoning.

---

# 20. Never Rewrite Shared History

Once a branch has been merged into the shared project:

- do not force-push rewritten history;
- do not squash away significant research/debug history unnecessarily;
- do not delete commits merely because an approach later changed.

Failed approaches can provide useful evidence during reverse engineering.

Experimental noise should be kept on temporary branches, while meaningful findings should be committed cleanly.

---

# 21. Pull Request / Merge Gate

Every implementation branch should conceptually pass:

```text
Implementation
    ↓
local build
    ↓
tests
    ↓
independent reviewer
    ↓
review fixes
    ↓
clean verification
    ↓
merge
```

A PR or equivalent merge record should include:

```text
Summary
Requirements implemented
Tests added
Documentation modified
Known limitations
Verification results
Related task IDs
```

Example:

```text
Implements:
REQ-NET-003
REQ-NET-004

Tests:
BikeTransportTests
ReconnectTests

Docs:
NETWORKING.md
STATE_MACHINE.md
```

---

# 22. Git Tagging

Tag meaningful project milestones.

Examples:

```text
research-v0.1
mvp-gate-1
mvp-gate-2
mvp-gate-3
mvp-hardware-projection
v0.1.0-alpha
```

Recommended sequence:

```text
mvp-gate-0
Research complete

mvp-gate-1
Protocol implementation complete

mvp-gate-2
Synthetic projection complete

mvp-gate-3
iPhone capture → DashSimulator

mvp-gate-4
Synthetic frame → 450NK

mvp-gate-5
Real iPhone mirroring → 450NK

v0.1.0-alpha
MVP candidate
```

Tags provide fixed historical checkpoints for debugging regressions.

---

# 23. Changelog

Maintain:

```text
CHANGELOG.md
```

This is primarily release/product oriented.

Example:

```text
## 0.1.0-alpha

### Added

- CFMoto 450NK pairing
- iPhone screen projection
- Waze mirroring
- Apple Maps mirroring
- projection diagnostics
- automatic reconnect

### Known limitations

- no handlebar input
- no motorcycle telemetry
- no audio forwarding
```

Do not use the changelog as a replacement for Git commit history.

---

# 24. Git Bisect Compatibility

Development should strive to keep intermediate commits buildable.

This enables:

```bash
git bisect
```

to identify regressions.

Especially important for:

```text
protocol changes
network lifecycle
video pipeline
ScreenCaptureKit integration
reconnect behavior
```

Avoid giant commits that make historical regression analysis impossible.

---

# 25. Generated Files

Do not commit:

```text
DerivedData/
build/
*.xcuserstate
local credentials
Wi-Fi passwords
screen recordings
diagnostic captures containing sensitive content
```

Maintain a proper `.gitignore`.

Protocol fixtures must contain sanitized data.

---

# 26. Coordinator Agent

The root Codex agent acts as:

**Technical Lead / Repository Coordinator**

Responsibilities:

- assign subagents;
- create branches/worktrees;
- maintain task dependencies;
- ensure tests are run;
- coordinate reviewers;
- merge completed work;
- maintain engineering status;
- ensure Git history remains coherent.

The coordinator should never allow an implementation agent to directly declare a milestone complete without verification.

---

# 27. Research Agents

## Agent A — OpenCFMoto Protocol Researcher

Research:

- QR format;
- pairing;
- connection endpoints;
- TCP/UDP usage;
- EasyConnect handshake;
- session messages;
- video negotiation;
- framing;
- heartbeat;
- reconnect;
- shutdown.

Outputs:

```text
OPENCFMOTO_RESEARCH.md
EASYCONNECT_PROTOCOL.md
protocol fixtures
```

Use dedicated branch:

```text
research/easyconnect-protocol
```

---

## Agent B — iOS Platform Researcher

Research:

```text
ScreenCaptureKit
background capture
permissions
NetworkExtension
NEHotspotConfigurationManager
Network.framework
VideoToolbox
Wi-Fi/cellular coexistence
```

Output:

```text
IOS_PLATFORM.md
RISKS.md
```

Branch:

```text
research/ios-platform
```

---

## Agent C — Architecture Agent

Consumes research from A and B.

Produces:

```text
SYSTEM_ARCHITECTURE.md
NETWORKING.md
VIDEO_PIPELINE.md
STATE_MACHINE.md
TEST_ARCHITECTURE.md
```

Branch:

```text
docs/system-architecture
```

---

# 28. Implementation Agents

## Protocol Agent

Owns:

```text
EasyConnect/
EasyConnectTests/
```

Branch:

```text
feat/easyconnect-core
```

---

## Networking Agent

Owns:

```text
Pairing/
Network/
```

Branch:

```text
feat/network-transport
```

---

## Capture Agent

Owns:

```text
Capture/
Video/
```

Branch:

```text
feat/capture-video
```

---

## Simulator Agent

Owns:

```text
Tools/DashSimulator/
Tests/Fixtures/
```

Branch:

```text
test/dash-simulator
```

---

## App Integration Agent

Owns:

```text
App/
UI/
Diagnostics/
```

Branch:

```text
feat/app-integration
```

---

# 29. Product Documentation Agent

Maintain:

```text
docs/product/
```

This agent consumes verified engineering behavior.

It should not infer unsupported capabilities.

Responsibilities:

- product overview;
- features;
- installation;
- compatibility;
- setup;
- usage;
- user testing;
- troubleshooting;
- FAQ;
- limitations;
- roadmap.

Typical branch:

```text
docs/product-beta-guide
```

---

# 30. Verification Agents

## iOS Reviewer

Review:

- lifecycle;
- concurrency;
- background execution;
- memory;
- capture API use;
- permission handling.

---

## Protocol Reviewer

Compare:

```text
Swift implementation
        ↕
EASYCONNECT_PROTOCOL.md
        ↕
OpenCFMoto observations
        ↕
binary fixtures
```

---

## Test Adversary

Attempt to break:

- parsers;
- reconnect;
- capture lifecycle;
- socket handling;
- orientation;
- malformed packets.

Add regression tests.

---

## Integration Verifier

Start with a clean checkout of the branch/merge candidate.

Run:

```text
build
tests
DashSimulator
integration flow
```

The verifier should record:

```text
Git commit SHA tested
Xcode version
iOS target
test result
```

This is important.

Verification must identify the exact Git revision being verified.

---

# 31. Verification Records

Each gate should record the tested revision.

Example inside `STATUS.md`:

```text
Gate 3 Verification

Commit:
8d39ab617...

Environment:
Xcode 28.0
iPhone 17 Pro
iOS 27.1

Result:
PASS

Tests:
148 passed
0 failed

Manual:
Waze foreground capture sustained 30 minutes.
```

This ties evidence to source history.

---

# 32. Dash Simulator

The project must include:

```text
Tools/DashSimulator/
```

It should simulate enough of the CFMoto display to test the application without a motorcycle.

Capabilities should eventually include:

```text
connection acceptance
handshake response
capability negotiation
heartbeats
video packet acceptance
frame recording
fault injection
forced disconnect
latency injection
packet drop
handshake rejection
```

The simulator should preferably be independently implemented from the iOS protocol library.

---

# 33. Synthetic Frame Source

Provide:

```text
ScreenFrameSource
├── RealScreenFrameSource
└── SyntheticFrameSource
```

Synthetic frames should permit deterministic tests.

Examples:

```text
solid colors
checkerboards
frame counters
resolution labels
moving test pattern
```

This allows:

```text
SyntheticFrameSource
        ↓
VideoPipeline
        ↓
EasyConnect
        ↓
DashSimulator
```

without ScreenCaptureKit or motorcycle hardware.

---

# 34. Test Layers

Use the following hierarchy:

```text
Unit tests
   ↓
Protocol fixture tests
   ↓
Component tests
   ↓
DashSimulator integration tests
   ↓
Physical iPhone tests
   ↓
450NK hardware-in-loop tests
```

---

# 35. Unit Testing

Cover:

```text
QR parsing
packet encoding
packet decoding
message framing
state transitions
heartbeat logic
timeouts
frame fragmentation
buffering
reconnect
error handling
```

---

# 36. Protocol Fixture Testing

Store sanitized fixtures:

```text
Tests/Fixtures/
├── qr/
├── handshake/
├── heartbeat/
├── capabilities/
└── video/
```

Tests should validate binary equivalence where appropriate.

---

# 37. Fault Injection

DashSimulator should support behaviors such as:

```text
--disconnect-after 10
--delay-ms 150
--drop-every 20
--reject-handshake
--stop-heartbeat-after 15
```

The iOS application must not crash.

---

# 38. CI

Configure GitHub Actions or equivalent CI early.

Every PR should run:

```text
checkout
dependency resolution
build
unit tests
protocol fixture tests
DashSimulator tests
static analysis where supported
```

CI status should correspond to the commit SHA being reviewed.

Merges into `main` should require successful CI once repository hosting permits branch protections.

---

# 39. Hardware Test Documentation

User-facing hardware testing procedures belong in:

```text
docs/product/TESTING_GUIDE.md
```

Engineering evidence belongs in:

```text
docs/engineering/HARDWARE_INTEGRATION.md
```

Example product test:

```text
TEST-PROJ-001

1. Start motorcycle.
2. Open MotoPlay.
3. Connect OpenCFMoto iOS.
4. Begin mirroring.
5. Launch Waze.
6. Leave running for 10 minutes.

Expected:
Waze remains visible on TFT.
```

Engineering result:

```text
TEST-PROJ-001

Bike:
2025 450NK US

App commit:
91bc87ef...

Firmware:
...

Result:
PASS

Observed FPS:
27.4

Reconnects:
0
```

---

# 40. Connection State Machine

Model explicitly:

```text
IDLE
 ↓
QR_PARSED
 ↓
JOINING_WIFI
 ↓
WIFI_CONNECTED
 ↓
CONNECTING
 ↓
NEGOTIATING
 ↓
READY
 ↓
CAPTURING
 ↓
PROJECTING
```

Possible error states:

```text
WIFI_FAILED
DASH_UNREACHABLE
HANDSHAKE_FAILED
CAPTURE_DENIED
ENCODER_FAILED
CONNECTION_LOST
STREAM_FAILED
```

Do not distribute lifecycle state across arbitrary SwiftUI callbacks.

---

# 41. MVP UI

Keep the MVP UI intentionally small.

## Pairing

```text
OpenCFMoto iOS

[ Scan MotoPlay QR ]

Bike:
CFMoto 450NK

[ Connect ]
```

---

## Ready

```text
450NK Connected

Projection: Ready

[ Start Mirroring ]
```

---

## Active

```text
Mirroring

FPS              28
Bitrate          4.0 Mbps
Dropped Frames   1
Reconnects       0
Connection       Healthy

[ Stop ]
[ Export Diagnostics ]
```

---

# 42. Diagnostics

Track:

```text
capture FPS
encoded FPS
sent frames
dropped frames
bitrate
network queue depth
reconnect count
session duration
thermal state
protocol state
```

Logs should use categories:

```text
wifi
network
protocol
handshake
heartbeat
capture
video
reconnect
lifecycle
```

Never log:

```text
Wi-Fi password
screen contents
navigation destination
private tokens
```

---

# 43. Development Gates

## Gate 0 — Research

Required:

```text
PRODUCT_REQUIREMENTS.md
OPENCFMOTO_RESEARCH.md
EASYCONNECT_PROTOCOL.md
IOS_PLATFORM.md
RISKS.md
LICENSING.md
```

Tag:

```text
mvp-gate-0
```

---

## Gate 1 — Protocol Core

Required:

```text
protocol encoder
protocol decoder
state machine
fixtures
unit tests
simulator handshake
```

Tag:

```text
mvp-gate-1
```

---

## Gate 2 — Synthetic Projection

Required:

```text
SyntheticFrameSource
        ↓
VideoPipeline
        ↓
DashSimulator
```

Tag:

```text
mvp-gate-2
```

---

## Gate 3 — Real Screen Capture to Simulator

Required:

```text
ScreenCaptureKit
        ↓
VideoPipeline
        ↓
DashSimulator
```

Verify Waze can become foreground.

Tag:

```text
mvp-gate-3
```

---

## Gate 4 — 450NK Test Pattern

Required:

```text
SyntheticFrameSource
        ↓
450NK TFT
```

The first target should be something unmistakable:

```text
┌─────────────────────┐
│                     │
│    HELLO 450NK      │
│                     │
└─────────────────────┘
```

Tag:

```text
mvp-gate-4
```

---

## Gate 5 — Full Mirroring

Required:

```text
Waze
 ↓
ScreenCaptureKit
 ↓
VideoPipeline
 ↓
EasyConnect
 ↓
450NK TFT
```

Tag:

```text
mvp-gate-5
```

---

## Gate 6 — MVP Candidate

Required:

```text
30-minute session
reconnect behavior
diagnostics
tests
product documentation
engineering documentation
clean Git history
independent review
clean build
```

Tag:

```text
v0.1.0-alpha
```

---

# 44. MVP Task Tracking

Maintain:

```text
docs/engineering/MVP_TASKS.md
```

Each task should contain:

```text
Task ID
Requirement IDs
Description
Dependencies
Branch
Owner/agent role
Acceptance criteria
Tests required
Documentation affected
Review status
Merge commit
```

Example:

```text
MVP-024

Requirement:
REQ-PROJ-005

Description:
Implement video packetization for negotiated projection session.

Branch:
feat/video-packetizer

Tests:
VideoPacketizerTests
DashSimulatorVideoTests

Docs:
VIDEO_PIPELINE.md
EASYCONNECT_PROTOCOL.md

Status:
Verified

Merge Commit:
4a71c22...
```

---

# 45. STATUS.md

Maintain a concise project status file.

Example:

```text
Current Gate:
Gate 2 — Synthetic Projection

Main Commit:
4a71c22

Completed:
- QR parser
- network transport
- handshake
- heartbeat

In Progress:
- frame packetization

Blocked:
- EasyConnect keyframe flag interpretation

Open Branches:
- feat/video-packetizer
- test/dash-simulator-video

Next:
- resolve keyframe behavior
- run simulator integration
```

A new Codex session should read this file immediately.

---

# 46. Product Documentation Testing

Product documentation itself should be validated.

A Documentation Verification Agent should ensure:

- installation steps match actual build process;
- buttons and labels match current UI;
- compatibility claims have evidence;
- testing procedures are executable;
- unsupported features aren't advertised;
- troubleshooting matches observed failures.

Product docs should be tested against a clean install whenever possible.

---

# 47. Definition of Done

A feature is complete only when:

```text
[ ] requirement exists
[ ] implementation exists
[ ] code builds
[ ] tests exist
[ ] tests pass
[ ] engineering docs updated
[ ] implementation agent self-reviewed
[ ] independent agent reviewed
[ ] review issues resolved
[ ] clean verifier run completed
[ ] commit SHA recorded
[ ] branch merged cleanly
[ ] product docs updated if verified user behavior changed
```

---

# 48. MVP Acceptance Checklist

The MVP is complete when:

```text
[ ] Fresh checkout builds.

[ ] Automated tests pass.

[ ] Protocol fixture tests pass.

[ ] DashSimulator tests pass.

[ ] QR configuration can be parsed.

[ ] iPhone can join the 450NK Wi-Fi network.

[ ] EasyConnect session can be established.

[ ] Synthetic frame appears on the TFT.

[ ] Full iPhone display appears on TFT.

[ ] Waze projection is validated.

[ ] Apple Maps projection is validated.

[ ] Projection operates >=30 minutes.

[ ] Temporary network interruption does not crash app.

[ ] Stop projection restores normal TFT behavior.

[ ] Diagnostics export works.

[ ] Sensitive information is excluded from logs.

[ ] Engineering docs reflect current implementation.

[ ] Product docs reflect verified functionality.

[ ] User setup guide has been followed successfully from a clean install.

[ ] User testing guide has been independently executed.

[ ] Git history contains meaningful development milestones.

[ ] Important milestones are tagged.

[ ] Every completed MVP task identifies its merge commit.

[ ] CI passes on the release candidate commit.

[ ] Independent verification reports no BLOCKER findings.

[ ] Release candidate is tagged v0.1.0-alpha.
```

---

# 49. Codex Startup Procedure

Every new coordinator session should execute this process:

```text
1. Inspect Git status.

2. Inspect current branch.

3. Read recent Git history.

4. Read:
   docs/engineering/README.md
   docs/engineering/STATUS.md
   docs/engineering/MVP_TASKS.md
   docs/engineering/PRODUCT_REQUIREMENTS.md

5. Inspect open/in-progress branches if available.

6. Run the existing test suite.

7. Confirm repository state matches STATUS.md.

8. Only then assign new work.
```

Useful commands include:

```bash
git status
git branch
git log --oneline --decorate -20
git tag --list
```

Codex should never assume that the previous chat context is more authoritative than the repository.

The repository is the project's persistent source of truth.

---

# 50. Codex Completion Procedure

At the end of every meaningful development task:

```text
1. Run relevant tests.

2. Run full build if practical.

3. Update engineering documentation.

4. Update STATUS.md.

5. Update MVP_TASKS.md.

6. Review git diff.

7. Ensure no credentials or artifacts were added.

8. Create meaningful commit(s).

9. Record verification status.

10. Notify coordinator branch is ready for independent review.
```

Do not leave completed work only as an uncommitted working-tree diff.

---

# 51. Agent Safety Rule for Git

Agents must never automatically perform destructive Git operations without a clear repository reason.

Avoid:

```text
git reset --hard
git clean -fd
git push --force
rewriting merged history
deleting another agent's worktree
```

unless explicitly coordinated and necessary.

Agents should inspect before modifying repository state.

---

# 52. Initial Codex Assignment

Start with research and repository foundation.

Do not begin by implementing the complete application.

Run four independent workstreams.

## Agent 1 — OpenCFMoto Research

Branch:

```text
research/easyconnect-protocol
```

Produce:

```text
OPENCFMOTO_RESEARCH.md
EASYCONNECT_PROTOCOL.md
protocol fixtures
```

---

## Agent 2 — iOS Capture Research

Branch:

```text
research/ios-screen-capture
```

Produce:

```text
IOS_PLATFORM.md
capture feasibility findings
```

---

## Agent 3 — iOS Networking Research

Branch:

```text
research/ios-networking
```

Produce findings covering:

```text
NEHotspotConfigurationManager
Network.framework
Wi-Fi routing
cellular coexistence
local network permission
```

---

## Agent 4 — Licensing Research

Branch:

```text
research/licensing
```

Produce:

```text
LICENSING.md
```

---

After the research branches are complete:

1. independently review each;
2. merge approved findings;
3. tag the resulting revision:

```text
mvp-gate-0
```

Then have the Architecture Agent produce the system specifications based on the merged research.

Do not architect against research that exists only in an unmerged agent worktree.

---

# 53. Fundamental Development Principle

The project should always be reproducible from the repository.

A future developer or Codex agent should be able to answer:

```text
What does the app currently support?
→ docs/product/

How is it implemented?
→ docs/engineering/

Why was it implemented this way?
→ DECISIONS.md + Git history

What remains unfinished?
→ STATUS.md + MVP_TASKS.md

How do we know it works?
→ automated tests + verification records

Which exact code was tested?
→ commit SHA + Git tags
```

Chat history should never be required to understand or continue the project.

The repository, documentation, tests, and Git history together are the authoritative project record.
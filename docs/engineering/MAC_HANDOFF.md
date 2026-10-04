# Mac handoff

The user requested a committed handoff from Windows on 2026-10-04 and reported access to a Mac, physical iPhone and CFMoto 450NK. Those resources have not been accessed from this session. Continue from [STATUS.md](STATUS.md) and [MVP_TASKS.md](MVP_TASKS.md), using the repository as the persistent record.

## Move the committed repository

The repository is uploaded to `git@github.com:Sking56/cfmoto-ios.git`. SSH authentication succeeded on retry; main, all four research branches and the annotated Gate 0 tag were pushed and their remote revisions checked. Clone it directly on your authenticated Mac:

```sh
git clone --branch main git@github.com:Sking56/cfmoto-ios.git OpenCFMoto-iOS
cd OpenCFMoto-iOS
git switch main
git status --short
git log --oneline --decorate -20
git tag --list
```

The clone's origin is already GitHub and main tracks origin/main. Research branch tips are available under origin/research/*; the original reviewed milestone tag remains unchanged.

The ignored `build/OpenCFMoto-iOS-handoff.bundle` is an optional offline copy of the committed source/history. If using that fallback, substitute its location and update the clone's remote:

```sh
git clone /path/to/OpenCFMoto-iOS-handoff.bundle OpenCFMoto-iOS
cd OpenCFMoto-iOS
git remote set-url origin git@github.com:Sking56/cfmoto-ios.git
git fetch origin
git branch --set-upstream-to=origin/main main
```

Ignored research downloads, agent worktrees, build products and signing credentials are excluded. Checked-in source citations and fixtures reproduce the research without them. Upload is complete; record native and hosted CI results against the exact revision actually tested.

## Run the first native verification

Use Python 3.10 or newer and Xcode with an iOS 27+ SDK plus an available iOS 27+ iPhone simulator. No pip packages or runtime third-party dependencies are needed for the foundation.

```sh
git rev-parse HEAD
xcodebuild -version
xcodebuild -showsdks
python3 Tools/verify_repository.py
python3 -m unittest discover -s Tests -p 'test_*.py' -v
python3 Tools/verify_xcode.py
open OpenCFMoto.xcodeproj
```

The native script builds/analyzes the app and runs the shared scheme's launch UI test, preserving an ignored `build/LaunchTests-*.xcresult`. A missing SDK/runtime returns explicit UNVERIFIED instead of passing. Record the exact commit, Xcode/SDK/runtime, command result and any diagnostics. Do not report native success from the Windows portable tests. Fix any native project/source errors on a short-lived branch with their verification record.

For physical-device installation choose your own development team and unique bundle identifiers in Xcode. The current skeleton should display `OpenCFMoto iOS`, `Research prototype`, and `Pairing and mirroring are not available yet.` It has no pairing or projection controls. A successful launch verifies only that skeleton.

## Resume the staged development

The first Mac continuation is recorded in [MAC_BASELINE.md](verification/MAC_BASELINE.md). The user subsequently upgraded to Xcode 27/iOS 27; native simulator build, analysis and launch pass from clean checkouts. Current [Gate 1 evidence](verification/GATE_1_HARDENING.md) records independently verified 21 Swift tests, 24 Python tests and 14 socket cases at fde4c81. Architecture/core have independent static approval for the synthetic scope and are merged at 18b771d7ab01e93d7b68202854ebfdd20b586baf. The local mvp-gate-1 checkpoint follows; new changes have not been pushed. Use Python 3.10+; bundled Python 3.12 was used. Physical signing, capture and hardware gates are tracked in [STATUS.md](STATUS.md).

Follow the brief's startup procedure. Check the research gate's recorded disposition and consume reviewed research/architecture on `main`. Gate 1 architecture is independently approved for its synthetic scope; later capture/network plans still require implementation and independent review.

Gate 2 encoded synthetic video and independent receiver decoding are approved at `603be12` and merged to local `main` at `44190bfc149bda862e86e941948d19e5ad8b4072`; [evidence](verification/GATE_2_HOST.md) records independent clean-checkout review/verification. The `mvp-gate-2` annotation records the exact final checkpoint's clean verification. The deterministic adapter send-completion/teardown test closes Gate 1's tracked gap. Two nonblocking coverage gaps remain before asynchronous capture work. Use `python3 Tools/verify_gate2.py` for all host tests, legacy sockets and decoded-video checks. The host probe's invented identity does not resolve Android identity/RSA compatibility, pairing mode or physical video acceptance. Resolve those through documented probes. Do not replace dash-pulled media with an unsolicited stream. The absent MotoPlay QR does not block SDK/capture-to-simulator work; Gate 3 is next.

Before capture implementation, audit the installed iOS SDK against [IOS_PLATFORM.md](IOS_PLATFORM.md), including iOS-only picker entry points and the macOS configuration members that lack documented iOS availability. Use its consent/background/device probe; it is a test plan and has not been implemented or executed. Add actual capabilities and usage keys when the corresponding behavior is implemented, then verify built/signed values.

Use [NETWORKING.md](NETWORKING.md) for persistent hotspot joining, phone-side callback listeners, outbound wake, local-network consent and cellular coexistence tests. Ordinary AP association versus P2P group negotiation remains a physical-450NK question.

Record physical results in [HARDWARE_INTEGRATION.md](HARDWARE_INTEGRATION.md). Gates 3–6 require real iPhone/450NK evidence, including Waze/Apple Maps foreground capture, a test pattern, full mirroring, at least 30 minutes, interruption recovery, stop/restoration and sanitized diagnostics. Update product support claims only after those checks pass.

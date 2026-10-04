# Mac handoff

The user requested a committed handoff from Windows on 2026-10-04 and reported access to a Mac, physical iPhone and CFMoto 450NK. Those resources have not been accessed from this session. Continue from [STATUS.md](STATUS.md) and [MVP_TASKS.md](MVP_TASKS.md), using the repository as the persistent record.

## Move the committed repository

The destination is `git@github.com:Sking56/cfmoto-ios.git`, configured as this workspace's `origin`. GitHub rejected this Windows machine's SSH authentication and existing HTTPS credentials, so upload remains pending and the remote's contents have not been inspected.

The coordinator refreshes `build/OpenCFMoto-iOS-handoff.bundle` after committing handoff changes. Copy that bundle to your authenticated Mac; it preserves commits, research branches and verified milestone tags. A bundle is a source handoff, not an installable iOS application.

On the Mac, substitute the bundle's actual location:

```sh
git clone /path/to/OpenCFMoto-iOS-handoff.bundle OpenCFMoto-iOS
cd OpenCFMoto-iOS
git switch main
git status --short
git log --oneline --decorate -20
git tag --list
```

The clone's `origin` initially points to the local bundle. Set the selected GitHub destination, check access and existing refs, then upload the committed history:

```sh
git remote set-url origin git@github.com:Sking56/cfmoto-ios.git
git ls-remote origin
git push -u origin main --follow-tags
git push origin 'refs/remotes/origin/research/*:refs/heads/research/*'
```

The last command preserves the four research branch tips created as remote-tracking refs by the bundle clone. If Git reports an existing branch/tag conflict, inspect the remote history before resolving it; a normal push preserves existing remote history. After successful upload, fresh Mac checkouts can use `git clone git@github.com:Sking56/cfmoto-ios.git OpenCFMoto-iOS` directly.

Ignored research downloads, agent worktrees, build products and signing credentials are excluded. Checked-in source citations and fixtures reproduce the research without them. Record the actual uploaded revision and hosted CI outcome when available.

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

Follow the brief's startup procedure. Check the research gate's recorded disposition before creating architecture. An architecture agent must consume the reviewed research on `main`; the architecture placeholders are not approved specifications.

Then build Gate 1 protocol core and an independently implemented Dash Simulator before adding synthetic video (Gate 2). Resolve the Android identity/RSA transformation compatibility, target pairing mode, raw-video boundary and fresh-keyframe behavior through the documented probes. Do not replace dash-pulled media with an unsolicited stream.

Before capture implementation, audit the installed iOS SDK against [IOS_PLATFORM.md](IOS_PLATFORM.md), including iOS-only picker entry points and the macOS configuration members that lack documented iOS availability. Use its consent/background/device probe; it is a test plan and has not been implemented or executed. Add actual capabilities and usage keys when the corresponding behavior is implemented, then verify built/signed values.

Use [NETWORKING.md](NETWORKING.md) for persistent hotspot joining, phone-side callback listeners, outbound wake, local-network consent and cellular coexistence tests. Ordinary AP association versus P2P group negotiation remains a physical-450NK question.

Record physical results in [HARDWARE_INTEGRATION.md](HARDWARE_INTEGRATION.md). Gates 3–6 require real iPhone/450NK evidence, including Waze/Apple Maps foreground capture, a test pattern, full mirroring, at least 30 minutes, interruption recovery, stop/restoration and sanitized diagnostics. Update product support claims only after those checks pass.

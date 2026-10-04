# Native Xcode 27 verification

Date: 2026-10-04. Initial tested revision: `024fb3da7e923527ddb606a5a2d826cc6a686be4`. Corrected revision, verified from a fresh detached checkout: `a5a75ae2fd0b5cc27eb22fca5b916dc13e77146b`. Branch: `codex/architecture-protocol-core`. Coordinator verification; independent architecture/protocol review remains pending.

## Environment and results

macOS 27.0.1 (26A434), Xcode 27.0 (27A266a), Apple Swift 6.4 (swiftlang-6.4.0.34.1), iOS/iOS Simulator SDK 27.0. Python 3.12.14 from the bundled runtime. Active developer directory: `/Applications/Xcode.app/Contents/Developer`.

`Tools/verify_xcode.py` exited 0 on both revisions. It ran the shared OpenCFMoto scheme with `CODE_SIGNING_ALLOWED=NO`, built/analyzed for the generic iOS Simulator destination, then ran the launch UI test on an arm64 iPhone Air simulator, iOS 27.0 (24A434), UDID `F0885868-B8B2-4FE9-BCC5-DE535995734C`.

| Check on corrected revision | Result |
|---|---|
| Native simulator build, including all Pairing/EasyConnect sources | PASS |
| Xcode analyzer | PASS |
| `LaunchTests.testLaunchShowsPrototypeStatus` | PASS: 1 test, 0 failures, 0 skipped |
| `xcresulttool get test-results summary` | Passed; no runtime warnings or test failures |
| Fresh detached checkout status before/after native checks | Clean; build output ignored |

The initial run exposed main-actor isolation warnings in the launch test. Commit `a5a75ae` annotates the test method `@MainActor`. The fresh native run has no actor-isolation/compiler warnings for the test or app sources. Xcode still reports skipped AppIntents metadata extraction because the targets do not depend on AppIntents; no AppIntents capability is implemented or claimed.

Ignored artifacts retained in the original checkout:

```text
build/native-verification-024fb3d.log
build/LaunchTests-20261004T212019567592Z.xcresult
build/native-verification-main-actor.log
build/LaunchTests-20261004T212334910709Z.xcresult
build/host-verification-xcode27.log
```

The corrected result bundle was copied out of the temporary clean checkout before cleanup. The original checkout's pre-existing untracked Xcode workspace was left untouched and was absent from the fresh checkout.

Host regression at initial revision `024fb3d` under the updated compiler: `Tools/verify_gate1.py` PASS, 15 Swift tests and seven independent loopback socket cases. The protocol sources are unchanged in corrected revision `a5a75ae`. The 22 Python tests and portable repository checks also pass on `a5a75ae`. CoreSimulator and localhost tests required access outside the workspace sandbox; no physical iPhone or TFT was accessed.

## Installed capture header spot-check

Inspected `ScreenCaptureKit.framework/Headers/SCContentSharingPicker.h` and `SCStream.h` in the installed `iPhoneOS27.0.sdk`. Picker `present()` and `presentForCurrentApplication()` have iOS 27 availability. The headers explicitly mark `allowedPickerModes`, `singleDisplay`, `minimumFrameInterval`, `pixelFormat` and `queueDepth` unavailable on iOS, consistent with the earlier research warning. They also mark `SCStream.updateContentFilter` and `updateConfiguration` unavailable on iOS; future source replacement/reconfiguration must use a supported lifecycle rather than those macOS methods.

This was a header inspection, not a complete Swift capture declaration probe or a capture/runtime test. The native app does not import/use ScreenCaptureKit yet. System picker availability/consent, video-only background operation, delivered buffer formats, navigation foreground capture and stream replacement all remain physical-device acceptance work.

## Disposition

The missing iOS 27 SDK/runtime blocker is resolved. Native foundation compilation, analysis and skeleton launch are verified at the corrected revision. No physical-device signing/install, hotspot association, hardware identity/RSA, encoded video, full-display capture, 450NK projection, recovery/restoration or 30-minute endurance is established. No Gate 1 tag, merge, release or remote push was made. Continue independent architecture/protocol review and Gate 1 completion before Gate 2 synthetic encoded projection and the physical capture/hardware gates.

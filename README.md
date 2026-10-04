# OpenCFMoto iOS

Research-stage native iOS proof of concept for mirroring an iPhone onto the CFMoto 450NK MotoPlay / Carbit / EasyConnect TFT.

The controlling brief is [CFMoto_IOS_MVP_V1.md](CFMoto_IOS_MVP_V1.md). Start with [engineering status](docs/engineering/STATUS.md), [task tracking](docs/engineering/MVP_TASKS.md), and [product limitations](docs/product/LIMITATIONS.md).

The application UI remains a SwiftUI launch skeleton. The Swift QR/protocol/negotiation core and synthetic Python dashboard peer are independently reviewed/tested. Gate 2 adds actual synthetic H.264 encoding and independent receiver decode, approved at `603be12`; [evidence](docs/engineering/verification/GATE_2_HOST.md). Camera pairing, production phone networking, screen capture and TFT projection are not integrated or verified. No hardware compatibility is claimed.

## Development

Open `OpenCFMoto.xcodeproj` on a Mac with Xcode and an iOS 27 or newer SDK. The minimum deployment target follows the brief: iOS 27.0. Choose your own development team and unique bundle identifier for physical-device installation; no team or signing credentials are stored here.

```sh
python Tools/verify_repository.py
python -m unittest discover -s Tests -p 'test_*.py' -v
python Tools/verify_xcode.py
python Tools/verify_gate2.py
```

Use Python 3.10+; the shell's default Python may be older. The first two commands are portable foundation checks. The third requires macOS, Xcode, and an installed iOS 27+ iPhone simulator and performs build/analyze plus a launch UI test. It fails explicitly if those prerequisites are unavailable. The fourth uses macOS/Swift 6/VideoToolbox for host tests, synthetic loopback negotiation and receiver video decode; local socket access is required. `verify_gate1.py` remains available for legacy protocol cases. Host checks do not establish that the iOS app compiles or projects anything.

CI is configured in `.github/workflows/ci.yml`. Committed history, four research branches and the `mvp-gate-0` tag have been uploaded to [Sking56/cfmoto-ios](https://github.com/Sking56/cfmoto-ios); local `main` tracks `origin/main`. Native and hosted CI results require their own verification. The [engineering index](docs/engineering/README.md) describes research and verification records. The [product index](docs/product/README.md) describes what a tester can currently do.

Licensing is undecided for this new repository; see [LICENSE](LICENSE). Reference research must preserve upstream provenance and must not silently copy code.

Reviewed research and the independently verified Gate 1/2 synthetic implementation are integrated on local `main`. Gate 2 passed independent clean host/portable/native checks with Xcode 27; `mvp-gate-2` marks the final checkpoint only after its own clean verification. The earlier gate tags remain unchanged. These changes are not uploaded; signed-device and hardware evidence remain pending. Follow the [Mac handoff guide](docs/engineering/MAC_HANDOFF.md) and [current status](docs/engineering/STATUS.md).

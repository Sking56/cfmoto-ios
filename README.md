# OpenCFMoto iOS

Research-stage native iOS proof of concept for mirroring an iPhone onto the CFMoto 450NK MotoPlay / Carbit / EasyConnect TFT.

The controlling brief is [CFMoto_IOS_MVP_V1.md](CFMoto_IOS_MVP_V1.md). Start with [engineering status](docs/engineering/STATUS.md), [task tracking](docs/engineering/MVP_TASKS.md), and [product limitations](docs/product/LIMITATIONS.md).

The initial application is a SwiftUI launch skeleton. Pairing, networking, capture, encoding, and projection are not implemented or verified. No hardware compatibility is claimed.

## Development

Open `OpenCFMoto.xcodeproj` on a Mac with Xcode and an iOS 27 or newer SDK. The minimum deployment target follows the brief: iOS 27.0. Choose your own development team and unique bundle identifier for physical-device installation; no team or signing credentials are stored here.

```sh
python Tools/verify_repository.py
python -m unittest discover -s Tests -p 'test_*.py' -v
python Tools/verify_xcode.py
```

The first two commands are portable foundation checks. The third requires macOS, Xcode, and an installed iOS 27+ iPhone simulator and performs a build plus a launch UI test. It fails explicitly if those prerequisites are unavailable. Passing portable checks does not establish that the app compiles or projects anything.

CI is configured locally in `.github/workflows/ci.yml`; no remote repository or hosted CI run is currently established. The [engineering index](docs/engineering/README.md) describes research and verification records. The [product index](docs/product/README.md) describes what a tester can currently do.

Licensing is undecided for this new repository; see [LICENSE](LICENSE). Reference research must preserve upstream provenance and must not silently copy code.

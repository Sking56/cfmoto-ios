# Native unit tests

`PairingTests`, `WireCodecTests` and `NegotiationTests` are XCTest suites built by the dependency-free Swift package. They test the same core sources included in the app, using the committed invented fixtures under `Tests/Fixtures`. Run `python3 Tools/verify_gate1.py` with Python 3.10+ and Swift 6 on macOS for unit tests plus independent loopback socket cases.

These are host unit tests; an iOS unit-test target has not been added. The Xcode scheme still uses `OpenCFMotoUITests` for launch/prototype status, and `Tools/verify_xcode.py` still requires iOS 27+ SDK/runtime. Portable checks live under `Tests/`. Host success does not verify native launch or hardware behavior.

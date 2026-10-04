# First Mac baseline

Date: 2026-10-04. Tested committed revision: `cd5d9a47aada71f211b0d8f73eff180dd89f87e5`. Tracked tree was clean; an existing untracked `OpenCFMoto.xcodeproj/project.xcworkspace/` was present and left intact.

Environment: macOS 14.6.1 (23G93), Xcode 16.2 (16C5032a), iOS/iOS Simulator SDK 18.2, Apple Swift 6.0.3, bundled Python 3.12.14. Shell `python3` resolves to Python 3.8, below the documented Python 3.10 minimum; it fails importing modern type annotations. No application defect is inferred from using that unsupported interpreter.

Using `/Users/sjc/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3`:

```text
Tools/verify_repository.py: PASS
-m unittest discover -s Tests -p 'test_*.py' -v: PASS, 17 tests
Tools/verify_xcode.py: exit 2, UNVERIFIED: active Xcode has no iOS 27+ simulator SDK
```

The native verifier printed the exact revision, Xcode build and SDK inventory before stopping. No native app compilation, analyzer, UI launch, signing or physical check was run. The app target remains iOS 27.0. Resume protocol work with host tests, and run the required native/device gates when a matching toolchain is available.

# Foundation and licensing cross-review

Review date: 2026-10-04. Reviewer: iOS capture research agent, independent of the coordinator who authored the foundation/licensing changes. This review does not independently review the capture agent's own research and does not verify native/device behavior.

## Exact review targets

| Surface | Reviewed commit | Scope |
|---|---|---|
| Repository foundation | `51df63b86002f749b2ae5d93e3b4fa3837a7d7a9` | Xcode project and generator, shared scheme, SwiftUI launch skeleton, launch UI test, portable/native verification scripts, tracked inventory and CI configuration. |
| Licensing research | `7b4d8b9d475c25e1aec1799ec9ffaea49108de60` | `docs/engineering/LICENSING.md`, its pinned evidence and reuse boundaries. |
| Upstream evidence | `zanderp/open-cfmoto` at `0abbe2a70119d6dd46ac6b8a0715ff267fcdb316` | LICENSE, NOTICE, README licensing section, app dependency declaration, and four sampled Kotlin headers. |

Read committed snapshots with `git show`, not the capture branch's older foundation copies. Executed checks against a temporary `git archive` export of the exact foundation SHA in the capture worktree's ignored build directory. The upstream local clone reported the exact pinned SHA and an empty porcelain status. No reviewed source files were edited.

## Findings and disposition

No unresolved actionable defects found in the reviewed foundation or corrected licensing research. Suitable for coordinator integration as repository/research work, with the verification limitations below retained. This is not a declaration that an MVP gate requiring a native build or device behavior has passed.

One provenance error in the earlier licensing commit `c3899d019a302a20b9f7b355dcb3c67417f5085b` had incorrectly grouped `QrData.kt` among files with AGPL SPDX headers. The coordinator corrected it in `7b4d8b9d475c25e1aec1799ec9ffaea49108de60` before this review concluded. Independently confirmed that `BikeLink.kt` and `BikeWifi.kt` have `AGPL-3.0-or-later` headers, while `QrData.kt` and `PxcHandshake.kt` start with package declarations. The revised research treats the missing per-file headers as a provenance question rather than a permissive license grant. Resolved severity: P2 (incorrect research evidence).

## Foundation review evidence

- The app target includes the SwiftUI `@main` source and produces an application; the UI test target includes `LaunchTests.swift`, produces a UI-testing bundle, names the app as its test target, and depends on it through a target dependency/proxy. Project object references and source paths pass the portable structural checker.
- The shared scheme's build/run actions reference the app and its test action references the UI test target. The UI test launches `XCUIApplication` and checks the prototype title identifier plus the research-stage and unavailable-feature text actually present in the app source.
- Project-level Debug/Release configurations declare iOS 27.0 and Swift 6.0. App configurations request generated Info.plist, launch screen and scene manifest, and iPhone family. No signing team/credentials, screen-capture implementation or runtime external library is present in this foundation snapshot.
- The generator reproduces the checked-in project and shared scheme **text content** on Windows. This is a consistency check, not validation by Xcode's project parser or a native build.
- The native verifier checks host/Xcode, requires an iOS 27+ simulator SDK and available iPhone runtime, then runs build/analyze and a UI test. It uses a timestamped result-bundle path so a prior run does not reuse an existing `.xcresult` destination. SDK absence is explicit rather than a passing skip.
- CI invokes the same portable and native commands, has bounded job timeouts, read-only repository permission and checkout credential persistence disabled. No remote or hosted CI run is claimed by this review; runner SDK availability and action execution have not been tested here.

| Check on archived foundation SHA above | Actual result |
|---|---|
| `python Tools/verify_repository.py` | PASS, exit 0. Structure, references, scheme XML and local documentation links. |
| `python -m unittest discover -s Tests -p 'test_*.py' -v` | All 8 existing tests pass, exit 0. Includes checker failure paths and simulator selection. |
| `python Tools/generate_xcode_project.py` followed by content comparison | Project and scheme match their original archived content. |
| `python Tools/verify_xcode.py` | Exit 2, explicit `UNVERIFIED` because macOS/Xcode/iOS 27+ SDK are unavailable. No native command or UI launch executed. |

## Licensing review evidence

Checked the pinned [LICENSE](https://github.com/zanderp/open-cfmoto/blob/0abbe2a70119d6dd46ac6b8a0715ff267fcdb316/LICENSE), [NOTICE](https://github.com/zanderp/open-cfmoto/blob/0abbe2a70119d6dd46ac6b8a0715ff267fcdb316/NOTICE), [README licensing section](https://github.com/zanderp/open-cfmoto/blob/0abbe2a70119d6dd46ac6b8a0715ff267fcdb316/README.md#-license), and [build declaration](https://github.com/zanderp/open-cfmoto/blob/0abbe2a70119d6dd46ac6b8a0715ff267fcdb316/app/build.gradle.kts) through the matching clean local clone. The LICENSE contains AGPL v3; NOTICE grants version 3 or later, attributes the Android Auto receiver lineage, and describes earlier forks lacking explicit licenses. README's alternate-licensing discussion excludes incorporated upstream components from the author's unilateral relicensing power. The corrected research records these distinctions without adopting upstream contributor terms for this repository.

Confirmed the explicit OkHttp dependency in `app/build.gradle.kts` and its absence from NOTICE's dependency account. The research appropriately warns that NOTICE is not a complete dependency audit. The foundation tracked-file inventory contains no imported Kotlin, receiver source, APK, third-party runtime library or upstream license text; its own LICENSE remains a decision placeholder.

Cross-checked the general translation caution with the official [FSF translation FAQ](https://www.gnu.org/licenses/gpl-faq.html#TranslateCode), and the research's bounded treatment of network interaction against [AGPL section 13](https://www.gnu.org/licenses/agpl-3.0-body.html). These sources support a reuse warning, not a definitive legal classification of an independently authored future Swift implementation. Complete contributor rights, individual file lineage and any eventual distribution obligations remain outside this factual source review.

## Verification still required

Native project parsing, Swift compilation, analyzer results, generated built-product Info.plist, signed device installation and the UI test must be run on the specified Mac/SDK. Capture consent/background execution, encoder behavior, Wi-Fi/cellular coexistence, motorcycle compatibility and continuous projection are unverified. A portable structural pass does not substitute for these results.

The owner must decide the new repository's license before distribution, and future code reuse must record its own provenance and obligations. The reviewed licensing document explicitly leaves that decision unresolved. No production/App Store release was requested or reviewed.

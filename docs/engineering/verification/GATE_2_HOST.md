# Gate 2 synthetic video verification

Date: 2026-10-04. Exact reviewed/tested candidate: `603be1247c9330e20d3e9eae4c07d9b6f3b40c71` on `codex/synthetic-projection`, based on the unchanged `mvp-gate-1` checkpoint. Coordinator and independent clean-checkout verification PASS; integration/milestone state is recorded below and in [STATUS](../STATUS.md).

Coordinator verification used a fresh detached checkout at `.worktrees/gate2-coordinator`. Status was empty before testing, after deterministic project regeneration and after all checks. The primary checkout's pre-existing untracked Xcode workspace was not included, staged or removed. Build/cache products were ignored. Loopback, VideoToolbox and CoreSimulator execution required sandbox escalation; no physical phone, bike or external peer was contacted.

Environment: macOS 27.0.1 (26A434), Xcode 27.0 (27A266a), Swift 6.4, iOS/iOS Simulator SDK 27.0, bundled Python 3.12.14. Native destination is arm64 iPhone Air, iOS 27.0 (24A434), simulator `F0885868-B8B2-4FE9-BCC5-DE535995734C`.

## Exact Candidate Checks

| Command | Coordinator result |
|---|---|
| `python3 Tools/verify_repository.py` | PASS: structure, references, scheme and documentation links |
| `python3 -m unittest discover -s Tests -p 'test_*.py' -v` | PASS: 27 tests |
| `python3 Tools/verify_gate2.py` | PASS: fresh build, 33 Swift tests, 14 legacy socket cases, two decoded-video cases and four inspector rejection cases |
| `python3 Tools/generate_xcode_project.py` then `git status --porcelain --untracked-files=all` | PASS: empty status; deterministic source/project/scheme generation |
| `plutil -lint OpenCFMoto.xcodeproj/project.pbxproj` | PASS |
| `python3 Tools/verify_xcode.py` | PASS, exit 0: native simulator build, analysis and one launch UI test |
| `xcrun xcresulttool get test-results summary --path build/LaunchTests-20261004T224445846716Z.xcresult --format json` | Passed: one test, zero failures/skips/expected failures and empty structured runtime-warning list |

The 33 Swift tests comprise 21 pure core, five host-adapter and seven video tests. Deterministic adapter tests close Gate 1's P3 callback-ordering gap: hold DATA_START acknowledgement pending through DATA_NEXT, then complete after teardown; success cannot precede draining and late completion cannot resurrect a stopped generation. Invalid port configurations fail without indexing traps. Encoder tests inject submission/flush/missing-output failures and require terminal invalidation before another frame can be submitted. Queue tests prove byte/count bounds, chain purge/keyframe recovery, stop and stale-generation rejection.

Each video socket case receives twelve actual encoded 800x384 synthetic frames. A separate executable, with no producer/core dependency, parses the raw/Annex-B bytes and reconstructs the H.264 decoding format. VideoToolbox produces decoded pixels checked for RGB bars and a moving marker, Baseline 3.1, and fresh SPS/PPS/IDR on initial start and restart before frame seven. One-byte and coalesced request writes pass. Idle checks reject unsolicited output between pulls; raw frame replies have only the four-byte LE length and Annex-B payload. Four independent inputs reject empty/truncated/oversized/missing-startup media.

An earlier working-tree full run passed all 33 Swift tests but hit the existing dashboard subprocess deadline in the legacy early-start case. That run is not reported as PASS. The isolated case, subsequent full working-tree run and this clean exact-candidate run all pass. No timeout was changed or failure ignored to obtain those results; it remains a possible test-timing flake, not evidence of a known resolved transport defect.

Ignored coordinator artifacts were preserved in the primary checkout as `build/gate2-host.log`, `build/gate2-native.log` and `build/LaunchTests-20261004T224445846716Z.xcresult`. The native log contains the existing AppIntents metadata-extraction warning (no framework dependency); the test passes with no compiler/analyzer errors. Historical working-tree logs remain separate from exact-commit evidence.

## Independent Review And Verification

User authorized the independent workflow. Reviewer Cicero (`01a10901-1af1-7e02-8fb2-7ae85e90bdeb`) did not author the implementation. Initial static review identified a P2 encoder error path that could reuse an uncertain predictive chain; the encoder now invalidates on any submission/flush/output failure, with deterministic tests. The nonblocking P3 public-adapter port validation issue was also fixed/tested. Final static disposition: APPROVE the documented synthetic Gate 2 scope at exact revision `603be1247c9330e20d3e9eae4c07d9b6f3b40c71`, with no blocking correctness findings. Gate 1's P3 held-completion/teardown gap is resolved for the control adapter; this does not establish asynchronous video-backpressure coverage. Busy DATA_START rejection remains an explicit prototype restriction, not support for overlapping restart.

Two nonblocking P3 coverage gaps remain, tracked before expanding into asynchronous capture: the socket test sends/reads video pulls individually rather than batching pulls or holding video-send completion; startup assertions require SPS/PPS/IDR presence rather than explicitly asserting their wire order. Static review confirms the producer emits the correct order. These are not reclassified as resolved and do not extend the current synchronous prototype approval.

Independent runtime disposition: PASS, approve the synthetic Gate 2 candidate. Cicero independently executed every Python command in the table, project lint and structured result inspection in a separate detached clean checkout at `.worktrees/gate2-independent`. All required commands exited 0: 27 Python tests, 33 Swift tests, 14 legacy socket cases, two cases with twelve decoded frames each, four inspector rejections, deterministic regeneration and native build/analyze/one skeleton UI test. Exact SHA was checked initially/finally and porcelain status remained empty before/after regeneration and at completion. This result is separate from coordinator execution.

Independent ignored evidence was preserved in the primary checkout as `build/gate2-independent-host.log`, `build/gate2-independent-native.log` and `build/LaunchTests-20261004T224909389901Z.xcresult`. Result summary reports Passed, zero failures and `runtimeWarnings: []`. Its first summary-read attempt exited 64 on cache permissions; the authorized escalated retry passed. Native logs retain AppIntents metadata-skip warnings, debugger-version lookup notices and a simulator duplicate-class notice. No source compiler/analyzer errors occurred. Temporary checkouts can be removed after preserving these artifacts; no required verification session remains running.

## Integration Checkpoint

The reviewed source is unchanged after `603be12`; subsequent commits record evidence/status only. Evidence was committed at `d9135e1` and the branch merged without conflicts to local `main` at `44190bfc149bda862e86e941948d19e5ad8b4072`. The final follow-up records that merge and changes documentation only. The local annotated `mvp-gate-2` checkpoint is created only after the exact final documentation/integration revision passes its own clean portable/host/native checks. Its annotation records the checkpoint SHA/results and source-review SHA. Gate 1 history/tag remains unchanged. No branch, tag or CI run is uploaded by this session.

## Limits

This gate covers `SyntheticFrameSource -> VideoPipeline -> DashSimulator`, not a usable mirroring app. Video sources compile in the app, but the launch test only exercises the SwiftUI skeleton. The host adapter uses invented `synthetic-no-crypto` identity and loopback, emits only twelve on-demand frames and terminates after writes drain. Send completion alone is not a display acknowledgement. Producer/inspector have independently authored parsers/processes but share Apple's codec engine; no cross-codec or firmware acceptance is proved. The old framing-only fixture is still non-decodable and is not the media evidence.

Single-in-flight synchronous encoding/flushing is not a sustained-FPS benchmark or asynchronous capture/Stop design. Queue overload/stale-generation tests are deterministic, not observed physical socket congestion. Changed active capture configuration is rejected by the prototype. No real screen/video content is saved; received synthetic units stay in bounded memory. Physical signing/install, identity/RSA, association/routing/cellular coexistence, full-display consent/background capture, TFT trailer/geometry acceptance, recovery/restoration/thermal behavior and 30-minute endurance remain unverified or unimplemented. No alpha release, remote push or hosted CI result is claimed.

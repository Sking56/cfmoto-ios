# Gate 1 bounded-writer verification

Date: 2026-10-04. Exact candidate tested: `fde4c817ce75514d973f00820e21498f35ade4b6` on `codex/architecture-protocol-core`. This extends the original [host candidate](GATE_1_HOST.md) and [Xcode 27 native verification](NATIVE_XCODE_27.md); historical records remain unchanged.

Coordinator verification used a fresh detached checkout at `.worktrees/gate1-hardening-verification`. Its porcelain status was empty before testing, after project regeneration and after all checks. The primary checkout's pre-existing untracked Xcode workspace was not included, staged or removed. Build/cache products were ignored. Loopback/CoreSimulator checks required sandbox escalation; no physical phone, bike or external network endpoint was contacted.

Environment: macOS 27.0.1 (26A434), Xcode 27.0 (27A266a), Swift 6.4, iOS/iOS Simulator SDK 27.0, bundled Python 3.12.14. Native launch ran on arm64 iPhone Air, iOS 27.0 (24A434), simulator `F0885868-B8B2-4FE9-BCC5-DE535995734C`.

## Checks

| Command | Result on the exact candidate |
|---|---|
| `python3 Tools/verify_repository.py` | PASS: portable structure, references, scheme and documentation links |
| `python3 -m unittest discover -s Tests -p 'test_*.py' -v` | PASS: 24 tests |
| `python3 Tools/verify_gate1.py` | PASS: fresh Swift build, 21 XCTest tests and 14 independent loopback cases |
| `python3 Tools/generate_xcode_project.py` then `git status --porcelain` | PASS: empty status; deterministic project/scheme regeneration |
| `python3 Tools/verify_xcode.py` | PASS, exit 0: native simulator build, analysis and one launch UI test |
| `xcrun xcresulttool get test-results summary --path build/LaunchTests-20261004T215144772712Z.xcresult --format json` | Passed: one test, zero failures/skips/expected failures and an empty structured runtime-warning list |

The six new Swift writer tests prove FIFO, a single in-flight write, count/byte caps including stalled completion, atomic batch rejection, independent connection budgets, close/purge and late-completion rejection. The host adapter uses the queue on every connection, caps pre-wake evidence with a set, records media-channel evidence only after connection readiness, and waits for writes/partial inbound frames before reporting one-shot success.

Socket cases include one-byte/coalesced success, callbacks before wake acceptance, rejected wake, invalid XOR, oversized/truncated PXC, unsupported command, duplicate PXC/media callbacks, missing CAR_DATA, early DATA_START/DATA_NEXT and disconnect. Failure cases require a specific termination reason rather than accepting any nonzero exit. Queue backpressure is exercised deterministically in core tests, not by assuming a particular kernel send-buffer size.

Ignored native artifacts were preserved in the primary checkout: `build/native-fde4c81.log` and `build/LaunchTests-20261004T215144772712Z.xcresult`. The log contains the existing AppIntents metadata-extraction warning (no framework dependency), a simulator-system duplicate accessibility-class notice and debugger-version lookup messages. The UI test passes; these notices are not silently classified as application failures or removed from the evidence.

## Review And Limits

Independent reviewer Hume (`01a108e1-9d56-76f1-bfbc-19f3cba15668`), who did not author the implementation, approved the architecture and protocol core at exact revision `fde4c817ce75514d973f00820e21498f35ade4b6` for the explicitly synthetic Gate 1 scope. The read-only static review found no blocking correctness findings and required no code changes. It checked framing, capture validation, token-zero replies, CHECK_SN identity, complete readiness evidence, bounded FIFO writes and terminal cleanup against the reviewed specification.

One nonblocking P3 test gap remains: add a deterministic adapter test holding Network send completion pending through DATA_NEXT and then delivering completion after teardown. Queue unit tests cover accounting/closure, but the socket cases do not force that callback ordering. This is a Gate 2 prerequisite before extending the adapter into the media path, not a current handshake blocker. No issue was reclassified as resolved without a test.

Independent verifier disposition: PASS, approve the synthetic protocol-core Gate 1 candidate. Hume independently executed all five Python commands in the table above in a separate detached clean checkout at `.worktrees/gate1-independent-verification`, confirmed the exact SHA, and reported exit 0 for each: 24 Python tests, 21 Swift tests, 14 socket cases, deterministic generation and native build/analyze/one launch test. `git status --porcelain --untracked-files=all` remained empty afterward. This runtime result is separate from the coordinator checks and the prior static review.

Independent native evidence was preserved in the primary checkout as `build/independent-native-fde4c81.log` and `build/LaunchTests-20261004T215642163358Z.xcresult` before removing the temporary checkout. The same AppIntents/simulator/debugger notices occurred, with no source compiler/analyzer errors or failed tests. There is no remaining independent verification blocker for this Gate 1 scope. Integration/milestone state is tracked in [STATUS](../STATUS.md); no remote publication is authorized or claimed.

## Integration Checkpoint

Review/evidence documentation was committed at `155dc22`; the branch merged without conflicts to `main` at `18b771d7ab01e93d7b68202854ebfdd20b586baf`. The final follow-up records that merge and updates task/handoff status; it changes documentation only. The annotated local `mvp-gate-1` tag identifies the exact final checkpoint, and is created only after its own fresh-checkout portable, Swift/socket and native checks pass. Its annotation records the checkpoint verification and source-review SHA. No tag or branch is uploaded by this session.

This milestone certifies only the brief's Gate 1 protocol encoder/decoder, state, fixtures, unit tests and synthetic simulator handshake. The one P3 adapter-callback ordering test remains tracked before Gate 2 media work. It is not a mirroring release or proof of hardware compatibility.

The queue limits (64 writes/256 KiB per connection) are defensive control-path limits, not firmware/video limits. Network completion does not prove receiver consumption. The probe still uses invented identity, sends no video, exits after an empty pull, and is not production iPhone transport. Hardware identity/RSA, periodic outbound liveness/recovery, physical signing/association/cellular routing, capture/background lifetime, encoded video and TFT/restoration/endurance remain unverified or unimplemented as applicable. No verified product behavior changes.

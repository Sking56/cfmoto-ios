# iOS networking research

Research date: 2026-10-04. Task: MVP-004, brief section 52. Requirements: REQ-NET-001, REQ-NET-002, REQ-NET-003; related REQ-REC-001 and REQ-LOG-002.

Status: source research was independently reviewed and merged at `0ddff39c576c8087e94059ef6459152465c5b83d`. The repository contains a launch skeleton; no iPhone, dashboard, native app build, cellular coexistence or background network behavior was tested. The post-research candidate architecture is in [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md); its independent review is pending.

The APIs support joining an ordinary accessory Wi-Fi network with consent and constraining individual TCP listeners/connections to Wi-Fi. They do not guarantee that navigation apps retain Internet connectivity or that the projection process keeps running in the background. Those are separate physical-device acceptance criteria.

## Scope and evidence boundaries

- **Apple source facts** below describe documented API behavior, not motorcycle compatibility.
- **Candidate design** below is a proposal for later architecture and implementation, not an implemented specification.
- **Test plan** below contains unexecuted acceptance cases. Passing repository checks does not pass any device case.

Wi-Fi mode, SSID, authentication, dashboard address, wake endpoint, listener ports, callback ordering, framing, and session identity must come from [protocol research](OPENCFMOTO_RESEARCH.md) and [the protocol document](EASYCONNECT_PROTOCOL.md). This workstream supplies no guessed addresses, passwords, or ports. The protocol workstream pins `zanderp/open-cfmoto` to [0abbe2a70119d6dd46ac6b8a0715ff267fcdb316](https://github.com/zanderp/open-cfmoto/tree/0abbe2a70119d6dd46ac6b8a0715ff267fcdb316); endpoint claims must be reviewed against that workstream's source citations and later hardware evidence.

The candidate flow accommodates the protocol workstream's phone-hosted TCP callbacks plus an outbound dashboard wake connection. An iPhone acting only as an outbound video client would not cover that transport role. Wire encoding and media pull behavior belong to the protocol specification.

## Apple source facts

### Hotspot configuration and joining

1. `NEHotspotConfigurationManager` manages configurations rather than arbitrary route tables. Creating/updating a configuration requires the user's approval. An app may remove its own configuration, but not one installed by another app or the user. iOS removes app-installed configurations and their keychain entries when the app is uninstalled. [Apple: NEHotspotConfigurationManager](https://developer.apple.com/documentation/networkextension/nehotspotconfigurationmanager)
2. Enable **Hotspot Configuration** in Xcode. The entitlement key is case-sensitive: `com.apple.developer.networking.HotspotConfiguration`, Boolean `true`. Importing NetworkExtension is not equivalent to adding a VPN or provider extension. [Apple: Hotspot Configuration entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.networking.hotspotconfiguration)
3. The SSID/passphrase initializer supports WEP or WPA/WPA2 personal configuration; the SSID-only initializer is for an open network. Select the constructor from researched authentication data, not from the mere presence of an SSID. [Apple: personal-network initializer](https://developer.apple.com/documentation/networkextension/nehotspotconfiguration/init%28ssid%3Apassphrase%3Aiswep%3A%29-3ll1v)
4. `apply(_:completionHandler:)` adds/updates the configuration and attempts association when the network is nearby. A successful completion does **not** prove association. Even association does not prove TCP/IP is ready. Apple recommends a connection API that waits for connectivity. MDM/carrier configurations can prevent or supersede the app's configuration. [Apple: apply](https://developer.apple.com/documentation/networkextension/nehotspotconfigurationmanager/apply%28_%3Acompletionhandler%3A%29)
5. `joinOnce = true` removes the configuration and disconnects when the configuring app stays backgrounded for more than 15 seconds, the device sleeps, the app exits/crashes/is uninstalled, or the device switches Wi-Fi networks. `removeConfiguration(forSSID:)` can explicitly disconnect a join-once configuration. [Apple: joinOnce](https://developer.apple.com/documentation/networkextension/nehotspotconfiguration/joinonce)
6. `joinOnce = false` creates the persistent configuration model, comparable to joining in Settings. Persistence is not a promise of continuous association. [Apple: TN3111, permanently join a network](https://developer.apple.com/documentation/technotes/tn3111-ios-wifi-api-overview)
7. `removeConfiguration(forSSID:)` removes an app-owned profile and has no completion result. Its documented scope does not include restoring an earlier SSID or guaranteeing the replacement Internet route. [Apple: removeConfiguration](https://developer.apple.com/documentation/networkextension/nehotspotconfigurationmanager/removeconfiguration%28forssid%3A%29)
8. `getConfiguredSSIDs` reports configurations; it is not a live association or reachability check. [Apple: getConfiguredSSIDs](https://developer.apple.com/documentation/networkextension/nehotspotconfigurationmanager/getconfiguredssids%28completionhandler%3A%29)

`NEHotspotNetwork.fetchCurrent` can report SSID/BSSID/security. It requires the **Access WiFi Information** entitlement (`com.apple.developer.networking.wifi-info`) plus an eligible condition. Configuring the current network through `NEHotspotConfiguration` is one such condition; precise-location authorization is another. Missing eligibility or entitlement yields `nil`. A `nil` result alone must not be reported as proof that Wi-Fi is off. [Apple: fetchCurrent](https://developer.apple.com/documentation/networkextension/nehotspotnetwork/fetchcurrent%28completionhandler%3A%29)

### Wi-Fi mode compatibility

TN3111 documents no general-purpose iOS Wi-Fi scan/configuration API. Its peer-to-peer options are Wi-Fi Aware (NAN, introduced in iOS 26) and Apple peer-to-peer Wi-Fi; Apple peer-to-peer Wi-Fi only interoperates between Apple devices. Hotspot Helper is for Internet hotspot navigation and has restrictions that exclude accessory integration. [Apple: TN3111](https://developer.apple.com/documentation/technotes/tn3111-ios-wifi-api-overview)

`includePeerToPeer` enables supported peer-to-peer link technologies for a Network operation. This property does not document Android Wi-Fi Direct group creation, discovery, negotiation, or MotoPlay interoperability. [Apple: includePeerToPeer](https://developer.apple.com/documentation/network/nwparameters/includepeertopeer)

**Inference requiring device verification:** an ordinary dashboard SoftAP is a plausible `NEHotspotConfigurationManager` target. A protocol mode labelled P2P must be classified separately. A Wi-Fi Direct group owner might expose an ordinary AP that an iPhone can join with its SSID/security credentials; that possibility is unresolved. Wi-Fi Aware support in iOS does not establish that the existing dashboard implements NAN. Do not silently translate an Android P2P path into SoftAP or claim all P2P-labelled networks are impossible.

### TCP operations and routing scope

`NWParameters.tcp` provides TCP parameters; `NWListener` receives incoming connections. The listener's `newConnectionHandler` supplies an `NWConnection`; install its handlers and call `start(queue:)` to accept it, or `cancel()` to reject it. A listener being ready is different from a peer being connected. [Apple: TCP parameters](https://developer.apple.com/documentation/network/nwparameters/tcp), [Apple: NWListener](https://developer.apple.com/documentation/network/nwlistener), [Apple: newConnectionHandler](https://developer.apple.com/documentation/network/nwlistener/newconnectionhandler)

`NWParameters.requiredInterfaceType = .wifi` requires a Wi-Fi interface for the connection/listener constructed with those parameters. `requiredInterface` is a more specific interface constraint. These are per-operation parameters; neither is a process-wide Android-style network binding nor a system default-route setter. Requiring Wi-Fi also does not choose an SSID. [Apple: requiredInterfaceType](https://developer.apple.com/documentation/network/nwparameters/requiredinterfacetype), [Apple: requiredInterface](https://developer.apple.com/documentation/network/nwparameters/requiredinterface)

Apple DTS describes this as scoped routing: constraints on the operation determine its permitted routes. An ordinary established TCP connection is tied to its local/remote address-and-port tuple; an address change can break it. Another operation's constraints do not change that tuple or route. Consequently, requiring Wi-Fi for dashboard traffic does not direct unrelated app traffic to cellular. [Apple DTS: Network Interface Techniques](https://developer.apple.com/forums/thread/734359)

`acceptLocalOnly` restricts listeners to peers on the local link. `NWConnection.currentPath` exposes the path that a specific connection uses, with path/viability update handlers available for diagnosis. A default `NWPathMonitor` snapshot is not evidence that the dashboard is reachable. [Apple: acceptLocalOnly](https://developer.apple.com/documentation/network/nwparameters/acceptlocalonly), [Apple: NWConnection](https://developer.apple.com/documentation/network/nwconnection)

Connection states distinguish `preparing`, `waiting`, `ready`, `failed`, and `cancelled`. `restart()` applies to a waiting connection; waiting connections automatically retry when their network path changes. It is not a general session-resume primitive. [Apple: NWConnection.State](https://developer.apple.com/documentation/network/nwconnection/state-swift.enum), [Apple: restart](https://developer.apple.com/documentation/network/nwconnection/restart%28%29)

### Local network privacy

Outgoing local TCP requires Local Network privilege; listening/accepting incoming TCP alone does not. Permission is initially undetermined. The first local operation prompts in the foreground; undetermined access attempted in the background is denied without a prompt. There is no general permission-query or explicit permission-request API. For an outgoing `NWConnection`, `.waiting` with `currentPath?.unsatisfiedReason == .localNetworkDenied` identifies denial. Granting permission later automatically retries a waiting connection. The simulator does not implement this privacy behavior. Extensions generally share their container app's privilege; usage keys belong in the containing app. Avoid hard-coded interface names such as `en0`. [Apple: TN3179](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy)

Any local network app should include `NSLocalNetworkUsageDescription`, including direct unicast access. Bonjour service types used by an app belong in `NSBonjourServices`. These keys are distinct from hotspot join consent. [Apple: local-network usage description](https://developer.apple.com/documentation/bundleresources/information-property-list/nslocalnetworkusagedescription), [Apple: Bonjour service types](https://developer.apple.com/documentation/bundleresources/information-property-list/nsbonjourservices)

`com.apple.developer.networking.multicast` is required on iOS for raw IP multicast/broadcast traffic and arbitrary Bonjour service operations; it requires Apple authorization. Direct TCP does not justify adding it. Ordinary declared Bonjour service operations do not by themselves require this entitlement. [Apple: multicast entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.networking.multicast), [Apple: TN3179, multicast operations](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy#Multicast-operations)

### Cellular coexistence limits

Apple DTS warns that an accessory Wi-Fi network can become the default route while providing no Internet, causing Internet connections to fail. Whether the network supplies usable addressing/router information and how iOS evaluates it matter. Networks that do not become the default route can have auto-join/sleep limitations. These are accessory/network conditions, not guarantees exposed by `apply`. [Apple DTS: Working with a Wi-Fi Accessory](https://developer.apple.com/forums/thread/734344)

The iOS Wi-Fi lifecycle post explicitly describes its model as conceptual, with undocumented details and uncertainties. Treat it as explanatory guidance rather than a normative timing contract for iOS 27. Record actual dashboard behavior. [Apple DTS: The iOS Wi-Fi Lifecycle](https://developer.apple.com/forums/thread/734361)

Multipath TCP is an opt-in connection feature and is not automatic fallback for every app/API. It also needs peer support. It cannot establish that Waze or Maps will use cellular while OpenCFMoto has joined the dashboard network. [Apple DTS: multipath and accessory Wi-Fi](https://developer.apple.com/forums/thread/795547), [Apple DTS: Network Interface Techniques](https://developer.apple.com/forums/thread/734359)

## Candidate design for later architecture

### Configuration, consent, and transport startup

1. Parse sanitized pairing input and explicitly classify the network mode. Reject incomplete/unsupported modes with an actionable state. Do not invent fallback SSIDs, endpoints, authentication, or Bonjour services.
2. On an explicit foreground **Connect** action, explain why joining the bike network is needed and apply an exact-SSID configuration with the matching authentication model. Permit one outstanding apply operation. Track an attempt identifier so a late completion cannot restart a stopped/replaced session.
3. For the navigation-app use case, propose `joinOnce = false`; `true` has the documented background-removal conflict. Explain that the bike profile persists and offer a separate **Disconnect and forget bike network** operation. A stop-stream operation and a forget-profile operation have different effects.
4. Track configuration applied, association evidence, listeners ready, accepted channel ready, and protocol negotiated separately. Do not advance to projection readiness from a nil apply error or a satisfied Wi-Fi monitor.
5. If exact SSID verification is needed, add Access WiFi Information and use `fetchCurrent` for app-configured Wi-Fi. Do not add location prompts solely to work around a missing entitlement. Manual Settings joining may have different eligibility; report unavailable SSID information separately from socket reachability.
6. Prepare phone-side listeners at the protocol-defined callback ports, using independent TCP parameters constrained to `.wifi`. Evaluate `acceptLocalOnly = true` against the researched topology. Leave Bonjour advertisement unset unless the actual protocol requires it. Bound channel counts and reject unexpected peers/channels after checking available peer/session information; SSID matching alone is not authentication.
7. Once the required listeners are ready, initiate the separately scoped outbound wake connection to the protocol-defined dashboard endpoint. This actual local operation can prompt for Local Network access. Keep first setup in the foreground until consent and handshake have completed.
8. Start accepted connections, inspect their actual paths, and drive negotiation using protocol-defined ordering. Candidate listeners and outbound wake are all Wi-Fi scoped; accepted TCP streams remain on their established local path. Inspect and reject an unexpected path rather than assuming a cellular fallback would reach the bike.

Use a single transport/session owner with serialized state transitions. The eventual network owner must coexist with the capture lifetime described in [IOS_PLATFORM.md](IOS_PLATFORM.md), including its iOS 27 ScreenCaptureKit and background-mode findings. Hotspot persistence and a live TCP socket do not themselves grant execution time. Background listeners, heartbeat delivery, reconnects, and video sending must be measured during the actual approved capture session.

### Capability proposal

| Setting/capability | Proposed use | Evidence/condition |
|---|---|---|
| Hotspot Configuration | Required for automatic joining | App entitlement key with capital `HotspotConfiguration`; signing profile must authorize it |
| `NSLocalNetworkUsageDescription` | Required for local traffic | Suggested purpose text: "Connect to your motorcycle display over Wi-Fi to send screen projection and session commands." |
| Access WiFi Information | Conditional | Add if association/SSID diagnostics use `fetchCurrent`; separate from join capability |
| `NSBonjourServices` | Not currently justified | Add only the exact service types required by verified discovery/advertisement |
| Multicast entitlement | Not currently justified | Reevaluate only if verified protocol uses raw broadcast/multicast or arbitrary Bonjour operations |
| VPN/provider or Hotspot Helper entitlement | Not justified for this flow | Ordinary hotspot configuration plus Network TCP does not require a provider extension |
| Capture background mode | Owned by capture research/implementation | Does not substitute for device verification of background transport |

This research does not add entitlements or Info.plist keys to the skeleton. Later implementation must verify the built app's effective properties and signed entitlements on the exact tested revision.

### Error and recovery proposal

Hotspot error names below come from [Apple's error enumeration](https://developer.apple.com/documentation/networkextension/nehotspotconfigurationerror). Recovery actions are project proposals. Compare typed/domain-qualified errors, not localized text or unexplained raw integers.

| Observation | Proposed response |
|---|---|
| `userDenied` | End the join attempt; present a user-initiated retry or manual Settings path; do not repeatedly prompt |
| `alreadyAssociated` | Continue association/endpoint validation; do not infer the projection session is healthy |
| Invalid SSID/passphrase/configuration cases | Return to pairing correction; do not retry the same invalid values |
| `applicationIsNotInForeground` | Wait for foreground and a user action before another consent operation |
| `pending` | Avoid overlapping applies; retain one attempt owner and resolve/expire the earlier attempt coherently |
| `joinOnceNotSupported` | Treat as a configuration-model mismatch; do not silently change security or retry forever |
| Internal/system/unknown errors, `systemDenied`, `userUnauthorized`, or future cases | Record sanitized error domain/code and attempt stage; show failure; use a bounded user-initiated retry after diagnosis |
| Outgoing connection waiting with `localNetworkDenied` | Surface permission guidance for Settings > Privacy & Security > Local Network; distinguish it from wrong credentials or dashboard absence |
| Listener failure/port conflict, peer timeout, disconnect, EOF, or protocol rejection | Tear down the affected session coherently; classify the stage; reconnect with a fresh handshake within a bounded policy |

Set separate measured deadlines for association, listener preparation, callback arrival, handshake, and liveness. Allow time for a pending consent decision; do not misclassify a user still answering the alert as a dash failure. Deadline values and retry budgets remain architecture decisions, informed by device measurements and simulator faults.

An existing waiting connection may be retained for path/permission recovery within its attempt budget. Recreate failed/cancelled connections and invalidated sessions; do not call `restart()` as a substitute for reinitialization. Reset parser, heartbeat, media requests, and queued frame ownership on a new protocol session. Suppress stale callbacks by attempt/session generation and give Stop priority over retries.

Do not automatically reapply a hotspot profile for every dropped socket. First distinguish consent denial, Wi-Fi loss, an address change, listener failure, and dashboard session failure. User-selected network changes must not trigger an endless rejoin/prompt loop.

Cancel connections/listeners before deliberate profile removal. Remove only the stored exact app-owned profile selected by the user; do not promise restoration of the previous Wi-Fi network. Because the removal API has no completion result, observe subsequent state and provide Settings guidance if needed. Cleanup on a crash cannot be assumed to run; persistent-profile behavior must be documented and tested.

### Internet connectivity and diagnostics proposal

Keep bike operations Wi-Fi scoped. Leave unrelated Internet operations under system policy unless there is a separately justified per-operation constraint. Requiring `.cellular` on an OpenCFMoto connection, if later needed, controls only that connection; it does not change Waze/Maps traffic. Do not add a VPN or multipath dependency as an inferred cure for the bike's routing behavior.

REQ-NET-003 remains conditional physical acceptance: simultaneous bike traffic and fresh online navigation requests must succeed on the tested iPhone, OS, dashboard firmware, cellular service, and settings. Cellular data disabled, unavailable coverage, roaming restrictions, per-app data settings, or an unsuitable dashboard default route can invalidate the test. Wi-Fi scope protects transport selection; it does not establish Internet availability.

Log attempt/session IDs, stage transitions, duration, listener/connection states, typed errors, selected interface type, path unsatisfied reason, timeout/reconnect counts, queue depth, and send/receive rates. Keep SSID/BSSID and endpoint details private by default; use sanitized topology data in exported evidence. Never log passphrases, QR payloads containing credentials, screen data, navigation destinations, or tokens. A successful send callback is not proof that the TFT displayed a frame.

## Physical-device and simulator verification plan

All cases below are **NOT RUN**. Use a development-signed physical iPhone on the brief's iOS 27+ target for radio, consent, routing, and background tests. Start with a controlled ordinary AP and an independently implemented dashboard simulator, then repeat relevant cases with the parked 450NK. Physical evidence must identify exact app SHA, Xcode/SDK, iPhone/OS build, bike model/region, TFT firmware, pairing mode, cellular settings/carrier availability, timestamps, and sanitized results.

| Test ID | Requirements | Procedure and acceptance evidence |
|---|---|---|
| TEST-NET-001 | REQ-NET-001 | Fresh install, foreground Connect, accept hotspot prompt. Record configuration result, association evidence, and real Wi-Fi socket/handshake success separately. Repeat while already on bike Wi-Fi. |
| TEST-NET-002 | REQ-NET-001, REQ-REC-001 | Deny join; use invalid input; keep AP absent; move app to background during the attempt. Each reaches a distinct bounded state without crash, repeated consent prompts, or false readiness. |
| TEST-NET-003 | REQ-NET-002 | Prepare every researched listener, send wake, accept callbacks, and complete handshake with the independent simulator. Check actual Wi-Fi paths; inject occupied port, missing callback, extra peer, and wrong channel. No unsolicited media assumption. |
| TEST-NET-004 | REQ-NET-002 | Fresh install on physical iPhone: trigger actual outbound local wake, deny/allow Local Network, revoke while connected, grant in Settings, then retry. Assert typed denial handling and distinction from association failure. Never use simulator consent as evidence. |
| TEST-NET-005 | REQ-NET-002, REQ-CAP-002 | In a controlled probe, compare join-once/persistent configuration; switch to a navigation app beyond 15 seconds and then 30 minutes. Use actual capture/background mode for the persistent case. Measure listener, heartbeat, and video continuity. Test screen lock separately; report unsupported behavior explicitly. |
| TEST-NET-006 | REQ-NET-003 | With bike connected and streaming, start fresh online route/search/map requests in Waze and Apple Maps; cached tiles are insufficient. Exercise cellular on/off, coverage interruption, and normal settings. Record online results and concurrent Wi-Fi transport; verify map/provider endpoints through sanitized evidence where feasible. |
| TEST-NET-007 | REQ-REC-001 | Cycle dashboard/AP power, toggle Wi-Fi in Settings, deliberately join another network, change DHCP lease/address on the test AP, and restore access. Confirm bounded recovery, fresh handshake, stale-frame disposal, and immediate cancellation by Stop. |
| TEST-NET-008 | REQ-NET-001, REQ-REC-001 | Stop stream versus disconnect/forget; relaunch after crash/force quit; uninstall/reinstall; test a manually joined network. Verify app-owned removal behavior and no promise of automatic previous-network restoration. |
| TEST-NET-009 | REQ-NET-001, REQ-NET-002 | Test real SoftAP and P2P-labelled QR configurations independently. Determine whether the dashboard group-owner AP permits ordinary iPhone association, or requires unsupported negotiation. Record protocol/firmware-specific compatibility. |
| TEST-NET-010 | REQ-LOG-002 | Export diagnostics for all failure paths; confirm credentials, screen bytes, raw sensitive QR fields, and destinations are absent. |

The iOS Simulator can later exercise TCP parsing, callback roles, state changes, and fault injection over its host environment. Use an explicit simulator transport mode/test double for hotspot configuration; host loopback or Ethernet paths may not satisfy a production Wi-Fi constraint. Keep that policy isolated from the physical-device transport. The simulator cannot validate Local Network prompts, iPhone radio association, cellular coexistence, or iPhone sleep/background lifetimes. A successful local simulation is not a verified bike connection.

## This branch's verification record and handoff

Research read the live primary Apple pages on 2026-10-04, including their Apple-provided `.md` representations when JavaScript-only pages prevented direct extraction. TN3179 lists its latest revision as 2026-02-17; TN3111 lists 2025-08-29. Apple DTS posts above are first-party engineering guidance with the stated caveats, not a substitute for SDK checks or hardware results.

Portable checks executed on the final research content on 2026-10-04:

```text
python Tools/verify_repository.py
python -m unittest discover -s Tests -p 'test_*.py' -v
git diff --check
```

Results: repository verification **PASS**; all **8** foundation tests **PASS**; diff whitespace check **PASS**. Self-review covered the source/design/test separation, exact entitlement casing, transport direction, cleanup scope, and cellular/P2P limitations; no blocking self-review finding remains. This is not independent review. The committed SHA is supplied at handoff for the coordinator's exact-revision verification.

Native Xcode compilation/signing and all TEST-NET cases remain unverified on this Windows research host. The coordinator records exact research/review/merge SHAs and results in shared task/status records. Independent review must check entitlement key casing, apply-versus-association distinction, persistent configuration lifetime, phone-hosted listener role, Local Network consent, scoped routing limits, and the unresolved P2P/SoftAP boundary before the research gate advances.

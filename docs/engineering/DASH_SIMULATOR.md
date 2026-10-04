# Dash Simulator specification

MVP-007 candidate specification, 2026-10-04; independent review pending. REQ-TEST-001. Implement in Python's standard library from the reviewed wire specification, without importing fixture generators, research-test parsers or Swift code.

The dashboard listens for phone wake (default 10930). After a parsed acceptable wake, it initiates two phone PXC connections (10922), one media-control connection (10921) and one media-data connection (10920). Allow explicit host/port overrides so tests can use loopback and isolated ports. Default development binding is loopback; LAN binding requires explicit configuration. The Swift host peer prepares listeners before wake. This corrects the generic earlier notion of a receiver merely waiting for unsolicited video.

Gate 1 validates CAR_CTRL/CAR_DATA acknowledgement, CLIENT_INFO shape under an explicitly synthetic profile, QUERY_SPEED, CHECK_SN acknowledgement/result, media version/capture/extend/start and PXC/media heartbeats. Configurable small writes split headers/bodies; some requests coalesce. It checks received commands, payloads and reply token zero independently. Synthetic identity acceptance is deliberate and does not validate RSA or target personality. Missing/invalid responses fail with a bounded socket deadline; all sockets close on exit.

The host verifier covers 14 cases: one-byte and coalesced success, delayed wake acceptance after PXC selection, rejected wake, malformed XOR, oversized/truncated PXC, unsupported command, duplicate PXC/media callbacks, missing CAR_DATA, early DATA_START/DATA_NEXT and disconnect. Negative cases require closure without an invented acknowledgement and a specific probe failure reason. Queue stalls/overflow are deterministic Swift core tests; the socket suite does not claim to force Network.framework backpressure.

Gate 2 adds DATA_START/DATA_NEXT pulls, bounded raw access-unit recording, optional decoder inspection, packet/frame counters and deliberate disconnect/delay faults. Output recording stays in ignored paths and requires explicit opt-in. Do not save real screen contents by default. Gate 1 can test DATA_START and empty pulls without pretending that the invented framing fixture is decodable video.

CLI exit success means only the selected synthetic case passed. Summaries report channel/message counts and test mode, without identity/credential/raw payload logging. Test the simulator's own malformed-length/XOR/EOF checks and socket cleanup in addition to cross-language integration.

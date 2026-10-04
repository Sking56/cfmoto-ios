# Security and privacy

The foundation launches a static view and performs no capture, network access, credential collection, telemetry or export. Future pairing credentials stay out of logs, fixtures and Git. Capture requires explicit system consent and must stop cleanly when revoked. Future diagnostics include operational counters only; no screen contents, navigation destination, passwords or tokens.

Planned controls: bounded packet sizes/queues, expected Wi-Fi peer validation, private OSLog fields, explicit user-controlled export and no screen recording by default. Threats include a spoofed local dash and hostile oversized packets. These controls are requirements, not implemented assurances.

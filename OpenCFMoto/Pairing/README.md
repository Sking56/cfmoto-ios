# Pairing

`PairingConfiguration.swift` parses classic URL QR data in memory, normalizes keys, applies reviewed form decoding/duplicate semantics, validates required fields and redacts printable descriptions. No URL is fetched. Password whitespace is preserved.

The parser does not scan with a camera, select a Wi-Fi mode, validate hardware compatibility, configure a hotspot or persist credentials. Those remain separate integration work. Host tests consume the invented QR fixtures and malformed/UTF-8 cases.

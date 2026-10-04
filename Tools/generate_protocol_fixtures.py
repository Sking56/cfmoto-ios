"""Generate invented research vectors. No network, secrets, encoder or client implementation."""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "Tests" / "Fixtures"
REVISION = "0abbe2a70119d6dd46ac6b8a0715ff267fcdb316"
UPSTREAM = "https://github.com/zanderp/open-cfmoto"
# SHA-256 of canonical git-show blob bytes, not a CRLF-transformed Windows checkout.
SOURCE_BLOBS = {
    "S1": ("app/src/main/java/dev/zanderp/opencfmoto/QrData.kt", "28d58b68cff72261ec177cc54a1c4bc2a7320a665db0896d3b35c5040d678729"),
    "S2": ("app/src/main/java/dev/zanderp/opencfmoto/EasyConnDiscovery.kt", "c535aef7c0ce50da0238015b4a7024199ea3381c95346b1cd2ae68fd8e56c187"),
    "S3": ("app/src/main/java/dev/zanderp/opencfmoto/EasyConnProber.kt", "4170c418ce354d8e95d94fe0d69a9b8cafdb4b4bcdc03aba671548f1cd095229"),
    "S4": ("app/src/main/java/dev/zanderp/opencfmoto/PxcFrame.kt", "d7c7a7c17ef0518c947fa70a30a12be1b226003d9e5b9c3e36acaedf5679b462"),
    "S5": ("app/src/main/java/dev/zanderp/opencfmoto/PxcHandshake.kt", "74ba276ab3d7cf561e51945d99c5bb0f26e0ff0d5a89c017b35c629ae1501b95"),
    "S6": ("app/src/main/java/dev/zanderp/opencfmoto/BikeProfile.kt", "295b2b201410945a12ad450286add2e928a61d033d0bb7d4d082a4d7db5cefe4"),
    "S7": ("app/src/main/java/dev/zanderp/opencfmoto/RsaKeys.kt", "ba90e38e0b396df0372192759b5687643a8e64de24fda6421e45c8ee5eb1eba0"),
    "S8": ("app/src/main/java/dev/zanderp/opencfmoto/VideoPipeline.kt", "67dff5b6fd4870c568dfd24419aef4528c45b6eed94e9e796fc008aaa70b4036"),
    "S9": ("app/src/main/java/dev/zanderp/opencfmoto/AndroidAutoService.kt", "96a52070b18e70b366881ac0c1c2828d1df7004f4d145a7a0f3d749166b1a845"),
    "S10": ("docs/01-REVERSE-ENGINEERING.md", "bb81fd25e653bd9255ad9860676696424898a313952f991ff4ec0eb7a7dbeacc"),
    "S11": ("docs/05-DEBUG-KNOWLEDGE.md", "5beefee1c77a1c63a7385a9a1f6cb6c9f8e1b9d6d7cd52fcda0f435d10e7c077"),
    "S12": ("docs/SUPPORTED-BIKES.md", "ce0aea3f1941bc56fc64bd3cf63943aa4d867190eb7fef11a0a06e33ec44a9b5"),
}


def json_bytes(value):
    return (json.dumps(value, indent=2, ensure_ascii=True) + "\n").encode("utf-8")


def pxc(command, body=b""):
    total = 16 + len(body)
    return struct.pack("<IIII", command, total, command ^ total, 0) + body


def media(command, body=b"", token=0):
    return struct.pack("<hHi", command, len(body), token) + body


def generated_files():
    files, entries = {}, []

    def add(path, data, wire, command, direction, role, sources, **expected):
        files[path] = data
        entries.append({"path": path, "sha256": hashlib.sha256(data).hexdigest(),
                        "byte_count": len(data), "wire": wire, "command": command,
                        "direction": direction, "role": role, "sources": sources,
                        "origin": "invented-synthetic", "expected": expected})

    # Compact JSON bytes are intentional, with synthetic identity/serial values throughout.
    wake = b'{"phoneType":"Android","packageName":"com.cfmoto.cfmotointernational"}'
    add("handshake/wake-request.bin", pxc(0x70000010, wake), "pxc", 0x70000010,
        "phone-to-dash", "wake", ["S3", "S4"], body_text=wake.decode())
    for name, status in [("accepted", "true"), ("rejected", "false")]:
        body = ('{"status":' + status + '}').encode()
        add(f"handshake/wake-{name}.bin", pxc(0x70000011, body), "pxc", 0x70000011,
            "dash-to-phone", "wake", ["S3", "S4"], body_text=body.decode())
    for label, command in [("car-ctrl", 0x10000), ("car-data", 0x20000)]:
        for suffix, offset, direction in [("select", 0, "dash-to-phone"), ("ack", 1, "phone-to-dash")]:
            add(f"handshake/{label}-{suffix}.bin", pxc(command + offset), "pxc", command + offset,
                direction, "pxc-control", ["S4", "S5"], body_hex="")
    info = b'{"HUID":"SYNTHETIC-HU-0001","HUName":"Synthetic fixture","sdkVersion":"0.9.29.1","channel":"fixture-not-hardware"}'
    add("capabilities/client-info-request.bin", pxc(0x10010, info), "pxc", 0x10010,
        "dash-to-phone", "pxc-control", ["S5", "S6"], body_text=info.decode(),
        note="Shape only; invented identity and no authenticated reply")
    for name, command, body, direction in [
        ("check-sn-request", 0x103e0, b'{"client_set":"easy_conn","sn":"SYNTHETIC-SN-0001"}', "dash-to-phone"),
        ("check-sn-ack", 0x103e1, b"", "phone-to-dash"),
        ("check-sn-result", 0x201c0, b'{"isOk":true,"errCode":0,"errMsg":"","id":"SYNTHETIC-SN-0001","client_set":"easy_conn"}', "phone-to-dash"),
    ]:
        add(f"handshake/{name}.bin", pxc(command, body), "pxc", command, direction,
            "pxc-control", ["S5"], body_text=body.decode())
    for name, command, wire, encode in [
        ("pxc-request", 0x70000000, "pxc", pxc), ("pxc-ack", 0x70000001, "pxc", pxc),
        ("media-request", 64, "media", media), ("media-ack", 65, "media", media),
    ]:
        add(f"heartbeat/{name}.bin", encode(command), wire, command, "either-peer" if wire == "pxc" else
            ("dash-to-phone" if command == 64 else "phone-to-dash"),
            "pxc-control" if wire == "pxc" else "media-control", ["S3", "S5"], body_hex="")
    config = bytearray(32)
    struct.pack_into("<HHiiiHHi", config, 0, 800, 386, 30, 2, 2, 0, 100, 2_500_000)
    config[29] = 1
    add("capabilities/config-capture-request.bin", media(16, config), "media", 16, "dash-to-phone",
        "media-control", ["S3", "S10"], body_hex=bytes(config).hex(), width=800, height=386,
        fps=30, encoder=2, extension=1, note="Other reported fields invented; not a measured 450NK configuration")
    reply = struct.pack("<iHHB", 2, 800, 384, 1)
    add("capabilities/config-capture-reply.bin", media(17, reply), "media", 17, "phone-to-dash",
        "media-control", ["S3", "S6"], body_hex=reply.hex(), width=800, height=384, encoder=2, extension=1)
    for name, command, body, direction in [
        ("version-request", 48, b"", "dash-to-phone"),
        ("version-reply", 49, struct.pack("<ii", 3, 1), "phone-to-dash"),
        ("extend-request", 96, b'{"fixture":true}', "dash-to-phone"),
        ("extend-reply", 97, b'{"state":0}', "phone-to-dash"),
        ("start-h264-request", 128, b"", "dash-to-phone"),
        ("start-h264-reply", 129, b"", "phone-to-dash"),
    ]:
        add(f"capabilities/{name}.bin", media(command, body), "media", command, direction,
            "media-control", ["S3"], body_hex=body.hex())
    for name, command, direction in [("data-start", 112, "dash-to-phone"),
                                     ("data-start-ack", 113, "phone-to-dash"),
                                     ("data-next", 114, "dash-to-phone")]:
        add(f"video/{name}.bin", media(command), "media", command, direction, "media-data", ["S3"], body_hex="")
    # NAL type bytes 7,8,5; bodies are invented ASCII, NOT valid H.264 RBSP.
    markers = bytes.fromhex("0000000167") + b"SYNTHETIC-SPS" + bytes.fromhex("0000000168") + b"SYNTHETIC-PPS" + bytes.fromhex("0000000165") + b"SYNTHETIC-IDR"
    add("video/framing-only.bin", struct.pack("<I", len(markers)) + markers, "raw-video", None,
        "phone-to-dash", "media-data", ["S3", "S8", "S10"], body_hex=markers.hex(),
        nal_types=[7, 8, 5], decodable_h264=False, note="Framing-only, non-decodable invented bodies; never a hardware test frame")
    for name, data, reason in [
        ("pxc-bad-xor", struct.pack("<IIII", 0x10000, 16, 0, 0), "bad-xor"),
        ("pxc-small-total", struct.pack("<IIII", 0x10000, 8, 0x10008, 0), "undersized-total"),
        ("pxc-huge-total", struct.pack("<IIII", 0x10000, 0x20000000, 0x20010000, 0), "size-guard"),
        ("pxc-truncated-body", pxc(0x10010, b"{}")[0:17], "incomplete"),
    ]:
        add(f"malformed/{name}.bin", data, "pxc", 0x10000 if name != "pxc-truncated-body" else 0x10010,
            "test-only", "pxc-control", ["S4"], rejection=reason,
            note="Defensive negative vector, not upstream-emitted traffic")
    add("malformed/media-truncated-body.bin", media(17, reply)[:-1], "media", 17, "test-only",
        "media-control", ["S3"], rejection="incomplete")
    add("malformed/raw-video-truncated.bin", (struct.pack("<I", len(markers)) + markers)[:-1],
        "raw-video", None, "test-only", "media-data", ["S3"], rejection="incomplete")
    qr_cases = [
        {"id": "classic", "raw": "https://pairing.example.invalid/?modelid=SYNTHETIC&sn=SYNTHETIC-NONCE&action=9&ssid=CFMOTO-TEST-000001&pwd=fixture-only-0001&auth=wpa2-psk&mac=02:00:00:00:00:01&name=Synthetic%20Bike",
         "expected": {"ssid": "CFMOTO-TEST-000001", "pwd": "fixture-only-0001", "action": "9", "name": "Synthetic Bike"}},
        {"id": "percent-plus-and-password-spaces", "raw": "https://pairing.example.invalid/?SSID=CFMOTO%2BTEST&pwd=fixture+only%2B0002&action=1",
         "expected": {"ssid": "CFMOTO+TEST", "pwd": "fixture only+0002", "action": "1"}},
        {"id": "duplicate-and-fragment", "raw": "https://pairing.example.invalid/?ssid=discarded&ssid=CFMOTO-TEST-000003&pwd=fixture-only-0003&action=1#pwd=ignored",
         "expected": {"ssid": "CFMOTO-TEST-000003", "pwd": "fixture-only-0003", "action": "1"}},
    ]
    files["qr/classic-cases.json"] = json_bytes({"origin": "invented-synthetic", "source": "S1", "cases": qr_cases})
    files["protocol-manifest.json"] = json_bytes({"schema_version": 1, "upstream_revision": REVISION,
        "origin": "invented-synthetic", "qr_file": "qr/classic-cases.json", "fixtures": entries})
    sources = {key: {"path": path, "sha256_git_blob": digest,
                       "url": f"{UPSTREAM}/blob/{REVISION}/{path}"}
               for key, (path, digest) in SOURCE_BLOBS.items()}
    files["protocol-provenance.json"] = json_bytes({"schema_version": 1, "upstream_repository": UPSTREAM,
        "upstream_revision": REVISION, "research_date": "2026-10-04", "sources": sources,
        "generator": "Tools/generate_protocol_fixtures.py", "method": "Independently constructed synthetic structural vectors from documented wire fields; no source implementation or captures copied",
        "sanitization": "All SSID/password/MAC/HUID/serial values invented; no private keys, tokens, screen contents or genuine identifiers",
        "limits": ["No authenticated CLIENT_INFO response", "Video markers are not decodable H.264",
                   "No target hardware or iPhone verification", "Negative vectors impose research guards, not measured firmware maxima"]})
    return files


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Check deterministic outputs without writing")
    parser.add_argument("--verify-upstream", type=Path, help="Optionally verify canonical source blobs in a local Git clone")
    args = parser.parse_args()
    if args.verify_upstream:
        for path, digest in SOURCE_BLOBS.values():
            blob = subprocess.check_output(["git", "-C", str(args.verify_upstream), "show", f"{REVISION}:{path}"])
            if hashlib.sha256(blob).hexdigest() != digest:
                raise SystemExit(f"FAIL: upstream blob mismatch: {path}")
    outputs = generated_files()
    for name, data in outputs.items():
        path = FIXTURES / name
        if args.check:
            if not path.is_file() or path.read_bytes() != data:
                raise SystemExit(f"FAIL: generated fixture differs: {name}")
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
    print(f"PASS: {len(outputs)} deterministic synthetic research artifacts {'checked' if args.check else 'generated'}")


if __name__ == "__main__":
    main()

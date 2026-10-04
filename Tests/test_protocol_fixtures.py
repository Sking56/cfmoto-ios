"""Independent synthetic artifact checks; no production transport implementation."""
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
import sys
import unittest
from urllib.parse import unquote_plus

ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "Tests/Fixtures"
REVISION = "0abbe2a70119d6dd46ac6b8a0715ff267fcdb316"


class IncompleteFrame(ValueError):
    pass


def decode_one(wire, data):
    """Research-only bounded inspector; retain bytes following the first frame."""
    header = {"pxc": 16, "media": 8, "raw-video": 4}[wire]
    if len(data) < header:
        raise IncompleteFrame("incomplete")
    if wire == "pxc":
        command, total, check, _reserved = struct.unpack_from("<IIII", data)
        if command ^ total != check:
            raise ValueError("bad-xor")
        if total < 16:
            raise ValueError("undersized-total")
        if total > 1024 * 1024:
            raise ValueError("size-guard")
    elif wire == "media":
        command, length, _token = struct.unpack_from("<hHi", data)
        total = 8 + length
    else:
        command = None
        length, = struct.unpack_from("<I", data)
        if length > 1024 * 1024:
            raise ValueError("size-guard")
        total = 4 + length
    if len(data) < total:
        raise IncompleteFrame("incomplete")
    return command, data[header:total], total


class ProtocolFixtureTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads((FIXTURES / "protocol-manifest.json").read_text(encoding="utf-8"))
        cls.entries = cls.manifest["fixtures"]

    def read(self, path):
        return (FIXTURES / path).read_bytes()

    def test_provenance_inventory_and_hashes(self):
        provenance = json.loads(self.read("protocol-provenance.json"))
        self.assertEqual(provenance["upstream_revision"], REVISION)
        self.assertEqual(self.manifest["upstream_revision"], REVISION)
        self.assertEqual(set(provenance["sources"]), {f"S{i}" for i in range(1, 13)})
        for source in provenance["sources"].values():
            self.assertRegex(source["sha256_git_blob"], r"^[a-f0-9]{64}$")
            self.assertEqual(source["url"], f'https://github.com/zanderp/open-cfmoto/blob/{REVISION}/{source["path"]}')
        listed = [entry["path"] for entry in self.entries]
        self.assertEqual(len(listed), len(set(listed)))
        self.assertEqual(set(listed), {p.relative_to(FIXTURES).as_posix() for p in FIXTURES.rglob("*.bin")})
        for entry in self.entries:
            with self.subTest(path=entry["path"]):
                data = self.read(entry["path"])
                self.assertEqual(entry["origin"], "invented-synthetic")
                self.assertTrue(entry["sources"])
                self.assertTrue(set(entry["sources"]) <= set(provenance["sources"]))
                self.assertEqual(entry["byte_count"], len(data))
                self.assertEqual(entry["sha256"], hashlib.sha256(data).hexdigest())

    def test_offline_regeneration_matches(self):
        result = subprocess.run([sys.executable, str(ROOT / "Tools/generate_protocol_fixtures.py"), "--check"],
                                cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_decoded_command_payload_and_negative_vectors(self):
        for entry in self.entries:
            with self.subTest(path=entry["path"]):
                expected = entry["expected"]
                if "rejection" in expected:
                    with self.assertRaisesRegex(ValueError, f'^{expected["rejection"]}$'):
                        decode_one(entry["wire"], self.read(entry["path"]))
                    continue
                command, body, consumed = decode_one(entry["wire"], self.read(entry["path"]))
                self.assertEqual(command, entry["command"])
                self.assertEqual(consumed, entry["byte_count"])
                if "body_text" in expected:
                    self.assertEqual(body.decode("utf-8"), expected["body_text"])
                    if body:
                        self.assertIsInstance(json.loads(body), dict)
                else:
                    self.assertEqual(body.hex(), expected["body_hex"])

    def test_literal_goldens_and_length_semantics(self):
        goldens = {
            "handshake/car-ctrl-select.bin": "00000100100000001000010000000000",
            "handshake/car-ctrl-ack.bin": "01000100100000001100010000000000",
            "heartbeat/pxc-request.bin": "00000070100000001000007000000000",
            "heartbeat/media-request.bin": "4000000000000000",
            "capabilities/config-capture-reply.bin": "1100090000000000020000002003800101",
        }
        for path, hex_data in goldens.items():
            self.assertEqual(self.read(path).hex(), hex_data)
        control = self.read("handshake/wake-request.bin")
        self.assertEqual(int.from_bytes(control[4:8], "little"), len(control))
        media = self.read("capabilities/version-reply.bin")
        self.assertEqual(int.from_bytes(media[2:4], "little"), len(media) - 8)

    def test_capture_offsets_rounding_and_version(self):
        _, request, _ = decode_one("media", self.read("capabilities/config-capture-request.bin"))
        _, reply, _ = decode_one("media", self.read("capabilities/config-capture-reply.bin"))
        self.assertEqual(struct.unpack_from("<HHii", request), (800, 386, 30, 2))
        self.assertEqual(request[29], 1)
        self.assertEqual(struct.unpack("<iHHB", reply), (2, 800 & 0xFFF0, 386 & 0xFFF0, 1))
        _, body, _ = decode_one("media", self.read("capabilities/version-reply.bin"))
        self.assertEqual(struct.unpack("<ii", body), (3, 1))

    def test_sn_result_and_wake_boolean(self):
        _, request, _ = decode_one("pxc", self.read("handshake/check-sn-request.bin"))
        _, result, _ = decode_one("pxc", self.read("handshake/check-sn-result.bin"))
        self.assertEqual(json.loads(result), {"isOk": True, "errCode": 0, "errMsg": "",
                                             "id": json.loads(request)["sn"], "client_set": "easy_conn"})
        for suffix, accepted in [("accepted", True), ("rejected", False)]:
            _, body, _ = decode_one("pxc", self.read(f"handshake/wake-{suffix}.bin"))
            self.assertIs(json.loads(body)["status"], accepted)

    def test_video_structural_markers_are_not_claimed_decodable(self):
        entry = next(e for e in self.entries if e["path"] == "video/framing-only.bin")
        self.assertIs(entry["expected"]["decodable_h264"], False)
        _, body, used = decode_one("raw-video", self.read(entry["path"]))
        self.assertEqual(used, 4 + len(body))
        nals = re.split(b"\x00\x00\x00\x01", body)[1:]
        self.assertEqual([nal[0] & 31 for nal in nals], [7, 8, 5])
        self.assertTrue(all(b"SYNTHETIC" in nal for nal in nals))

    def test_all_split_points_and_coalesced_messages(self):
        for entry in self.entries:
            if "rejection" in entry["expected"]:
                continue
            data = self.read(entry["path"])
            for split in range(len(data)):
                with self.subTest(path=entry["path"], split=split):
                    with self.assertRaises(IncompleteFrame):
                        decode_one(entry["wire"], data[:split])
                    self.assertEqual(decode_one(entry["wire"], data[:split] + data[split:])[2], len(data))
            _, _, consumed = decode_one(entry["wire"], data + data)
            self.assertEqual(consumed, len(data))
            self.assertEqual(decode_one(entry["wire"], (data + data)[consumed:])[2], len(data))

    def test_qr_decoding_duplicate_keys_fragment_and_invented_values(self):
        cases = json.loads(self.read(self.manifest["qr_file"]))
        self.assertEqual(cases["origin"], "invented-synthetic")
        for case in cases["cases"]:
            query = case["raw"].split("?", 1)[1].split("#", 1)[0]
            parsed = {}
            for part in query.split("&"):
                key, _, value = part.partition("=")
                parsed[key.lower()] = unquote_plus(value)
            self.assertTrue(case["raw"].startswith("https://pairing.example.invalid/"))
            for key, value in case["expected"].items():
                self.assertEqual(parsed[key], value)
            self.assertTrue(parsed["pwd"].startswith("fixture"))


if __name__ == "__main__":
    unittest.main()

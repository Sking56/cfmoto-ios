"""Independent peer checks; Swift socket integration is Tools/verify_gate1.py."""
import importlib.util
from pathlib import Path
import socket
import struct
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("dash_simulator", ROOT / "Tools/DashSimulator/dash_simulator.py")
dash = importlib.util.module_from_spec(spec)
spec.loader.exec_module(dash)


class DashSimulatorTests(unittest.TestCase):
    def pair(self):
        sender, receiver = socket.socketpair()
        self.addCleanup(sender.close)
        self.addCleanup(receiver.close)
        receiver.settimeout(1)
        return sender, receiver

    def test_independent_literal_goldens_and_reserved_token_preservation(self):
        self.assertEqual(dash.pxc(0x10000).hex(), "00000100100000001000010000000000")
        self.assertEqual(dash.media(64).hex(), "4000000000000000")
        sender, receiver = self.pair()
        sender.sendall(dash.pxc(0x87654321, b"unknown", reserved=9))
        self.assertEqual(dash.read_pxc(receiver), (0x87654321, b"unknown", 9))
        sender.sendall(dash.media(-1, b"x", token=-42))
        self.assertEqual(dash.read_media(receiver), (-1, b"x", -42))

    def test_coalesced_messages_and_partial_eof(self):
        sender, receiver = self.pair()
        sender.sendall(dash.pxc(1) + dash.pxc(2, b"body"))
        self.assertEqual(dash.read_pxc(receiver), (1, b"", 0))
        self.assertEqual(dash.read_pxc(receiver), (2, b"body", 0))
        sender.sendall(dash.media(17, b"123")[:-1])
        sender.shutdown(socket.SHUT_WR)
        with self.assertRaisesRegex(dash.PeerError, "EOF"):
            dash.read_media(receiver)

    def test_rejects_lengths_and_checksum_before_reading_body(self):
        for command, total, checksum in [(1, 15, 1 ^ 15), (1, 0xffffffff, 1 ^ 0xffffffff), (1, 16, 0)]:
            sender, receiver = self.pair()
            sender.sendall(struct.pack("<IIII", command, total, checksum, 0))
            with self.assertRaises(dash.PeerError):
                dash.read_pxc(receiver)

    def test_request_reply_shape_checks_token_and_command(self):
        sender, receiver = self.pair()
        sender.sendall(dash.media(65, token=1))
        with self.assertRaises(dash.PeerError):
            dash.expect(receiver, "media", 65)
        sender.sendall(dash.pxc(0x10002))
        with self.assertRaises(dash.PeerError):
            dash.expect(receiver, "pxc", 0x10001)

    def test_encoders_enforce_local_frame_limits(self):
        self.assertEqual(len(dash.pxc(1, b"x" * (1024 * 1024 - 16))), 1024 * 1024)
        with self.assertRaises(dash.PeerError):
            dash.pxc(1, b"x" * (1024 * 1024 - 15))
        self.assertEqual(len(dash.media(1, b"x" * 65535)), 65543)
        with self.assertRaises(dash.PeerError):
            dash.media(1, b"x" * 65536)

    def test_fault_observer_rejects_any_reply_then_accepts_eof(self):
        sender, receiver = self.pair()
        sender.sendall(b"x")
        with self.assertRaises(dash.PeerError):
            dash.expect_closed(receiver)
        sender.shutdown(socket.SHUT_WR)
        dash.expect_closed(receiver)


if __name__ == "__main__":
    unittest.main()

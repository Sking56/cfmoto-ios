"""Independent synthetic EasyConnect dashboard peer. No firmware/crypto claim."""
import argparse
from contextlib import ExitStack
import json
import select
import socket
import struct
import subprocess


class PeerError(ValueError):
    pass


def pxc(command, body=b"", reserved=0):
    total = 16 + len(body)
    if total > 1024 * 1024:
        raise PeerError("oversized PXC frame")
    return struct.pack("<IIII", command, total, command ^ total, reserved) + body


def media(command, body=b"", token=0):
    if len(body) > 65535:
        raise PeerError("oversized media frame")
    return struct.pack("<hHi", command, len(body), token) + body


def exact(connection, count):
    parts = bytearray()
    while len(parts) < count:
        data = connection.recv(min(count - len(parts), 65536))
        if not data:
            raise PeerError("unexpected EOF")
        parts.extend(data)
    return bytes(parts)


def read_pxc(connection):
    command, total, checksum, reserved = struct.unpack("<IIII", exact(connection, 16))
    if checksum != command ^ total:
        raise PeerError("invalid PXC XOR")
    if total < 16 or total > 1024 * 1024:
        raise PeerError("invalid PXC size")
    return command, exact(connection, total - 16), reserved


def read_media(connection):
    command, length, token = struct.unpack("<hHi", exact(connection, 8))
    return command, exact(connection, length), token


def json_body(value):
    return json.dumps(value, separators=(",", ":")).encode("utf-8")


def send_chunks(connection, data, chunk_size):
    for offset in range(0, len(data), chunk_size):
        connection.sendall(data[offset:offset + chunk_size])


def expect(connection, wire, command, body=b""):
    actual, payload, field = read_pxc(connection) if wire == "pxc" else read_media(connection)
    if actual != command or field != 0 or (body is not None and payload != body):
        raise PeerError("unexpected reply shape")
    return payload


def expect_closed(connection):
    try:
        data = connection.recv(1)
    except ConnectionResetError:
        return
    if data:
        raise PeerError("rejected session produced a reply")
    if data != b"":
        raise PeerError("session did not close")


def expect_idle(connection):
    if select.select([connection], [], [], 0.05)[0]:
        raise PeerError("unsolicited media or early close")


def read_video(connection):
    header = exact(connection, 4)
    length, = struct.unpack("<I", header)
    if not 0 < length <= 1024 * 1024:
        raise PeerError("invalid raw-video size")
    body = exact(connection, length)
    if not body.startswith(b"\x00\x00\x00\x01"):
        raise PeerError("missing Annex-B start code")
    nals = body.split(b"\x00\x00\x00\x01")[1:]
    if any(not nal or nal[0] & 0x80 for nal in nals):
        raise PeerError("invalid Annex-B unit")
    return header + body, [nal[0] & 31 for nal in nals]


def inspect_video(inspector, packets):
    result = subprocess.run([inspector], input=b"".join(packets), capture_output=True, timeout=30)
    if result.returncode != 0:
        raise PeerError("independent video decode failed")
    summary = json.loads(result.stdout)
    images = summary.get("images", [])
    if summary.get("result") != "PASS" or len(images) != 12 or summary.get("profile") != 66 or summary.get("level") != 31:
        raise PeerError("unexpected decoded video profile/count")
    for index, image in enumerate(images):
        if image.get("width") != 800 or image.get("height") != 384 or abs(image.get("markerX", -1000) - index * 16) > 8:
            raise PeerError("wrong decoded geometry or stale/static frame")
        colors = image.get("colors", [])
        expected = [[240, 20, 20], [20, 240, 20], [20, 20, 240]]
        if len(colors) != 3 or any(len(actual) != 3 or any(abs(a - b) > 45 for a, b in zip(actual, target))
                                   for actual, target in zip(colors, expected)):
            raise PeerError("wrong decoded calibration colors")
    if summary.get("keyframes", 0) < 2:
        raise PeerError("restart did not produce a fresh keyframe")
    return summary


def run(bind, phone, ports, chunk_size=3, fault="none", video=False, inspector=None):
    wake_port, pxc_port, control_port, data_port = ports
    with ExitStack() as stack:
        server = stack.enter_context(socket.socket(socket.AF_INET, socket.SOCK_STREAM))
        server.settimeout(8)
        server.bind((bind, wake_port))
        server.listen(1)
        print(json.dumps({"event": "listening", "mode": "synthetic-no-crypto"}), flush=True)
        wake, _ = server.accept()
        stack.enter_context(wake)
        wake.settimeout(4)
        command, body, _ = read_pxc(wake)
        if command != 0x70000010 or json.loads(body) != {
            "phoneType": "Android", "packageName": "com.cfmoto.cfmotointernational"
        }:
            raise PeerError("unexpected wake request")
        if fault != "delayed-wake":
            send_chunks(wake, pxc(0x70000011, json_body({"status": fault != "reject-wake"})), chunk_size)
        if fault == "reject-wake":
            expect_closed(wake)
            return {"mode": "synthetic-no-crypto", "result": "fault-delivered", "fault": fault}

        def callback(port):
            connection = stack.enter_context(socket.create_connection((phone, port), timeout=4))
            connection.settimeout(4)
            return connection

        ctrl = callback(pxc_port)
        if fault in {"oversized-pxc", "truncated-pxc"}:
            total = 1024 * 1024 + 1
            packet = struct.pack("<IIII", 0x10000, total, 0x10000 ^ total, 0) if fault == "oversized-pxc" else pxc(0x10000)[:12]
            send_chunks(ctrl, packet, chunk_size)
            if fault == "truncated-pxc":
                ctrl.shutdown(socket.SHUT_WR)
            expect_closed(ctrl)
            return {"mode": "synthetic-no-crypto", "result": "fault-delivered", "fault": fault}
        if fault == "bad-xor":
            packet = bytearray(pxc(0x10000))
            packet[8] ^= 1
            send_chunks(ctrl, packet, chunk_size)
            expect_closed(ctrl)
            return {"mode": "synthetic-no-crypto", "result": "fault-delivered", "fault": fault}
        if fault == "disconnect":
            ctrl.close()
            expect_closed(wake)
            return {"mode": "synthetic-no-crypto", "result": "fault-delivered", "fault": fault}

        send_chunks(ctrl, pxc(0x10000) + pxc(0x70000000), chunk_size)
        expect(ctrl, "pxc", 0x10001)
        expect(ctrl, "pxc", 0x70000001)
        if fault == "unknown-command":
            send_chunks(ctrl, pxc(0x33333), chunk_size)
            expect_closed(ctrl)
            return {"mode": "synthetic-no-crypto", "result": "fault-delivered", "fault": fault}
        data = ctrl
        if fault != "missing-channel":
            data = callback(pxc_port)
            if fault == "duplicate-channel":
                send_chunks(data, pxc(0x10000), chunk_size)
                expect_closed(data)
                return {"mode": "synthetic-no-crypto", "result": "fault-delivered", "fault": fault}
            send_chunks(data, pxc(0x20000) + pxc(0x70000000), chunk_size)
            expect(data, "pxc", 0x20001)
            expect(data, "pxc", 0x70000001)
        if fault == "delayed-wake":
            # Both PXC selectors have already been acknowledged before wake acceptance.
            send_chunks(wake, pxc(0x70000011, json_body({"status": True})), chunk_size)
        if fault in {"early-start", "early-pull"}:
            stream = callback(data_port)
            send_chunks(stream, media(112 if fault == "early-start" else 114), chunk_size)
            expect_closed(stream)
            return {"mode": "synthetic-no-crypto", "result": "fault-delivered", "fault": fault}

        send_chunks(ctrl, pxc(0x10010, json_body({"HUID": "SYNTHETIC-HU-0001"})), chunk_size)
        identity = json.loads(expect(ctrl, "pxc", 0x10011, None))
        if identity != {"profile": "synthetic-no-crypto", "phoneUUID": "SYNTHETIC-PHONE",
                        "supportH264IFrame": True, "supportFunction": 0}:
            raise PeerError("unexpected synthetic identity")
        send_chunks(ctrl, pxc(0x10690), chunk_size)
        expect(ctrl, "pxc", 0x10691)
        send_chunks(data, pxc(0x103e0, json_body({"sn": "SYNTHETIC-SN-0001", "client_set": "easy_conn"})), chunk_size)
        expect(data, "pxc", 0x103e1)
        result = json.loads(expect(data, "pxc", 0x201c0, None))
        if result != {"isOk": True, "errCode": 0, "errMsg": "", "id": "SYNTHETIC-SN-0001", "client_set": "easy_conn"}:
            raise PeerError("unexpected CHECK_SN result")
        send_chunks(data, pxc(0x201c1), chunk_size)

        control = callback(control_port)
        if fault == "duplicate-media":
            duplicate = callback(control_port)
            expect_closed(duplicate)
            return {"mode": "synthetic-no-crypto", "result": "fault-delivered", "fault": fault}
        capture = bytearray(32)
        struct.pack_into("<HHii", capture, 0, 800, 386, 30, 2)
        capture[29] = 1
        send_chunks(control, media(48, token=42) + media(16, capture, token=-123), chunk_size)
        expect(control, "media", 49, struct.pack("<ii", 3, 1))
        expect(control, "media", 17, struct.pack("<iHHB", 2, 800, 384, 1))
        send_chunks(control, media(96, json_body({"fixture": True})) + media(64) + media(128), chunk_size)
        expect(control, "media", 97, json_body({"state": 0}))
        expect(control, "media", 65)
        expect(control, "media", 129)

        stream = callback(data_port)
        if video:
            expect_idle(stream)
        send_chunks(stream, media(112), chunk_size)
        if fault == "missing-channel":
            # Every capability is valid, but CAR_DATA was never selected.
            expect_closed(stream)
            return {"mode": "synthetic-no-crypto", "result": "fault-delivered", "fault": fault}
        expect(stream, "media", 113)
        if video:
            packets, keyframes = [], []
            for index in range(12):
                if index == 6:
                    send_chunks(stream, media(112), chunk_size)
                    expect(stream, "media", 113)
                expect_idle(stream)
                send_chunks(stream, media(114), chunk_size)
                packet, types = read_video(stream)
                if index in {0, 6} and not all(value in types for value in [7, 8, 5]):
                    raise PeerError("startup/restart lacks SPS/PPS/IDR")
                if 5 in types:
                    keyframes.append(index)
                packets.append(packet)
            expect_closed(stream)
            decoded = inspect_video(inspector, packets)
            return {"mode": "synthetic-no-crypto", "result": "PASS", "channels": 4, "video_frames": 12,
                    "keyframes": keyframes, "decoded_frames": len(decoded["images"]), "pull_only": True}
        send_chunks(stream, media(114), chunk_size)
        # The host probe has no frame source: a pull must not fabricate a frame/reply.
        expect_closed(stream)
        return {"mode": "synthetic-no-crypto", "result": "PASS", "channels": 4, "video_frames": 0}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bind", default="127.0.0.1")
    parser.add_argument("--phone", default="127.0.0.1")
    parser.add_argument("--ports", type=int, nargs=4, default=[10930, 10922, 10921, 10920],
                        metavar=("WAKE", "PXC", "CONTROL", "DATA"))
    parser.add_argument("--chunk-size", type=int, default=3)
    parser.add_argument("--video", action="store_true")
    parser.add_argument("--inspector", help="Independent native decoder executable (required with --video)")
    parser.add_argument("--fault", choices=["none", "delayed-wake", "reject-wake", "bad-xor", "oversized-pxc",
                                           "truncated-pxc", "unknown-command", "duplicate-channel", "duplicate-media", "missing-channel",
                                           "early-start", "early-pull", "disconnect"], default="none")
    args = parser.parse_args()
    if args.chunk_size < 1 or any(not 0 < port < 65536 for port in args.ports) or len(set(args.ports)) != 4:
        parser.error("positive chunk size and four distinct valid ports required")
    if args.video and (not args.inspector or args.fault != "none"):
        parser.error("video mode requires an inspector and the none fault case")
    try:
        print(json.dumps(run(args.bind, args.phone, args.ports, args.chunk_size, args.fault, args.video, args.inspector), sort_keys=True))
    except (PeerError, OSError, ValueError, struct.error, subprocess.TimeoutExpired):
        print("SIMULATOR FAIL: invalid or incomplete synthetic exchange")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

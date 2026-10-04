"""Independent synthetic EasyConnect dashboard peer. No firmware/crypto claim."""
import argparse
from contextlib import ExitStack
import json
import socket
import struct


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


def run(bind, phone, ports, chunk_size=3, fault="none"):
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
        send_chunks(wake, pxc(0x70000011, json_body({"status": fault != "reject-wake"})), chunk_size)
        if fault == "reject-wake":
            expect_closed(wake)
            return {"mode": "synthetic-no-crypto", "result": "fault-delivered", "fault": fault}

        def callback(port):
            connection = stack.enter_context(socket.create_connection((phone, port), timeout=4))
            connection.settimeout(4)
            return connection

        ctrl = callback(pxc_port)
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
        data = callback(pxc_port)
        if fault == "duplicate-channel":
            send_chunks(data, pxc(0x10000), chunk_size)
            expect_closed(data)
            return {"mode": "synthetic-no-crypto", "result": "fault-delivered", "fault": fault}
        send_chunks(data, pxc(0x20000) + pxc(0x70000000), chunk_size)
        expect(data, "pxc", 0x20001)
        expect(data, "pxc", 0x70000001)
        if fault == "early-start":
            stream = callback(data_port)
            send_chunks(stream, media(112), chunk_size)
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
        send_chunks(stream, media(112), chunk_size)
        expect(stream, "media", 113)
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
    parser.add_argument("--fault", choices=["none", "reject-wake", "bad-xor", "duplicate-channel", "early-start", "disconnect"], default="none")
    args = parser.parse_args()
    if args.chunk_size < 1 or any(not 0 < port < 65536 for port in args.ports) or len(set(args.ports)) != 4:
        parser.error("positive chunk size and four distinct valid ports required")
    try:
        print(json.dumps(run(args.bind, args.phone, args.ports, args.chunk_size, args.fault), sort_keys=True))
    except (PeerError, OSError, ValueError, struct.error):
        print("SIMULATOR FAIL: invalid or incomplete synthetic exchange")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

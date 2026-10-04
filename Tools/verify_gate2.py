"""Synthetic pulled VideoToolbox output with independent receiver decode; no hardware claim."""
import json
from pathlib import Path
import selectors
import subprocess
import sys

from verify_gate1 import available_ports

ROOT = Path(__file__).resolve().parents[1]


def video_case(chunk_size):
    ports = [str(value) for value in available_ports()]
    binary = ROOT / "build/SwiftPM/debug/ProtocolProbe"
    inspector = ROOT / "build/SwiftPM/debug/VideoInspector"
    command = [sys.executable, "Tools/DashSimulator/dash_simulator.py", "--ports", *ports,
               "--chunk-size", str(chunk_size), "--video", "--inspector", str(inspector)]
    with subprocess.Popen(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True) as receiver:
        try:
            with selectors.DefaultSelector() as selector:
                selector.register(receiver.stdout, selectors.EVENT_READ)
                if not selector.select(timeout=10):
                    raise RuntimeError("video receiver startup timeout")
            if json.loads(receiver.stdout.readline()).get("event") != "listening":
                raise RuntimeError("video receiver did not listen")
            phone = subprocess.run([str(binary), "--video", *ports], cwd=ROOT, capture_output=True, text=True, timeout=40)
            output, _ = receiver.communicate(timeout=35)
            if phone.returncode != 0 or receiver.returncode != 0:
                raise RuntimeError(f"synthetic video case failed\n{phone.stdout}{phone.stderr}{output}")
            sender, decoder = json.loads(phone.stdout), json.loads(output)
            if sender.get("reason") != "synthetic-video-pulls" or sender.get("video_frames") != 12 or \
                    decoder.get("decoded_frames") != 12 or decoder.get("pull_only") is not True:
                raise RuntimeError("missing synthetic decode evidence")
            print(f"PASS: 12 independently decoded pulled frames, restart IDR, moving pixels; chunk_size={chunk_size}", flush=True)
        finally:
            if receiver.poll() is None:
                receiver.terminate()
                try:
                    receiver.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    receiver.kill(); receiver.wait()


def main():
    subprocess.run([sys.executable, "Tools/verify_gate1.py"], cwd=ROOT, check=True)
    for chunk_size in [1, 65536]:
        video_case(chunk_size)
    inspector = ROOT / "build/SwiftPM/debug/VideoInspector"
    for packet in [b"", b"\x01\x00\x00\x00", b"\xff\xff\xff\xff", b"\x05\x00\x00\x00\x00\x00\x00\x01\x41"]:
        result = subprocess.run([str(inspector)], input=packet, capture_output=True, timeout=5)
        if result.returncode != 1:
            raise RuntimeError("independent inspector accepted malformed/incomplete startup")
    print("PASS: synthetic host video only; capture, production iPhone transport and TFT remain unverified.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

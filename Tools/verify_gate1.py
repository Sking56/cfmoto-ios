"""Host core tests and independent synthetic socket cases; not a native gate pass."""
from contextlib import ExitStack
import json
import os
from pathlib import Path
import selectors
import socket
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
FAILURE_REASONS = {
    "reject-wake": {"wakeRejected"},
    "duplicate-media": {"callbackRejected"},
    "disconnect": {"callbackClosed", "connectionLost"},
    **{fault: {"protocolViolation"} for fault in ["bad-xor", "oversized-pxc", "truncated-pxc", "unknown-command",
                                                "duplicate-channel", "missing-channel", "early-start", "early-pull"]},
}
SWIFT = ["swift", "test", "--disable-sandbox", "--scratch-path", "build/SwiftPM",
         "--cache-path", "build/SwiftCache", "--config-path", "build/SwiftConfig",
         "--security-path", "build/SwiftSecurity"]


def available_ports():
    with ExitStack() as stack:
        sockets = [stack.enter_context(socket.socket()) for _ in range(4)]
        for connection in sockets:
            connection.bind(("127.0.0.1", 0))
        return [connection.getsockname()[1] for connection in sockets]


def integration_case(binary, fault, chunk_size):
    ports = [str(port) for port in available_ports()]
    command = [sys.executable, "Tools/DashSimulator/dash_simulator.py", "--ports", *ports,
               "--fault", fault, "--chunk-size", str(chunk_size)]
    with subprocess.Popen(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True) as dashboard:
        try:
            with selectors.DefaultSelector() as selector:
                selector.register(dashboard.stdout, selectors.EVENT_READ)
                if not selector.select(timeout=10):
                    raise RuntimeError("dashboard startup timeout")
            ready = dashboard.stdout.readline()
            if json.loads(ready).get("event") != "listening":
                raise RuntimeError("dashboard failed to listen: " + ready)
            phone = subprocess.run([str(binary), *ports], cwd=ROOT, capture_output=True, text=True, timeout=18)
            output, _ = dashboard.communicate(timeout=8)
            expected_success = fault in {"none", "delayed-wake"}
            if dashboard.returncode != 0 or phone.returncode != (0 if expected_success else 1):
                raise RuntimeError(f"socket case {fault} failed\n{phone.stdout}{phone.stderr}{output}")
            dash_result, phone_result = json.loads(output), json.loads(phone.stdout)
            if dash_result.get("result") != ("PASS" if expected_success else "fault-delivered") or \
                    phone_result.get("result") != ("PASS" if expected_success else "FAIL") or \
                    phone_result.get("mode") != "synthetic-no-crypto":
                raise RuntimeError("missing synthetic case evidence")
            expected_reasons = {"synthetic-handshake-and-empty-pull"} if expected_success else FAILURE_REASONS[fault]
            if phone_result.get("reason") not in expected_reasons:
                raise RuntimeError(f"wrong termination reason for {fault}: {phone_result.get('reason')}")
            print(f"PASS: independent socket case fault={fault} chunk_size={chunk_size}", flush=True)
        finally:
            if dashboard.poll() is None:
                dashboard.terminate()
                try:
                    dashboard.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    dashboard.kill()
                    dashboard.wait()


def main():
    environment = dict(os.environ)
    environment["CLANG_MODULE_CACHE_PATH"] = str(ROOT / "build/ClangModuleCache")
    subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT, check=True)
    subprocess.run(SWIFT, cwd=ROOT, env=environment, check=True)
    # SwiftPM exposes a platform-specific debug symlink at this path.
    binary = ROOT / "build/SwiftPM/debug/ProtocolProbe"
    for fault, chunk_size in [("none", 1), ("none", 65536), ("reject-wake", 3),
                              ("delayed-wake", 3), ("bad-xor", 3), ("oversized-pxc", 3), ("truncated-pxc", 3),
                              ("unknown-command", 3), ("duplicate-channel", 3), ("duplicate-media", 3),
                              ("missing-channel", 3), ("early-start", 3), ("early-pull", 3), ("disconnect", 3)]:
        integration_case(binary, fault, chunk_size)
    print("PASS: legacy host protocol checks; this command does not verify native iOS, RSA, capture, received video or TFT.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

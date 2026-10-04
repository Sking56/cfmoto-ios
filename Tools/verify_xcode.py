"""Build and launch-test the exact checkout on a suitable Mac; never silently skip."""
from pathlib import Path
import json
import platform
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]

def choose_destination(data: dict) -> str:
    available = []
    for runtime, devices in data.get("devices", {}).items():
        match = re.fullmatch(r"com\.apple\.CoreSimulator\.SimRuntime\.iOS-(\d+)-(\d+)(?:-(\d+))?", runtime)
        if not match or int(match[1]) < 27:
            continue
        version = tuple(int(part or 0) for part in match.groups())
        for device in devices:
            if device.get("isAvailable") and device.get("name", "").startswith("iPhone"):
                available.append((version, device["udid"]))
    if not available:
        raise ValueError("No available iOS 27+ iPhone simulator. Install a matching runtime.")
    return "platform=iOS Simulator,id=" + max(available)[1]

def main() -> int:
    if platform.system() != "Darwin" or not shutil.which("xcodebuild"):
        print("UNVERIFIED: native checks require macOS and Xcode with an iOS 27+ SDK.", file=sys.stderr)
        return 2
    subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT, check=True)
    subprocess.run(["xcodebuild", "-version"], check=True)
    sdks = subprocess.check_output(["xcodebuild", "-showsdks"], text=True)
    print(sdks)
    if not any(int(version) >= 27 for version in re.findall(r"-sdk iphonesimulator(\d+)\.", sdks)):
        print("UNVERIFIED: active Xcode has no iOS 27+ simulator SDK.", file=sys.stderr)
        return 2
    data = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "--json"], text=True))
    try:
        destination = choose_destination(data)
    except ValueError as error:
        print(f"UNVERIFIED: {error}", file=sys.stderr)
        return 2
    common = ["xcodebuild", "-project", "OpenCFMoto.xcodeproj", "-scheme", "OpenCFMoto", "-derivedDataPath", "build/DerivedData", "CODE_SIGNING_ALLOWED=NO"]
    subprocess.run(common + ["-destination", "generic/platform=iOS Simulator", "build", "analyze"], cwd=ROOT, check=True)
    subprocess.run(common + ["-destination", destination, "-resultBundlePath", "build/LaunchTests.xcresult", "test"], cwd=ROOT, check=True)
    return 0

if __name__ == "__main__":
    sys.exit(main())

"""Exercise portable verification failure paths and simulator selection."""
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "Tools"))
from verify_repository import validate
from verify_xcode import choose_destination

class RepositoryValidationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for name in ["docs", "OpenCFMoto", "OpenCFMotoUITests", "OpenCFMoto.xcodeproj", "Tests/Fixtures", "Tools/DashSimulator", ".github"]:
            shutil.copytree(ROOT / name, self.root / name)
        for name in ["CFMoto_IOS_MVP_V1.md", "README.md", "CONTRIBUTING.md", "LICENSE", ".gitignore", "CHANGELOG.md"]:
            shutil.copy2(ROOT / name, self.root / name)

    def test_current_foundation_is_valid(self):
        self.assertEqual(validate(self.root), [])

    def test_missing_required_document_is_rejected(self):
        (self.root / "docs/engineering/STATUS.md").unlink()
        self.assertTrue(any("STATUS.md" in error for error in validate(self.root)))

    def test_broken_local_document_link_is_rejected(self):
        with (self.root / "README.md").open("a", encoding="utf-8") as file:
            file.write("\n[bad](docs/absent.md)\n")
        self.assertTrue(any("Broken local link" in error for error in validate(self.root)))

    def test_unresolved_xcode_reference_is_rejected(self):
        path = self.root / "OpenCFMoto.xcodeproj/project.pbxproj"
        path.write_text(path.read_text(encoding="utf-8").replace("rootObject = A00000000000000000000050", "rootObject = F00000000000000000000050"), encoding="utf-8")
        self.assertTrue(any("Unresolved Xcode object" in error for error in validate(self.root)))

    def test_invalid_scheme_is_rejected(self):
        (self.root / "OpenCFMoto.xcodeproj/xcshareddata/xcschemes/OpenCFMoto.xcscheme").write_text("<Scheme>", encoding="utf-8")
        self.assertTrue(any("Invalid shared scheme" in error for error in validate(self.root)))

class SimulatorSelectionTests(unittest.TestCase):
    def test_requires_available_iphone_and_supported_runtime(self):
        data = {"devices": {
            "com.apple.CoreSimulator.SimRuntime.iOS-26-0": [{"name": "iPhone Old", "isAvailable": True, "udid": "old"}],
            "com.apple.CoreSimulator.SimRuntime.iOS-27-0": [
                {"name": "iPhone Missing", "isAvailable": False, "udid": "missing"},
                {"name": "iPad", "isAvailable": True, "udid": "tablet"},
                {"name": "iPhone Test", "isAvailable": True, "udid": "valid"}],
            "com.apple.CoreSimulator.SimRuntime.tvOS-27-0": [{"name": "iPhone Fake", "isAvailable": True, "udid": "tv"}]}}
        self.assertEqual(choose_destination(data), "platform=iOS Simulator,id=valid")

    def test_missing_supported_runtime_fails(self):
        with self.assertRaises(ValueError):
            choose_destination({"devices": {}})

    def test_prefers_latest_supported_runtime(self):
        data = {"devices": {
            "com.apple.CoreSimulator.SimRuntime.iOS-27-0": [{"name": "iPhone", "isAvailable": True, "udid": "base"}],
            "com.apple.CoreSimulator.SimRuntime.iOS-27-1-1": [{"name": "iPhone", "isAvailable": True, "udid": "latest"}]}}
        self.assertEqual(choose_destination(data), "platform=iOS Simulator,id=latest")

if __name__ == "__main__":
    unittest.main()

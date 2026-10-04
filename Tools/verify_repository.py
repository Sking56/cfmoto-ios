"""Portable structural checks. These do not replace an Xcode build or hardware test."""
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
ENGINEERING = "README PRODUCT_REQUIREMENTS SYSTEM_ARCHITECTURE OPENCFMOTO_RESEARCH EASYCONNECT_PROTOCOL IOS_PLATFORM NETWORKING VIDEO_PIPELINE STATE_MACHINE TEST_ARCHITECTURE DASH_SIMULATOR HARDWARE_INTEGRATION SECURITY_PRIVACY LICENSING RISKS DECISIONS MVP_TASKS STATUS AGENT_WORKFLOW".split()
PRODUCT = "README PRODUCT_OVERVIEW FEATURES REQUIREMENTS COMPATIBILITY INSTALLATION SETUP_GUIDE USER_GUIDE TESTING_GUIDE TROUBLESHOOTING FAQ PRIVACY LIMITATIONS ROADMAP".split()

def validate(root: Path) -> list[str]:
    errors = []
    required = ["CFMoto_IOS_MVP_V1.md", "README.md", "CONTRIBUTING.md", "LICENSE", ".gitignore", "CHANGELOG.md", ".github/workflows/ci.yml", "OpenCFMoto/App/OpenCFMotoApp.swift", "OpenCFMotoUITests/LaunchTests.swift", "Tools/DashSimulator/README.md", "Tests/Fixtures/README.md"]
    required += [f"docs/engineering/{name}.md" for name in ENGINEERING]
    required += [f"docs/product/{name}.md" for name in PRODUCT]
    for name in required:
        path = root / name
        if not path.is_file() or not path.read_text(encoding="utf-8").strip():
            errors.append(f"Missing or empty required file: {name}")
    project_path = root / "OpenCFMoto.xcodeproj/project.pbxproj"
    if not project_path.is_file():
        errors.append("Missing Xcode project")
    else:
        project = project_path.read_text(encoding="utf-8")
        # A static object-reference sanity check, not an OpenStep plist parser.
        definitions = re.findall(r"^\s*([A-F0-9]{24})\s*=\s*\{", project, re.M)
        references = set(re.findall(r"\b[A-F0-9]{24}\b", project))
        if len(set(definitions)) != len(definitions):
            errors.append("Duplicate Xcode object definitions")
        for reference in references - set(definitions):
            errors.append(f"Unresolved Xcode object: {reference}")
        for relative in re.findall(r"path = ([^;]+\.swift);", project):
            if not (root / relative.strip('"')).is_file():
                errors.append(f"Missing Xcode Swift source: {relative}")
        for folder in ["Pairing", "EasyConnect", "Video"]:
            for source in (root / "OpenCFMoto" / folder).rglob("*.swift"):
                if f"path = {source.relative_to(root).as_posix()};" not in project:
                    errors.append(f"Core Swift source missing from Xcode project: {source.relative_to(root)}")
        if "IPHONEOS_DEPLOYMENT_TARGET = 27.0;" not in project:
            errors.append("iOS 27 minimum deployment target missing")
    scheme_path = root / "OpenCFMoto.xcodeproj/xcshareddata/xcschemes/OpenCFMoto.xcscheme"
    try:
        scheme = ET.parse(scheme_path)
        if not scheme.findall(".//TestableReference"):
            errors.append("Shared scheme has no testable target")
    except (OSError, ET.ParseError) as error:
        errors.append(f"Invalid shared scheme: {error}")
    # Verify local markdown links in committed documentation, including new research.
    docs = [root / "README.md", root / "CONTRIBUTING.md"]
    docs += list((root / "docs").rglob("*.md"))
    for path in docs:
        if not path.is_file():
            continue
        for target in re.findall(r"(?<!!)\[[^\]]+\]\(([^)]+)\)", path.read_text(encoding="utf-8")):
            if re.match(r"[a-zA-Z][a-zA-Z0-9+.-]*:", target) or target.startswith("#"):
                continue
            local = target.split("#", 1)[0].replace("%20", " ")
            if local and not (path.parent / local).exists():
                errors.append(f"Broken local link in {path.relative_to(root)}: {target}")
    return errors

if __name__ == "__main__":
    failures = validate(ROOT)
    for failure in failures:
        print(f"FAIL: {failure}")
    if failures:
        sys.exit(1)
    print("PASS: portable repository structure, Xcode references, scheme XML and documentation links")
    print("Native compilation, UI launch and hardware behavior are not checked by this command.")

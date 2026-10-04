"""Generate the dependency-free foundation project; no Xcode installation required."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

PROJECT = r'''// !$*UTF8*$!
{
    archiveVersion = 1;
    classes = {};
    objectVersion = 56;
    objects = {
        A00000000000000000000001 = {isa = PBXBuildFile; fileRef = A00000000000000000000011; };
        A00000000000000000000002 = {isa = PBXBuildFile; fileRef = A00000000000000000000012; };
        A00000000000000000000011 = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = OpenCFMoto/App/OpenCFMotoApp.swift; sourceTree = "<group>"; };
        A00000000000000000000012 = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = OpenCFMotoUITests/LaunchTests.swift; sourceTree = "<group>"; };
        A00000000000000000000013 = {isa = PBXFileReference; explicitFileType = wrapper.application; path = OpenCFMoto.app; sourceTree = BUILT_PRODUCTS_DIR; };
        A00000000000000000000014 = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; path = OpenCFMotoUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
        A00000000000000000000020 = {isa = PBXGroup; children = (A00000000000000000000011, A00000000000000000000012, A00000000000000000000021); sourceTree = "<group>"; };
        A00000000000000000000021 = {isa = PBXGroup; children = (A00000000000000000000013, A00000000000000000000014); name = Products; sourceTree = "<group>"; };
        A00000000000000000000030 = {isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (A00000000000000000000001); runOnlyForDeploymentPostprocessing = 0; };
        A00000000000000000000031 = {isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (A00000000000000000000002); runOnlyForDeploymentPostprocessing = 0; };
        A00000000000000000000032 = {isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };
        A00000000000000000000033 = {isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };
        A00000000000000000000034 = {isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };
        A00000000000000000000035 = {isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };
        A00000000000000000000040 = {
            isa = PBXNativeTarget;
            buildConfigurationList = A00000000000000000000061;
            buildPhases = (A00000000000000000000030, A00000000000000000000032, A00000000000000000000034);
            buildRules = (); dependencies = ();
            name = OpenCFMoto; productName = OpenCFMoto;
            productReference = A00000000000000000000013;
            productType = "com.apple.product-type.application";
        };
        A00000000000000000000041 = {
            isa = PBXNativeTarget;
            buildConfigurationList = A00000000000000000000062;
            buildPhases = (A00000000000000000000031, A00000000000000000000033, A00000000000000000000035);
            buildRules = (); dependencies = (A00000000000000000000043);
            name = OpenCFMotoUITests; productName = OpenCFMotoUITests;
            productReference = A00000000000000000000014;
            productType = "com.apple.product-type.bundle.ui-testing";
        };
        A00000000000000000000042 = {isa = PBXContainerItemProxy; containerPortal = A00000000000000000000050; proxyType = 1; remoteGlobalIDString = A00000000000000000000040; remoteInfo = OpenCFMoto; };
        A00000000000000000000043 = {isa = PBXTargetDependency; target = A00000000000000000000040; targetProxy = A00000000000000000000042; };
        A00000000000000000000050 = {
            isa = PBXProject;
            attributes = {LastUpgradeCheck = 2700; TargetAttributes = {A00000000000000000000040 = {CreatedOnToolsVersion = 27.0; }; A00000000000000000000041 = {CreatedOnToolsVersion = 27.0; TestTargetID = A00000000000000000000040; }; }; };
            buildConfigurationList = A00000000000000000000060;
            compatibilityVersion = "Xcode 14.0"; developmentRegion = en;
            hasScannedForEncodings = 0; knownRegions = (en, Base);
            mainGroup = A00000000000000000000020;
            productRefGroup = A00000000000000000000021;
            projectDirPath = ""; projectRoot = "";
            targets = (A00000000000000000000040, A00000000000000000000041);
        };
        A00000000000000000000060 = {isa = XCConfigurationList; buildConfigurations = (A00000000000000000000070, A00000000000000000000071); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };
        A00000000000000000000061 = {isa = XCConfigurationList; buildConfigurations = (A00000000000000000000072, A00000000000000000000073); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };
        A00000000000000000000062 = {isa = XCConfigurationList; buildConfigurations = (A00000000000000000000074, A00000000000000000000075); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };
        A00000000000000000000070 = {isa = XCBuildConfiguration; buildSettings = {SDKROOT = iphoneos; IPHONEOS_DEPLOYMENT_TARGET = 27.0; SWIFT_VERSION = 6.0; CLANG_ENABLE_MODULES = YES; DEBUG_INFORMATION_FORMAT = dwarf; SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG; SWIFT_OPTIMIZATION_LEVEL = "-Onone"; }; name = Debug; };
        A00000000000000000000071 = {isa = XCBuildConfiguration; buildSettings = {SDKROOT = iphoneos; IPHONEOS_DEPLOYMENT_TARGET = 27.0; SWIFT_VERSION = 6.0; CLANG_ENABLE_MODULES = YES; DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym"; SWIFT_COMPILATION_MODE = wholemodule; }; name = Release; };
        A00000000000000000000072 = {isa = XCBuildConfiguration; buildSettings = {GENERATE_INFOPLIST_FILE = YES; INFOPLIST_KEY_UILaunchScreen_Generation = YES; INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES; PRODUCT_BUNDLE_IDENTIFIER = org.opencfmoto.prototype; PRODUCT_NAME = "$(TARGET_NAME)"; CURRENT_PROJECT_VERSION = 1; MARKETING_VERSION = 0.0.1; TARGETED_DEVICE_FAMILY = 1; CODE_SIGN_STYLE = Automatic; }; name = Debug; };
        A00000000000000000000073 = {isa = XCBuildConfiguration; buildSettings = {GENERATE_INFOPLIST_FILE = YES; INFOPLIST_KEY_UILaunchScreen_Generation = YES; INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES; PRODUCT_BUNDLE_IDENTIFIER = org.opencfmoto.prototype; PRODUCT_NAME = "$(TARGET_NAME)"; CURRENT_PROJECT_VERSION = 1; MARKETING_VERSION = 0.0.1; TARGETED_DEVICE_FAMILY = 1; CODE_SIGN_STYLE = Automatic; }; name = Release; };
        A00000000000000000000074 = {isa = XCBuildConfiguration; buildSettings = {GENERATE_INFOPLIST_FILE = YES; PRODUCT_BUNDLE_IDENTIFIER = org.opencfmoto.prototype.uitests; PRODUCT_NAME = "$(TARGET_NAME)"; TARGETED_DEVICE_FAMILY = 1; TEST_TARGET_NAME = OpenCFMoto; CODE_SIGN_STYLE = Automatic; }; name = Debug; };
        A00000000000000000000075 = {isa = XCBuildConfiguration; buildSettings = {GENERATE_INFOPLIST_FILE = YES; PRODUCT_BUNDLE_IDENTIFIER = org.opencfmoto.prototype.uitests; PRODUCT_NAME = "$(TARGET_NAME)"; TARGETED_DEVICE_FAMILY = 1; TEST_TARGET_NAME = OpenCFMoto; CODE_SIGN_STYLE = Automatic; }; name = Release; };
    };
    rootObject = A00000000000000000000050;
}
'''

SCHEME = '''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2700" version="1.3">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
    <BuildActionEntries>
      <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
        <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="A00000000000000000000040" BuildableName="OpenCFMoto.app" BlueprintName="OpenCFMoto" ReferencedContainer="container:OpenCFMoto.xcodeproj"/>
      </BuildActionEntry>
    </BuildActionEntries>
  </BuildAction>
  <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES">
    <Testables>
      <TestableReference skipped="NO"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="A00000000000000000000041" BuildableName="OpenCFMotoUITests.xctest" BlueprintName="OpenCFMotoUITests" ReferencedContainer="container:OpenCFMoto.xcodeproj"/></TestableReference>
    </Testables>
  </TestAction>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugServiceExtension="internal" allowLocationSimulation="YES">
    <BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="A00000000000000000000040" BuildableName="OpenCFMoto.app" BlueprintName="OpenCFMoto" ReferencedContainer="container:OpenCFMoto.xcodeproj"/></BuildableProductRunnable>
  </LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="A00000000000000000000040" BuildableName="OpenCFMoto.app" BlueprintName="OpenCFMoto" ReferencedContainer="container:OpenCFMoto.xcodeproj"/></BuildableProductRunnable></ProfileAction>
  <AnalyzeAction buildConfiguration="Debug"/>
  <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
'''

def generate(root: Path = ROOT) -> None:
    project = root / "OpenCFMoto.xcodeproj"
    project.mkdir(parents=True, exist_ok=True)
    core_sources = sorted(path for folder in ["Pairing", "EasyConnect", "Video"]
                          for path in (root / "OpenCFMoto" / folder).rglob("*.swift"))
    definitions, build_ids, file_ids = [], [], []
    for index, source in enumerate(core_sources, start=1):
        build_id, file_id = f"B{2 * index:023X}", f"B{2 * index + 1:023X}"
        relative = source.relative_to(root).as_posix()
        definitions += [
            f'        {build_id} = {{isa = PBXBuildFile; fileRef = {file_id}; }};',
            f'        {file_id} = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {relative}; sourceTree = "<group>"; }};'
        ]
        build_ids.append(build_id)
        file_ids.append(file_id)
    rendered = PROJECT
    if core_sources:
        rendered = rendered.replace("    objects = {", "    objects = {\n" + "\n".join(definitions), 1)
        rendered = rendered.replace("children = (A00000000000000000000011,",
                                    "children = (" + ", ".join(file_ids) + ", A00000000000000000000011,", 1)
        rendered = rendered.replace("files = (A00000000000000000000001);",
                                    "files = (A00000000000000000000001, " + ", ".join(build_ids) + ");", 1)
    (project / "project.pbxproj").write_text(rendered, encoding="utf-8")
    scheme = project / "xcshareddata/xcschemes/OpenCFMoto.xcscheme"
    scheme.parent.mkdir(parents=True, exist_ok=True)
    scheme.write_text(SCHEME, encoding="utf-8")

if __name__ == "__main__":
    generate()

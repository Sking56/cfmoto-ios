import Foundation
import ProtocolHarness

var arguments = Array(CommandLine.arguments.dropFirst())
let video = arguments.first == "--video"
if video { arguments.removeFirst() }
let portArguments = arguments.isEmpty ? ["10930", "10922", "10921", "10920"] : arguments
let ports = portArguments.compactMap(UInt16.init)
guard ports.count == 4, ports.allSatisfy({ $0 > 0 }), Set(ports).count == 4 else {
    print("Usage: ProtocolProbe [--video] [wake-port pxc-port media-control-port media-data-port]")
    exit(2)
}
exit(HostProbe(ports: ports, videoEnabled: video).run() ? 0 : 1)

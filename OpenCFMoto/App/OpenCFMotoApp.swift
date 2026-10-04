import SwiftUI

@main
struct OpenCFMotoApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 16) {
                Text("OpenCFMoto iOS")
                    .font(.largeTitle)
                    .accessibilityIdentifier("prototypeTitle")
                Text("Research prototype")
                    .font(.headline)
                Text("Pairing and mirroring are not available yet.")
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}


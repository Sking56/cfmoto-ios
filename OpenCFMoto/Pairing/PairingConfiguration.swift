import Foundation

public enum PairingError: Error, Equatable, Sendable {
    case oversizedInput, malformedURL, malformedEncoding, missingSSID, invalidSSID, missingPassword, invalidAction
}

public struct PairingConfiguration: Sendable, CustomStringConvertible, CustomDebugStringConvertible {
    public let ssid: String
    public let password: String
    public let action: UInt32?
    public let authentication: String?
    public let name: String?

    public var description: String { "PairingConfiguration(credentials: redacted)" }
    public var debugDescription: String { description }

    public static func parse(_ input: String) throws -> Self {
        guard input.utf8.count <= 8192 else { throw PairingError.oversizedInput }
        guard let url = URLComponents(string: input),
              let scheme = url.scheme?.lowercased(), ["https", "http"].contains(scheme),
              url.host != nil, let query = url.percentEncodedQuery else {
            throw PairingError.malformedURL
        }
        // Check the original query: URLComponents can repair a malformed percent escape.
        let original = input.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)[0]
        guard let question = original.firstIndex(of: "?") else { throw PairingError.malformedURL }
        let bytes = Array(original[original.index(after: question)...].utf8)
        let hex: (UInt8) -> Bool = { (48...57).contains($0) || (65...70).contains($0) || (97...102).contains($0) }
        for i in bytes.indices where bytes[i] == 37 {
            guard i + 2 < bytes.count, hex(bytes[i + 1]), hex(bytes[i + 2]) else {
                throw PairingError.malformedEncoding
            }
        }
        var fields: [String: String] = [:]
        for pair in query.split(separator: "&", omittingEmptySubsequences: false) {
            let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard let key = String(parts[0]).replacingOccurrences(of: "+", with: " ").removingPercentEncoding,
                  let value = (parts.count == 2 ? String(parts[1]) : "")
                    .replacingOccurrences(of: "+", with: " ").removingPercentEncoding else {
                throw PairingError.malformedEncoding
            }
            fields[key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()] = value
        }
        let ssid = fields["ssid"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !ssid.isEmpty else { throw PairingError.missingSSID }
        guard ssid.utf8.count <= 32, !ssid.contains("\0") else { throw PairingError.invalidSSID }
        guard let password = fields["pwd"], !password.isEmpty else { throw PairingError.missingPassword }
        var action: UInt32?
        if let value = fields["action"] {
            guard let number = UInt32(value), !value.isEmpty else { throw PairingError.invalidAction }
            action = number
        }
        return Self(ssid: ssid, password: password, action: action,
                    authentication: fields["auth"], name: fields["name"])
    }
}

import Foundation
import XCTest
@testable import OpenCFMotoCore

final class PairingTests: XCTestCase {
    func testReviewedQRFixtures() throws {
        struct Cases: Decodable {
            struct Entry: Decodable { let raw: String; let expected: [String: String] }
            let cases: [Entry]
        }
        let cases = try JSONDecoder().decode(Cases.self, from: fixture("qr/classic-cases.json"))
        for item in cases.cases {
            let config = try PairingConfiguration.parse(item.raw)
            XCTAssertEqual(config.ssid, item.expected["ssid"])
            XCTAssertEqual(config.password, item.expected["pwd"])
            XCTAssertEqual(config.action.map(String.init), item.expected["action"])
            XCTAssertEqual(config.name, item.expected["name"])
        }
    }

    func testUnicodeUnknownFieldsAndRedaction() throws {
        let config = try PairingConfiguration.parse("https://example.invalid/?SSID=%20%E8%87%AA%E8%BB%A2%E8%BB%8A%20&pwd=%20secret%2B+%20&unknown=ignored")
        XCTAssertEqual(config.ssid, "\u{81ea}\u{8ee2}\u{8eca}")
        XCTAssertEqual(config.password, " secret+  ")
        XCTAssertNil(config.action)
        XCTAssertFalse(String(describing: config).contains(config.ssid))
        XCTAssertFalse(String(reflecting: config).contains("secret"))
    }

    func testInvalidQRFieldsAreTypedErrors() {
        let prefix = "https://example.invalid/?"
        let cases: [(String, PairingError)] = [
            (prefix, .missingSSID), (prefix + "&&", .missingSSID),
            (prefix + "pwd=x", .missingSSID), (prefix + "ssid=+&pwd=x", .missingSSID),
            (prefix + "ssid=test", .missingPassword), (prefix + "ssid=test&pwd=", .missingPassword),
            (prefix + "ssid=%ZZ&pwd=x", .malformedEncoding), (prefix + "ssid=%&pwd=x", .malformedEncoding),
            (prefix + "ssid=%FF&pwd=x", .malformedEncoding), (prefix + "ssid=%00&pwd=x", .invalidSSID),
            (prefix + "ssid=test&pwd=x&action=-1", .invalidAction),
            (prefix + "ssid=test&pwd=x&action=4294967296", .invalidAction),
            ("ssid=test&pwd=x", .malformedURL), (prefix + "ssid=" + String(repeating: "x", count: 33) + "&pwd=x", .invalidSSID),
            (String(repeating: "x", count: 8193), .oversizedInput)
        ]
        for (input, expected) in cases {
            XCTAssertThrowsError(try PairingConfiguration.parse(input)) { XCTAssertEqual($0 as? PairingError, expected) }
        }
    }
}

func fixture(_ path: String) throws -> Data {
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    return try Data(contentsOf: root.appendingPathComponent("Tests/Fixtures/" + path))
}

import CryptoKit
import Foundation

public enum LiveIntentParserError: Error, Equatable, Sendable {
  case inputTooLarge
  case invalidJSON
  case noncanonicalJSON
}

public enum LiveStrictIntentParser {
  public static let maximumOutputBytes = 65_536

  public static func canonicalOutput(for intent: LiveUntrustedActionIntent) throws -> String {
    let data = try canonicalEncoder().encode(intent)
    guard let output = String(data: data, encoding: .utf8) else {
      throw LiveIntentParserError.invalidJSON
    }
    return output
  }

  public static func parse(_ output: String) throws -> LiveUntrustedActionIntent {
    let data = Data(output.utf8)
    guard !data.isEmpty, data.count <= maximumOutputBytes else {
      throw LiveIntentParserError.inputTooLarge
    }
    let intent: LiveUntrustedActionIntent
    do {
      intent = try JSONDecoder().decode(LiveUntrustedActionIntent.self, from: data)
    } catch {
      throw LiveIntentParserError.invalidJSON
    }
    guard try canonicalEncoder().encode(intent) == data else {
      throw LiveIntentParserError.noncanonicalJSON
    }
    return intent
  }

  public static func sha256(of string: String) -> String {
    let digest = SHA256.hash(data: Data(string.utf8))
    return "sha256:" + digest.map { String(format: "%02x", $0) }.joined()
  }

  private static func canonicalEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return encoder
  }
}

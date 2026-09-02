import FUMReproducibleMemoryPopulation
import Foundation

public enum LiveEpisodeRuntimeJSON {
  public static let canonicalProfile = CanonicalMemoryJSON.profileID
  public static let maximumCommandBytes = 16_777_216

  public static func encode<T: Encodable>(_ value: T) throws -> Data {
    try CanonicalMemoryJSON.encode(value)
  }

  public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    try JSONDecoder().decode(type, from: data)
  }
}

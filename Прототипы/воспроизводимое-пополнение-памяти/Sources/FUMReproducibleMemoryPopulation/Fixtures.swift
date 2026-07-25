import Foundation

public enum MemoryPopulationFixtures {
  public static func loadBootstrapV1() throws -> Data {
    try load("bootstrap-v1")
  }

  public static func loadBootstrapBaseV1() throws -> Data {
    try load("bootstrap-base-v1")
  }

  public static func loadBootstrapContinuationV1() throws -> Data {
    try load("bootstrap-continuation-v1")
  }

  private static func load(_ name: String) throws -> Data {
    let url =
      Bundle.module.url(
        forResource: name,
        withExtension: "json",
        subdirectory: "Фикстуры"
      ) ?? Bundle.module.url(forResource: name, withExtension: "json")
    guard let url else {
      throw MemoryPopulationError.missingFixture("\(name).json")
    }

    let values = try url.resourceValues(forKeys: [.fileSizeKey])
    guard let byteCount = values.fileSize,
      byteCount <= MemoryPopulationEngine.maximumInputBytes
    else {
      throw MemoryPopulationError.inputTooLarge(values.fileSize ?? -1)
    }
    let data = try Data(contentsOf: url, options: [.mappedIfSafe])
    guard data.count <= MemoryPopulationEngine.maximumInputBytes else {
      throw MemoryPopulationError.inputTooLarge(data.count)
    }
    return data
  }
}

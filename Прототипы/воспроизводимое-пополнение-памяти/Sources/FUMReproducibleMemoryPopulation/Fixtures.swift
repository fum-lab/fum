import Foundation

public enum MemoryPopulationFixtures {
  private static let bootstrapName = "bootstrap-v1"

  public static func loadBootstrapV1() throws -> Data {
    let url =
      Bundle.module.url(
        forResource: bootstrapName,
        withExtension: "json",
        subdirectory: "Фикстуры"
      ) ?? Bundle.module.url(forResource: bootstrapName, withExtension: "json")
    guard let url else {
      throw MemoryPopulationError.missingFixture("\(bootstrapName).json")
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

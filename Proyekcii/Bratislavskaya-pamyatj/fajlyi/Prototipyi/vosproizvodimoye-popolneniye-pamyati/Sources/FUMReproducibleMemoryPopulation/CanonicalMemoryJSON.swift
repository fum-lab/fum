import CryptoKit
import Foundation

public struct CanonicalMemoryJSONError: Error, Equatable, Sendable, CustomStringConvertible {
  public let description: String

  init(_ description: String) {
    self.description = description
  }
}

public enum CanonicalMemoryJSON {
  public static let profileID = "fum.memory.canonical-json.v1"
  public static let maximumSafeInteger: Int64 = 9_007_199_254_740_991
  public static let maximumDepth = 128

  public static func encode<T: Encodable>(_ value: T) throws -> Data {
    let root = CanonicalJSONNode()
    try value.encode(to: CanonicalJSONEncoder(node: root, codingPath: []))
    return Data(try serializeRoot(root))
  }

  public static func canonicalize(_ data: Data) throws -> Data {
    var parser = CanonicalJSONParser(bytes: Array(data))
    let root = try parser.parse()
    return Data(try serializeRoot(root))
  }

  public static func requireCanonical(_ data: Data) throws {
    guard try canonicalize(data) == data else {
      throw CanonicalMemoryJSONError(
        "Вход не совпадает с каноническими байтами профиля \(profileID)."
      )
    }
  }

  public static func sha256(_ data: Data) -> String {
    let hexadecimal = Array("0123456789abcdef".utf8)
    var output = Array("sha256:".utf8)
    output.reserveCapacity(71)
    for byte in SHA256.hash(data: data) {
      output.append(hexadecimal[Int(byte >> 4)])
      output.append(hexadecimal[Int(byte & 0x0f)])
    }
    return String(decoding: output, as: UTF8.self)
  }

  private static func serializeRoot(_ root: CanonicalJSONNode) throws -> [UInt8] {
    guard case .object = root.value else {
      throw CanonicalMemoryJSONError("Верхний уровень канонической памяти должен быть объектом.")
    }
    var output: [UInt8] = []
    try serialize(root, depth: 0, into: &output)
    return output
  }

  private static func serialize(
    _ node: CanonicalJSONNode,
    depth: Int,
    into output: inout [UInt8]
  ) throws {
    guard depth <= maximumDepth else {
      throw CanonicalMemoryJSONError("Превышена максимальная глубина JSON.")
    }
    if let failure = node.failure {
      throw failure
    }
    guard let value = node.value else {
      throw CanonicalMemoryJSONError("Кодировщик не сформировал значение JSON.")
    }

    switch value {
    case .object(let storage):
      if let failure = storage.failure {
        throw failure
      }
      output.append(UInt8(ascii: "{"))
      let keys = storage.values.keys.sorted()
      for (index, key) in keys.enumerated() {
        guard isMemberName(key) else {
          throw CanonicalMemoryJSONError(
            "Имя поля должно соответствовать ASCII-шаблону [a-z][a-z0-9_]*."
          )
        }
        if index > 0 {
          output.append(UInt8(ascii: ","))
        }
        try serializeString(key, into: &output)
        output.append(UInt8(ascii: ":"))
        guard let child = storage.values[key] else {
          throw CanonicalMemoryJSONError("Кодировщик потерял поле объекта.")
        }
        try serialize(child, depth: depth + 1, into: &output)
      }
      output.append(UInt8(ascii: "}"))
    case .array(let storage):
      output.append(UInt8(ascii: "["))
      for (index, child) in storage.values.enumerated() {
        if index > 0 {
          output.append(UInt8(ascii: ","))
        }
        try serialize(child, depth: depth + 1, into: &output)
      }
      output.append(UInt8(ascii: "]"))
    case .string(let string):
      try serializeString(string, into: &output)
    case .integer(let integer):
      output.append(contentsOf: integer.utf8)
    case .boolean(let boolean):
      output.append(contentsOf: boolean ? "true".utf8 : "false".utf8)
    }
  }

  private static func serializeString(_ string: String, into output: inout [UInt8]) throws {
    try validateUnicode(string)
    output.append(UInt8(ascii: "\""))
    let hexadecimal = Array("0123456789abcdef".utf8)
    for scalar in string.unicodeScalars {
      switch scalar.value {
      case 0x08:
        output.append(contentsOf: "\\b".utf8)
      case 0x09:
        output.append(contentsOf: "\\t".utf8)
      case 0x0a:
        output.append(contentsOf: "\\n".utf8)
      case 0x0c:
        output.append(contentsOf: "\\f".utf8)
      case 0x0d:
        output.append(contentsOf: "\\r".utf8)
      case 0x00...0x1f:
        output.append(contentsOf: "\\u00".utf8)
        output.append(hexadecimal[Int((scalar.value >> 4) & 0x0f)])
        output.append(hexadecimal[Int(scalar.value & 0x0f)])
      case 0x22:
        output.append(contentsOf: "\\\"".utf8)
      case 0x5c:
        output.append(contentsOf: "\\\\".utf8)
      default:
        output.append(contentsOf: String(scalar).utf8)
      }
    }
    output.append(UInt8(ascii: "\""))
  }

  fileprivate static func validateUnicode(_ string: String) throws {
    for scalar in string.unicodeScalars where isNoncharacter(scalar.value) {
      throw CanonicalMemoryJSONError("Строка содержит запрещённую Unicode noncharacter code point.")
    }
  }

  private static func isNoncharacter(_ value: UInt32) -> Bool {
    (0xfdd0...0xfdef).contains(value)
      || (value & 0xffff == 0xfffe)
      || (value & 0xffff == 0xffff)
  }

  fileprivate static func isMemberName(_ value: String) -> Bool {
    let bytes = Array(value.utf8)
    guard let first = bytes.first, (0x61...0x7a).contains(first) else {
      return false
    }
    return bytes.dropFirst().allSatisfy {
      (0x61...0x7a).contains($0) || (0x30...0x39).contains($0) || $0 == 0x5f
    }
  }

  fileprivate static func signedInteger(_ value: Int64) throws -> String {
    guard (0...maximumSafeInteger).contains(value) else {
      throw CanonicalMemoryJSONError(
        "Профиль памяти допускает только целые числа от 0 до \(maximumSafeInteger)."
      )
    }
    return String(value)
  }

  fileprivate static func unsignedInteger(_ value: UInt64) throws -> String {
    guard value <= UInt64(maximumSafeInteger) else {
      throw CanonicalMemoryJSONError(
        "Профиль памяти допускает только целые числа от 0 до \(maximumSafeInteger)."
      )
    }
    return String(value)
  }
}

private indirect enum CanonicalJSONValue {
  case object(CanonicalJSONObjectStorage)
  case array(CanonicalJSONArrayStorage)
  case string(String)
  case integer(String)
  case boolean(Bool)
}

private final class CanonicalJSONNode {
  var value: CanonicalJSONValue?
  var failure: CanonicalMemoryJSONError?
}

private final class CanonicalJSONObjectStorage {
  var values: [String: CanonicalJSONNode] = [:]
  var failure: CanonicalMemoryJSONError?
}

private final class CanonicalJSONArrayStorage {
  var values: [CanonicalJSONNode] = []
}

private final class CanonicalJSONEncoder: Encoder {
  let node: CanonicalJSONNode
  let codingPath: [any CodingKey]
  let userInfo: [CodingUserInfoKey: Any] = [:]

  init(node: CanonicalJSONNode, codingPath: [any CodingKey]) {
    self.node = node
    self.codingPath = codingPath
  }

  func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key>
  where Key: CodingKey {
    let storage: CanonicalJSONObjectStorage
    if case .object(let existing) = node.value {
      storage = existing
    } else if node.value == nil {
      storage = CanonicalJSONObjectStorage()
      node.value = .object(storage)
    } else {
      storage = CanonicalJSONObjectStorage()
      node.failure = CanonicalMemoryJSONError("Значение повторно закодировано как объект.")
    }
    return KeyedEncodingContainer(
      CanonicalKeyedEncodingContainer<Key>(storage: storage, codingPath: codingPath)
    )
  }

  func unkeyedContainer() -> any UnkeyedEncodingContainer {
    let storage: CanonicalJSONArrayStorage
    if case .array(let existing) = node.value {
      storage = existing
    } else if node.value == nil {
      storage = CanonicalJSONArrayStorage()
      node.value = .array(storage)
    } else {
      storage = CanonicalJSONArrayStorage()
      node.failure = CanonicalMemoryJSONError("Значение повторно закодировано как массив.")
    }
    return CanonicalUnkeyedEncodingContainer(storage: storage, codingPath: codingPath)
  }

  func singleValueContainer() -> any SingleValueEncodingContainer {
    CanonicalSingleValueEncodingContainer(node: node, codingPath: codingPath)
  }
}

private struct CanonicalKeyedEncodingContainer<Key: CodingKey>:
  KeyedEncodingContainerProtocol
{
  let storage: CanonicalJSONObjectStorage
  let codingPath: [any CodingKey]

  mutating func encodeNil(forKey key: Key) throws {
    throw CanonicalMemoryJSONError("Значение null запрещено профилем памяти.")
  }

  mutating func encode(_ value: Bool, forKey key: Key) throws {
    try insert(.boolean(value), forKey: key)
  }

  mutating func encode(_ value: String, forKey key: Key) throws {
    try insert(.string(value), forKey: key)
  }

  mutating func encode(_ value: Double, forKey key: Key) throws { try rejectFloating() }
  mutating func encode(_ value: Float, forKey key: Key) throws { try rejectFloating() }
  mutating func encode(_ value: Int, forKey key: Key) throws {
    try insert(.integer(CanonicalMemoryJSON.signedInteger(Int64(value))), forKey: key)
  }
  mutating func encode(_ value: Int8, forKey key: Key) throws {
    try insert(.integer(CanonicalMemoryJSON.signedInteger(Int64(value))), forKey: key)
  }
  mutating func encode(_ value: Int16, forKey key: Key) throws {
    try insert(.integer(CanonicalMemoryJSON.signedInteger(Int64(value))), forKey: key)
  }
  mutating func encode(_ value: Int32, forKey key: Key) throws {
    try insert(.integer(CanonicalMemoryJSON.signedInteger(Int64(value))), forKey: key)
  }
  mutating func encode(_ value: Int64, forKey key: Key) throws {
    try insert(.integer(CanonicalMemoryJSON.signedInteger(value)), forKey: key)
  }
  mutating func encode(_ value: UInt, forKey key: Key) throws {
    try insert(.integer(CanonicalMemoryJSON.unsignedInteger(UInt64(value))), forKey: key)
  }
  mutating func encode(_ value: UInt8, forKey key: Key) throws {
    try insert(.integer(CanonicalMemoryJSON.unsignedInteger(UInt64(value))), forKey: key)
  }
  mutating func encode(_ value: UInt16, forKey key: Key) throws {
    try insert(.integer(CanonicalMemoryJSON.unsignedInteger(UInt64(value))), forKey: key)
  }
  mutating func encode(_ value: UInt32, forKey key: Key) throws {
    try insert(.integer(CanonicalMemoryJSON.unsignedInteger(UInt64(value))), forKey: key)
  }
  mutating func encode(_ value: UInt64, forKey key: Key) throws {
    try insert(.integer(CanonicalMemoryJSON.unsignedInteger(value)), forKey: key)
  }

  mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
    let node = try insertNode(forKey: key)
    try value.encode(to: CanonicalJSONEncoder(node: node, codingPath: codingPath + [key]))
  }

  mutating func nestedContainer<NestedKey>(
    keyedBy keyType: NestedKey.Type,
    forKey key: Key
  ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
    let node: CanonicalJSONNode
    do {
      node = try insertNode(forKey: key)
    } catch let error as CanonicalMemoryJSONError {
      storage.failure = error
      node = CanonicalJSONNode()
      node.failure = error
    } catch {
      storage.failure = CanonicalMemoryJSONError("Не удалось создать вложенный объект.")
      node = CanonicalJSONNode()
      node.failure = storage.failure
    }
    return CanonicalJSONEncoder(node: node, codingPath: codingPath + [key])
      .container(keyedBy: keyType)
  }

  mutating func nestedUnkeyedContainer(forKey key: Key) -> any UnkeyedEncodingContainer {
    let node: CanonicalJSONNode
    do {
      node = try insertNode(forKey: key)
    } catch let error as CanonicalMemoryJSONError {
      storage.failure = error
      node = CanonicalJSONNode()
      node.failure = error
    } catch {
      storage.failure = CanonicalMemoryJSONError("Не удалось создать вложенный массив.")
      node = CanonicalJSONNode()
      node.failure = storage.failure
    }
    return CanonicalJSONEncoder(node: node, codingPath: codingPath + [key]).unkeyedContainer()
  }

  mutating func superEncoder() -> any Encoder {
    let key = CanonicalLiteralKey(stringValue: "super")
    let node: CanonicalJSONNode
    do {
      node = try insertNode(named: key.stringValue)
    } catch let error as CanonicalMemoryJSONError {
      storage.failure = error
      node = CanonicalJSONNode()
      node.failure = error
    } catch {
      storage.failure = CanonicalMemoryJSONError("Не удалось создать super-объект.")
      node = CanonicalJSONNode()
      node.failure = storage.failure
    }
    return CanonicalJSONEncoder(node: node, codingPath: codingPath + [key])
  }

  mutating func superEncoder(forKey key: Key) -> any Encoder {
    let node: CanonicalJSONNode
    do {
      node = try insertNode(forKey: key)
    } catch let error as CanonicalMemoryJSONError {
      storage.failure = error
      node = CanonicalJSONNode()
      node.failure = error
    } catch {
      storage.failure = CanonicalMemoryJSONError("Не удалось создать super-объект.")
      node = CanonicalJSONNode()
      node.failure = storage.failure
    }
    return CanonicalJSONEncoder(node: node, codingPath: codingPath + [key])
  }

  private func insert(_ value: CanonicalJSONValue, forKey key: Key) throws {
    let node = try insertNode(forKey: key)
    node.value = value
  }

  private func insertNode(forKey key: Key) throws -> CanonicalJSONNode {
    try insertNode(named: key.stringValue)
  }

  private func insertNode(named name: String) throws -> CanonicalJSONNode {
    guard CanonicalMemoryJSON.isMemberName(name) else {
      throw CanonicalMemoryJSONError(
        "Имя поля должно соответствовать ASCII-шаблону [a-z][a-z0-9_]*."
      )
    }
    guard storage.values[name] == nil else {
      throw CanonicalMemoryJSONError("Объект содержит повторное поле \(name).")
    }
    let node = CanonicalJSONNode()
    storage.values[name] = node
    return node
  }

  private func rejectFloating() throws {
    throw CanonicalMemoryJSONError("Дробные числа и числа с экспонентой запрещены профилем памяти.")
  }
}

private struct CanonicalUnkeyedEncodingContainer: UnkeyedEncodingContainer {
  let storage: CanonicalJSONArrayStorage
  let codingPath: [any CodingKey]
  var count: Int { storage.values.count }

  mutating func encodeNil() throws {
    throw CanonicalMemoryJSONError("Значение null запрещено профилем памяти.")
  }

  mutating func encode(_ value: Bool) throws { append(.boolean(value)) }
  mutating func encode(_ value: String) throws { append(.string(value)) }
  mutating func encode(_ value: Double) throws { try rejectFloating() }
  mutating func encode(_ value: Float) throws { try rejectFloating() }
  mutating func encode(_ value: Int) throws {
    append(.integer(try CanonicalMemoryJSON.signedInteger(Int64(value))))
  }
  mutating func encode(_ value: Int8) throws {
    append(.integer(try CanonicalMemoryJSON.signedInteger(Int64(value))))
  }
  mutating func encode(_ value: Int16) throws {
    append(.integer(try CanonicalMemoryJSON.signedInteger(Int64(value))))
  }
  mutating func encode(_ value: Int32) throws {
    append(.integer(try CanonicalMemoryJSON.signedInteger(Int64(value))))
  }
  mutating func encode(_ value: Int64) throws {
    append(.integer(try CanonicalMemoryJSON.signedInteger(value)))
  }
  mutating func encode(_ value: UInt) throws {
    append(.integer(try CanonicalMemoryJSON.unsignedInteger(UInt64(value))))
  }
  mutating func encode(_ value: UInt8) throws {
    append(.integer(try CanonicalMemoryJSON.unsignedInteger(UInt64(value))))
  }
  mutating func encode(_ value: UInt16) throws {
    append(.integer(try CanonicalMemoryJSON.unsignedInteger(UInt64(value))))
  }
  mutating func encode(_ value: UInt32) throws {
    append(.integer(try CanonicalMemoryJSON.unsignedInteger(UInt64(value))))
  }
  mutating func encode(_ value: UInt64) throws {
    append(.integer(try CanonicalMemoryJSON.unsignedInteger(value)))
  }

  mutating func encode<T>(_ value: T) throws where T: Encodable {
    let node = appendNode()
    try value.encode(
      to: CanonicalJSONEncoder(
        node: node,
        codingPath: codingPath + [CanonicalIndexKey(index: count - 1)]
      )
    )
  }

  mutating func nestedContainer<NestedKey>(
    keyedBy keyType: NestedKey.Type
  ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
    let index = count
    let node = appendNode()
    return CanonicalJSONEncoder(
      node: node,
      codingPath: codingPath + [CanonicalIndexKey(index: index)]
    ).container(keyedBy: keyType)
  }

  mutating func nestedUnkeyedContainer() -> any UnkeyedEncodingContainer {
    let index = count
    let node = appendNode()
    return CanonicalJSONEncoder(
      node: node,
      codingPath: codingPath + [CanonicalIndexKey(index: index)]
    ).unkeyedContainer()
  }

  mutating func superEncoder() -> any Encoder {
    let index = count
    let node = appendNode()
    return CanonicalJSONEncoder(
      node: node,
      codingPath: codingPath + [CanonicalIndexKey(index: index)]
    )
  }

  private func append(_ value: CanonicalJSONValue) {
    let node = appendNode()
    node.value = value
  }

  private func appendNode() -> CanonicalJSONNode {
    let node = CanonicalJSONNode()
    storage.values.append(node)
    return node
  }

  private func rejectFloating() throws {
    throw CanonicalMemoryJSONError("Дробные числа и числа с экспонентой запрещены профилем памяти.")
  }
}

private struct CanonicalSingleValueEncodingContainer: SingleValueEncodingContainer {
  let node: CanonicalJSONNode
  let codingPath: [any CodingKey]

  func encodeNil() throws {
    throw CanonicalMemoryJSONError("Значение null запрещено профилем памяти.")
  }

  func encode(_ value: Bool) throws { try set(.boolean(value)) }
  func encode(_ value: String) throws { try set(.string(value)) }
  func encode(_ value: Double) throws { try rejectFloating() }
  func encode(_ value: Float) throws { try rejectFloating() }
  func encode(_ value: Int) throws {
    try set(.integer(CanonicalMemoryJSON.signedInteger(Int64(value))))
  }
  func encode(_ value: Int8) throws {
    try set(.integer(CanonicalMemoryJSON.signedInteger(Int64(value))))
  }
  func encode(_ value: Int16) throws {
    try set(.integer(CanonicalMemoryJSON.signedInteger(Int64(value))))
  }
  func encode(_ value: Int32) throws {
    try set(.integer(CanonicalMemoryJSON.signedInteger(Int64(value))))
  }
  func encode(_ value: Int64) throws {
    try set(.integer(CanonicalMemoryJSON.signedInteger(value)))
  }
  func encode(_ value: UInt) throws {
    try set(.integer(CanonicalMemoryJSON.unsignedInteger(UInt64(value))))
  }
  func encode(_ value: UInt8) throws {
    try set(.integer(CanonicalMemoryJSON.unsignedInteger(UInt64(value))))
  }
  func encode(_ value: UInt16) throws {
    try set(.integer(CanonicalMemoryJSON.unsignedInteger(UInt64(value))))
  }
  func encode(_ value: UInt32) throws {
    try set(.integer(CanonicalMemoryJSON.unsignedInteger(UInt64(value))))
  }
  func encode(_ value: UInt64) throws {
    try set(.integer(CanonicalMemoryJSON.unsignedInteger(value)))
  }

  func encode<T>(_ value: T) throws where T: Encodable {
    guard node.value == nil else {
      throw CanonicalMemoryJSONError("Одно значение закодировано повторно.")
    }
    try value.encode(to: CanonicalJSONEncoder(node: node, codingPath: codingPath))
  }

  private func set(_ value: CanonicalJSONValue) throws {
    guard node.value == nil else {
      throw CanonicalMemoryJSONError("Одно значение закодировано повторно.")
    }
    node.value = value
  }

  private func rejectFloating() throws {
    throw CanonicalMemoryJSONError("Дробные числа и числа с экспонентой запрещены профилем памяти.")
  }
}

private struct CanonicalIndexKey: CodingKey {
  let intValue: Int?
  let stringValue: String

  init(index: Int) {
    intValue = index
    stringValue = String(index)
  }

  init?(intValue: Int) {
    self.init(index: intValue)
  }

  init?(stringValue: String) {
    guard let index = Int(stringValue) else { return nil }
    self.init(index: index)
  }
}

private struct CanonicalLiteralKey: CodingKey {
  let intValue: Int? = nil
  let stringValue: String

  init(stringValue: String) {
    self.stringValue = stringValue
  }

  init?(intValue: Int) {
    return nil
  }
}

private struct CanonicalJSONParser {
  let bytes: [UInt8]
  var index = 0

  mutating func parse() throws -> CanonicalJSONNode {
    skipWhitespace()
    let root = try parseValue(depth: 0)
    skipWhitespace()
    guard index == bytes.count else {
      throw CanonicalMemoryJSONError("После JSON-значения остались лишние байты.")
    }
    guard case .object = root.value else {
      throw CanonicalMemoryJSONError("Верхний уровень канонической памяти должен быть объектом.")
    }
    return root
  }

  private mutating func parseValue(depth: Int) throws -> CanonicalJSONNode {
    guard depth <= CanonicalMemoryJSON.maximumDepth else {
      throw CanonicalMemoryJSONError("Превышена максимальная глубина JSON.")
    }
    guard let byte = peek() else {
      throw CanonicalMemoryJSONError("JSON неожиданно завершился.")
    }
    switch byte {
    case UInt8(ascii: "{"):
      return try parseObject(depth: depth + 1)
    case UInt8(ascii: "["):
      return try parseArray(depth: depth + 1)
    case UInt8(ascii: "\""):
      return node(.string(try parseString()))
    case UInt8(ascii: "t"):
      try consume("true")
      return node(.boolean(true))
    case UInt8(ascii: "f"):
      try consume("false")
      return node(.boolean(false))
    case UInt8(ascii: "n"):
      try consume("null")
      throw CanonicalMemoryJSONError("Значение null запрещено профилем памяти.")
    case UInt8(ascii: "-"), UInt8(ascii: "0")...UInt8(ascii: "9"):
      return node(.integer(try parseInteger()))
    default:
      throw CanonicalMemoryJSONError("Недопустимое JSON-значение.")
    }
  }

  private mutating func parseObject(depth: Int) throws -> CanonicalJSONNode {
    try expect(UInt8(ascii: "{"))
    skipWhitespace()
    let storage = CanonicalJSONObjectStorage()
    if take(UInt8(ascii: "}")) {
      return node(.object(storage))
    }
    while true {
      guard peek() == UInt8(ascii: "\"") else {
        throw CanonicalMemoryJSONError("Имя поля JSON должно быть строкой.")
      }
      let key = try parseString()
      guard CanonicalMemoryJSON.isMemberName(key) else {
        throw CanonicalMemoryJSONError(
          "Имя поля должно соответствовать ASCII-шаблону [a-z][a-z0-9_]*."
        )
      }
      guard storage.values[key] == nil else {
        throw CanonicalMemoryJSONError("Объект содержит повторное поле \(key).")
      }
      skipWhitespace()
      try expect(UInt8(ascii: ":"))
      skipWhitespace()
      storage.values[key] = try parseValue(depth: depth)
      skipWhitespace()
      if take(UInt8(ascii: "}")) {
        return node(.object(storage))
      }
      try expect(UInt8(ascii: ","))
      skipWhitespace()
    }
  }

  private mutating func parseArray(depth: Int) throws -> CanonicalJSONNode {
    try expect(UInt8(ascii: "["))
    skipWhitespace()
    let storage = CanonicalJSONArrayStorage()
    if take(UInt8(ascii: "]")) {
      return node(.array(storage))
    }
    while true {
      storage.values.append(try parseValue(depth: depth))
      skipWhitespace()
      if take(UInt8(ascii: "]")) {
        return node(.array(storage))
      }
      try expect(UInt8(ascii: ","))
      skipWhitespace()
    }
  }

  private mutating func parseString() throws -> String {
    try expect(UInt8(ascii: "\""))
    var utf8: [UInt8] = []
    while let byte = peek() {
      index += 1
      switch byte {
      case UInt8(ascii: "\""):
        let string = String(decoding: utf8, as: UTF8.self)
        guard Array(string.utf8) == utf8 else {
          throw CanonicalMemoryJSONError("Строка содержит недопустимую последовательность UTF-8.")
        }
        try CanonicalMemoryJSON.validateUnicode(string)
        return string
      case UInt8(ascii: "\\"):
        try parseEscape(into: &utf8)
      case 0x00...0x1f:
        throw CanonicalMemoryJSONError("Неэкранированный управляющий символ запрещён.")
      default:
        utf8.append(byte)
      }
    }
    throw CanonicalMemoryJSONError("Строка JSON не закрыта.")
  }

  private mutating func parseEscape(into utf8: inout [UInt8]) throws {
    guard let escape = peek() else {
      throw CanonicalMemoryJSONError("Escape-последовательность неожиданно завершилась.")
    }
    index += 1
    switch escape {
    case UInt8(ascii: "\""):
      utf8.append(UInt8(ascii: "\""))
    case UInt8(ascii: "\\"):
      utf8.append(UInt8(ascii: "\\"))
    case UInt8(ascii: "/"):
      utf8.append(UInt8(ascii: "/"))
    case UInt8(ascii: "b"):
      utf8.append(0x08)
    case UInt8(ascii: "f"):
      utf8.append(0x0c)
    case UInt8(ascii: "n"):
      utf8.append(0x0a)
    case UInt8(ascii: "r"):
      utf8.append(0x0d)
    case UInt8(ascii: "t"):
      utf8.append(0x09)
    case UInt8(ascii: "u"):
      let first = try parseHexScalar()
      let scalarValue: UInt32
      if (0xd800...0xdbff).contains(first) {
        try expect(UInt8(ascii: "\\"))
        try expect(UInt8(ascii: "u"))
        let second = try parseHexScalar()
        guard (0xdc00...0xdfff).contains(second) else {
          throw CanonicalMemoryJSONError("Старший суррогат не продолжен младшим.")
        }
        scalarValue = 0x10000 + ((first - 0xd800) << 10) + (second - 0xdc00)
      } else {
        guard !(0xdc00...0xdfff).contains(first) else {
          throw CanonicalMemoryJSONError("Одиночный младший суррогат запрещён.")
        }
        scalarValue = first
      }
      guard let scalar = Unicode.Scalar(scalarValue) else {
        throw CanonicalMemoryJSONError("Escape-последовательность не задаёт Unicode scalar.")
      }
      utf8.append(contentsOf: String(scalar).utf8)
    default:
      throw CanonicalMemoryJSONError("Неизвестная escape-последовательность JSON.")
    }
  }

  private mutating func parseHexScalar() throws -> UInt32 {
    var value: UInt32 = 0
    for _ in 0..<4 {
      guard let byte = peek(), let digit = hexadecimalDigit(byte) else {
        throw CanonicalMemoryJSONError("Unicode escape должен содержать четыре hex-цифры.")
      }
      index += 1
      value = value * 16 + UInt32(digit)
    }
    return value
  }

  private func hexadecimalDigit(_ byte: UInt8) -> UInt8? {
    switch byte {
    case UInt8(ascii: "0")...UInt8(ascii: "9"):
      return byte - UInt8(ascii: "0")
    case UInt8(ascii: "a")...UInt8(ascii: "f"):
      return byte - UInt8(ascii: "a") + 10
    case UInt8(ascii: "A")...UInt8(ascii: "F"):
      return byte - UInt8(ascii: "A") + 10
    default:
      return nil
    }
  }

  private mutating func parseInteger() throws -> String {
    let start = index
    _ = take(UInt8(ascii: "-"))
    guard let first = peek() else {
      throw CanonicalMemoryJSONError("Число неожиданно завершилось.")
    }
    if first == UInt8(ascii: "0") {
      index += 1
      if let next = peek(), (UInt8(ascii: "0")...UInt8(ascii: "9")).contains(next) {
        throw CanonicalMemoryJSONError("Ведущие нули запрещены JSON.")
      }
    } else if (UInt8(ascii: "1")...UInt8(ascii: "9")).contains(first) {
      repeat {
        index += 1
      } while peek().map { (UInt8(ascii: "0")...UInt8(ascii: "9")).contains($0) } == true
    } else {
      throw CanonicalMemoryJSONError("Недопустимая целая часть числа.")
    }
    if let next = peek(),
      next == UInt8(ascii: ".") || next == UInt8(ascii: "e")
        || next == UInt8(ascii: "E")
    {
      throw CanonicalMemoryJSONError(
        "Дробные числа и числа с экспонентой запрещены профилем памяти."
      )
    }
    let text = String(decoding: bytes[start..<index], as: UTF8.self)
    guard text != "-0", let value = Int64(text) else {
      throw CanonicalMemoryJSONError("Целое число имеет запрещённое представление или диапазон.")
    }
    return try CanonicalMemoryJSON.signedInteger(value)
  }

  private mutating func skipWhitespace() {
    while let byte = peek(), byte == 0x20 || byte == 0x09 || byte == 0x0a || byte == 0x0d {
      index += 1
    }
  }

  private mutating func consume(_ literal: String) throws {
    for byte in literal.utf8 {
      try expect(byte)
    }
  }

  private mutating func expect(_ byte: UInt8) throws {
    guard take(byte) else {
      throw CanonicalMemoryJSONError("JSON содержит неожиданный байт.")
    }
  }

  private mutating func take(_ byte: UInt8) -> Bool {
    guard peek() == byte else { return false }
    index += 1
    return true
  }

  private func peek() -> UInt8? {
    index < bytes.count ? bytes[index] : nil
  }

  private func node(_ value: CanonicalJSONValue) -> CanonicalJSONNode {
    let node = CanonicalJSONNode()
    node.value = value
    return node
  }
}

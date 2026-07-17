import CoreFoundation
import FUMInputCore
import Foundation
import IOKit.hid

public struct HIDKeyboardDeviceSummary: Codable, Equatable, Sendable {
  public let deviceID: String
  public let vendorID: Int?
  public let productID: Int?
  public let transport: String?
  public let keyboardElementCount: Int

  public init(
    deviceID: String,
    vendorID: Int?,
    productID: Int?,
    transport: String?,
    keyboardElementCount: Int
  ) {
    self.deviceID = deviceID
    self.vendorID = vendorID
    self.productID = productID
    self.transport = transport
    self.keyboardElementCount = keyboardElementCount
  }
}

public final class IOHIDKeyboardSource: MacKeyboardObservationSource, @unchecked Sendable {
  public let sourceID: InputSourceID = .ioHIDManager

  private var manager: IOHIDManager?
  private var handler: KeyboardObservationHandler?
  private let lock = NSLock()
  private var deviceIDs: [UInt: String] = [:]
  private var nextDeviceIndex = 1

  public init() {}

  public func start(handler: @escaping KeyboardObservationHandler) throws {
    lock.lock()
    defer { lock.unlock() }
    guard manager == nil else {
      throw MacKeyboardSourceError.alreadyRunning
    }

    let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
    IOHIDManagerSetDeviceMatching(manager, Self.keyboardMatchingDictionary)
    IOHIDManagerRegisterInputValueCallback(
      manager,
      iohidInputValueCallback,
      Unmanaged.passUnretained(self).toOpaque()
    )
    IOHIDManagerScheduleWithRunLoop(
      manager,
      CFRunLoopGetCurrent(),
      CFRunLoopMode.defaultMode.rawValue
    )
    let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    guard result == kIOReturnSuccess else {
      IOHIDManagerUnscheduleFromRunLoop(
        manager,
        CFRunLoopGetCurrent(),
        CFRunLoopMode.defaultMode.rawValue
      )
      throw MacKeyboardSourceError.openFailed(
        "IOHIDManagerOpen завершился кодом \(result)"
      )
    }
    self.handler = handler
    self.manager = manager
  }

  public func stop() {
    lock.lock()
    defer { lock.unlock() }
    guard let manager else {
      return
    }
    IOHIDManagerUnscheduleFromRunLoop(
      manager,
      CFRunLoopGetCurrent(),
      CFRunLoopMode.defaultMode.rawValue
    )
    IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    self.manager = nil
    handler = nil
    deviceIDs.removeAll()
    nextDeviceIndex = 1
  }

  fileprivate func receive(_ value: IOHIDValue) {
    let element = IOHIDValueGetElement(value)
    let usagePage = IOHIDElementGetUsagePage(element)
    let usage = IOHIDElementGetUsage(element)
    guard usagePage == 0x07 else {
      return
    }
    let device = IOHIDElementGetDevice(element)
    let deviceID = ephemeralDeviceID(for: device)
    guard
      let observation = IOHIDObservationFactory.keyboardObservation(
        deviceID: deviceID,
        usagePage: usagePage,
        usage: usage,
        integerValue: IOHIDValueGetIntegerValue(value),
        monotonicNanoseconds: IOHIDValueGetTimeStamp(value)
      )
    else {
      return
    }
    handler?(observation)
  }

  private func ephemeralDeviceID(for device: IOHIDDevice) -> String {
    let pointer = UInt(bitPattern: Unmanaged.passUnretained(device).toOpaque())
    if let existing = deviceIDs[pointer] {
      return existing
    }
    let newID = "keyboard-\(nextDeviceIndex)"
    nextDeviceIndex += 1
    deviceIDs[pointer] = newID
    return newID
  }

  public static func inventory() -> [HIDKeyboardDeviceSummary] {
    let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
    IOHIDManagerSetDeviceMatching(manager, keyboardMatchingDictionary)
    let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    guard result == kIOReturnSuccess else {
      return []
    }
    defer {
      IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }
    guard let rawDevices = IOHIDManagerCopyDevices(manager) else {
      return []
    }
    let devices = rawDevices as! Set<IOHIDDevice>
    return
      devices
      .enumerated()
      .map { index, device in
        HIDKeyboardDeviceSummary(
          deviceID: "keyboard-\(index + 1)",
          vendorID: intProperty(kIOHIDVendorIDKey, device: device),
          productID: intProperty(kIOHIDProductIDKey, device: device),
          transport: stringProperty(kIOHIDTransportKey, device: device),
          keyboardElementCount: keyboardElementCount(device: device)
        )
      }
  }

  private static var keyboardMatchingDictionary: CFDictionary {
    [
      kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
      kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Keyboard,
    ] as CFDictionary
  }

  private static func intProperty(_ key: String, device: IOHIDDevice) -> Int? {
    (IOHIDDeviceGetProperty(device, key as CFString) as? NSNumber)?.intValue
  }

  private static func stringProperty(_ key: String, device: IOHIDDevice) -> String? {
    IOHIDDeviceGetProperty(device, key as CFString) as? String
  }

  private static func keyboardElementCount(device: IOHIDDevice) -> Int {
    let matching =
      [
        kIOHIDElementUsagePageKey as String: 0x07
      ] as CFDictionary
    guard
      let elements = IOHIDDeviceCopyMatchingElements(
        device,
        matching,
        IOOptionBits(kIOHIDOptionsTypeNone)
      ) as? [IOHIDElement]
    else {
      return 0
    }
    return elements.count
  }
}

private func iohidInputValueCallback(
  context: UnsafeMutableRawPointer?,
  result: IOReturn,
  sender: UnsafeMutableRawPointer?,
  value: IOHIDValue
) {
  guard result == kIOReturnSuccess, let context else {
    return
  }
  Unmanaged<IOHIDKeyboardSource>
    .fromOpaque(context)
    .takeUnretainedValue()
    .receive(value)
}

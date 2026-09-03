import CoreImage
import Metal

struct ГрафическиеРесурсы {
  let устройство: any MTLDevice
  let очередь: any MTLCommandQueue
  let контекст: CIContext

  static func создать() -> ГрафическиеРесурсы? {
    guard
      let устройство = MTLCreateSystemDefaultDevice(),
      let очередь = устройство.makeCommandQueue()
    else {
      return nil
    }

    return ГрафическиеРесурсы(
      устройство: устройство,
      очередь: очередь,
      контекст: CIContext(mtlDevice: устройство)
    )
  }
}

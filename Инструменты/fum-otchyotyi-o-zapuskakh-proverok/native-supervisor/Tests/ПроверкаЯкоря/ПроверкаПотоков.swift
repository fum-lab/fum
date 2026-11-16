import Darwin
import Dispatch
import Foundation

final class Исходы: @unchecked Sendable {
    private let замок = NSLock()
    private var значения: [Int: (Bool, Int32)] = [:]
    func записать(_ номер: Int, _ запись: Bool, _ закрытие: Int32) {
        замок.lock(); defer { замок.unlock() }; значения[номер] = (запись, закрытие)
    }
    func успех() -> Bool {
        замок.lock(); defer { замок.unlock() }
        return значения.count == 2 && значения.values.allSatisfy { $0.0 && $0.1 == 0 }
    }
}

func проверитьБольшиеПотоки() throws {
        var действие = sigaction()
        действие.__sigaction_u.__sa_handler = SIG_IGN
        guard sigemptyset(&действие.sa_mask) == 0, sigaction(SIGPIPE, &действие, nil) == 0 else { exit(10) }
        var первый = [Int32](repeating: -1, count: 2), второй = первый
        guard pipe(&первый) == 0, pipe(&второй) == 0 else { exit(11) }
        for чтение in [первый[0], второй[0]] {
            let флаги = fcntl(чтение, F_GETFL)
            guard флаги >= 0, fcntl(чтение, F_SETFL, флаги | O_NONBLOCK) == 0 else { exit(12) }
        }
        let группа = DispatchGroup()
        let исходы = Исходы()
        for (номер, пара) in [(первый[1], UInt8(65)), (второй[1], UInt8(66))].enumerated() {
            let (дескриптор, байт) = пара
            группа.enter()
            DispatchQueue.global().async {
                let блок = [UInt8](repeating: байт, count: 4096)
                var записано = true
                for _ in 0..<32 {
                    var смещение = 0
                    while смещение < блок.count {
                        let длина = блок.withUnsafeBytes { write(дескриптор, $0.baseAddress!.advanced(by: смещение), $0.count - смещение) }
                        if длина < 0 && errno == EINTR { continue }
                        if длина <= 0 { записано = false; break }
                        смещение += длина
                    }
                    if !записано { break }
                }
                let закрытие = close(дескриптор)
                исходы.записать(номер, записано, закрытие)
                группа.leave()
            }
        }
        let край = clock_gettime_nsec_np(CLOCK_UPTIME_RAW) + 10_000_000_000
        let получено: [[UInt8]]
        do { получено = try собратьПотоки([первый[0], второй[0]], пределы: [131_072, 131_072], край: край) }
        catch {
            let первоеЗакрытие = close(первый[0]), второеЗакрытие = close(второй[0])
            guard группа.wait(timeout: .now() + 2) == .success, первоеЗакрытие == 0, второеЗакрытие == 0,
                  исходы.успех() else { while true { sleep(1) } }
            throw error
        }
        guard группа.wait(timeout: .now() + 2) == .success else { while true { sleep(1) } }
        let первоеЗакрытие = close(первый[0]), второеЗакрытие = close(второй[0])
        guard исходы.успех(), первоеЗакрытие == 0, второеЗакрытие == 0,
              получено == [[UInt8](repeating: 65, count: 131_072), [UInt8](repeating: 66, count: 131_072)] else { while true { sleep(1) } }
        print("concurrent_A=131072 concurrent_B=131072")
  }

#if canImport(Darwin)
import Darwin

public enum ИтогОпросаДочернегоПроцесса: Equatable, Sendable {
    case нетРезультата
    case собран(pid: Int32, сыройСтатус: Int32)
    case неизвестно(errno: Int32)
}

/// Только единственный владелец непосредственного child вправе вызывать опрос.
/// Повтор последнего результата не повторяет waitpid; сигналы не отправляются.
public final class НаблюдениеДочернегоПроцесса {
    public let pid: Int32
    private var окончательный: ИтогОпросаДочернегоПроцесса?

    public init?(pid: Int32) {
        guard pid > 1, pid != getpid() else { return nil }
        self.pid = pid
    }

    public func опросить() -> ИтогОпросаДочернегоПроцесса {
        if let окончательный { return окончательный }
        var сырой: Int32 = 0
        let результат = waitpid(pid, &сырой, WNOHANG)
        if результат == 0 || (результат == -1 && errno == EINTR) { return .нетРезультата }
        let итог: ИтогОпросаДочернегоПроцесса
        if результат == pid {
            итог = .собран(pid: pid, сыройСтатус: сырой)
        } else {
            итог = .неизвестно(errno: результат == -1 ? errno : EINVAL)
        }
        окончательный = итог
        return итог
    }
}
#endif

import Foundation

enum ФикстурыCodexAppServer {
    static let запросРазрешенияКоманды = "{\"id\":77,\"method\":\"commandExecution/requestApproval\",\"params\":{}}\n"
    static let завершениеХодаА = "{\"method\":\"turn/completed\",\"params\":{\"turn\":{\"id\":\"turn_a\",\"status\":\"completed\"}}}\n"
    static let завершениеХодаОтменено = "{\"method\":\"turn/completed\",\"params\":{\"turn\":{\"id\":\"turn_cancel\",\"status\":\"interrupted\"}}}\n"
}

import XCTest
@testable import ЯдроМашины

final class ПроверкиНастройкиГостя: XCTestCase {
    func testSSHЗакреплёнИГотовностьНеЗапускаетсяВнутриCloudInit() throws {
        let текст = try НастройкаГостя.создать(идентификатор: "12345678-1234-4234-8234-123456789abc",
            ключКлиента: "ssh-ed25519 AAAACLIENT", ключХоста: "ssh-ed25519 AAAAHOST", закрытыйКлючХоста: "ОТКРЫТАЯ-ФИКСТУРА\n")
        XCTAssertTrue(текст.contains("#cloud-config"))
        XCTAssertTrue(текст.contains("ssh_pwauth: false"))
        XCTAssertTrue(текст.contains("ed25519_private:"))
        XCTAssertTrue(текст.contains("VSOCK-LISTEN:2222,fork"))
        XCTAssertTrue(текст.contains("socat"))
        XCTAssertFalse(текст.contains("cloud-init status --wait"))
        XCTAssertFalse(текст.contains("After=cloud-init.target"))
    }
    func testДанныеНеМогутВнедритьДругуюНастройку() {
        XCTAssertThrowsError(try НастройкаГостя.создать(идентификатор: "x\nruncmd: []", ключКлиента: "x", ключХоста: "x", закрытыйКлючХоста: "x"))
    }
}

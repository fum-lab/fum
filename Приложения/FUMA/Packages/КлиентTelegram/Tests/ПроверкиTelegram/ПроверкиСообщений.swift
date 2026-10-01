import Foundation
import Testing
@testable import КлиентTelegram

@Test(arguments: ["updateNewMessage", "updateMessageContent", "updateMessageEdited", "updateDeleteMessages"])
func позднееОбновлениеНеВозвращаетЗаменённуюИдентичность(_ тип: String) throws {
    var модель = МодельСообщений()
    let успех = ЗначениеДанных.типа("updateMessageSendSucceeded", ["old_message_id": .число(101),
        "message": сообщениеПримера(10001, тип: "messageText")])
    let позднее: ЗначениеДанных
    switch тип {
    case "updateNewMessage": позднее = .типа(тип, ["message": сообщениеПримера(101, тип: "messageText", ожидает: true)])
    case "updateMessageContent": позднее = .типа(тип, ["chat_id": .число(-100001), "message_id": .число(101),
        "new_content": .типа("messageText")])
    case "updateMessageEdited": позднее = .типа(тип, ["chat_id": .число(-100001), "message_id": .число(101), "edit_date": .число(1)])
    default: позднее = .типа(тип, ["chat_id": .число(-100001), "message_ids": .массив([.число(101)]),
        "is_permanent": .флаг(true), "from_cache": .флаг(false)])
    }
    try модель.применить(успех, аккаунт: 17)
    try модель.применить(позднее, аккаунт: 17)
    let старый = ИдентичностьСообщения(аккаунт: 17, чат: -100001, сообщение: 101)
    let новый = ИдентичностьСообщения(аккаунт: 17, чат: -100001, сообщение: 10001)
    #expect(модель.сообщения[старый] == nil)
    #expect(модель.сообщения[новый]?.данные == сообщениеПримера(10001, тип: "messageText"))
    #expect(модель.сообщения.count == 1)
    #expect(модель.история.map(\.событие) == [успех, позднее])
    var повтор = МодельСообщений()
    for наблюдение in модель.история { try повтор.применить(наблюдение.событие, аккаунт: наблюдение.аккаунт) }
    #expect(повтор.сообщения[старый] == nil)
    #expect(повтор.сообщения == модель.сообщения)
    if тип == "updateMessageContent" || тип == "updateMessageEdited" {
        let неверное = ЗначениеДанных.типа(тип, ["chat_id": .число(-100001), "message_id": .число(101), "edit_date": .число(-1)])
        #expect(throws: ОшибкаКлиента.self) { try модель.применить(неверное, аккаунт: 17) }
        #expect(модель.история.count == 2)
    }
}

@Test func идентичностьПорядокПовторыПравкиИВидыУдаления() throws {
    var модель = МодельСообщений()
    let сообщение = ЗначениеДанных.типа("message", ["chat_id": .число(-100001), "id": .число(1048576),
        "content": .типа("messageText", ["text": .типа("formattedText", ["text": .текст("Одинаковый текст")])])])
    let новое = ЗначениеДанных.типа("updateNewMessage", ["message": сообщение])
    try модель.применить(новое, аккаунт: 17)
    try модель.применить(новое, аккаунт: 17)
    try модель.применить(новое, аккаунт: 18)
    try модель.применить(.типа("updateNewMessage", ["message": сообщение.добавив("id", .число(2097152))]), аккаунт: 17)
    #expect(модель.сообщения.count == 3)
    #expect(модель.история.count == 4)
    let ключ = ИдентичностьСообщения(аккаунт: 17, чат: -100001, сообщение: 1048576)
    try модель.применить(.типа("updateMessageContent", ["chat_id": .число(-100001), "message_id": .число(1048576),
        "new_content": .типа("messageText", ["text": .типа("formattedText", ["text": .текст("Правка")])])]), аккаунт: 17)
    #expect(модель.сообщения[ключ]?.данные["content"]?["text"]?["text"]?.строка == "Правка")
    let очистка = ЗначениеДанных.типа("updateDeleteMessages", ["chat_id": .число(-100001),
        "message_ids": .массив([.число(1048576)]), "is_permanent": .флаг(false), "from_cache": .флаг(true)])
    try модель.применить(очистка, аккаунт: 17)
    #expect(модель.сообщения[ключ]?.очищенКэш == true)
    #expect(модель.сообщения[ключ]?.удалено == false)
    try модель.применить(очистка.добавив("is_permanent", .флаг(true)), аккаунт: 17)
    #expect(модель.сообщения[ключ]?.удалено == true)
    #expect(модель.история.map(\.порядок) == Array(1...7))
}

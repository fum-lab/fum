//
//  KeyboardLayout.swift
//  Keyboard
//
//  Created by Roman Kerimov on 2016-11-08.
//
//

import Foundation

public struct KeyboardLayout: Equatable, Identifiable, RawRepresentable {
    public static func == (lhs: KeyboardLayout, rhs: KeyboardLayout) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
    
    public var rawValue: String {
        get {
            name
        }
    }
    
    public init?(rawValue: String) {
        if let layout = Self.allLayouts.first(where: {$0.rawValue == rawValue}) {
            self = layout
        } else {
            return nil
        }
    }
    
    public var id: String {
        return name
    }
    
    public let name: String
    public let inputSourceID: String
    
    private var characterComponents: [CharacterComponent] = Array(repeating: .none, count: Keycode.keycodeMaxCount)
    
    func characterComponent(fromKeycode keycode: Keycode) -> CharacterComponent {characterComponents[keycode]}
    
    public func contain(_ key: Key) -> Bool {characterComponents[key.keycode] != .none || key == .enter}
    
    var components: Set<CharacterComponent> {
        Set(
            characterComponents
            + KeyboardLayout.option.characterComponents
            + KeyboardLayout.shiftUpDictionary.values
            + [.space]
        )
    }
    
    init(
        name: String = "",
        rows: [[CharacterComponent]] = Array(
            repeating: Array(
                repeating: .zero,
                count: Key.layoutBoardColumnCount
            ),
            count: Key.layoutBoardRowCount), defaultInputSourceID: String = ""
    ) {
        self.name = name
        
        for (characterComponentRow, keyRow) in zip(rows, Key.layoutBoard) {
            for (characterComponent, key) in zip(characterComponentRow, keyRow) {
                characterComponents[key.keycode] = characterComponent
            }
        }
        
        characterComponents[Key.space.keycode] = .space
        
        self.inputSourceID = defaultInputSourceID
    }
    
    public static let system = KeyboardLayout(
        name: "System"
    )
    
    static let option = KeyboardLayout(
        rows: [
            [.asterisk,     .apostrophe,    .ampersand,       .verticalLine, .tilde,   .divisionSign,       .seven, .eight, .nine,  .minusSign, ],
            [.commercialAt, .numberSign,    .dollarSign,      .percentSign,  .caret,   .multiplicationSign, .four,  .five,  .six,   .plusSign,  ],
            [.curlyBracket, .squareBracket, .leftParenthesis, .lessThanSign, .solidus, .zero,               .one,   .two,   .three, .equalsSign,],
        ]
    )
    
    static let shiftUpDictionary: [CharacterComponent: CharacterComponent] = [
        .fullStop: .colon,
        .comma: .semicolon,
        .questionMark: .exclamationMark,
        .apostrophe: .quotationMark,
        .hyphen: .lowLine,
    ]
    
    static let shiftRightDictionary: [CharacterComponent: CharacterComponent] = [
        .lessThanSign: .greaterThanSign,
        .leftParenthesis: .rightParenthesis,
        .commercialAt: .degree,
    ]
    
    static let reversedShiftRightDictionary = Dictionary(uniqueKeysWithValues: shiftRightDictionary.map {($1, $0)})
}

public extension Array where Element == KeyboardLayout {
    func element(inputSourceID: String) -> Element {
        guard let index = self.map( {$0.inputSourceID} ).firstIndex(of: inputSourceID) else {
            return .system
        }
        
        return self[index]
    }
}

//
//  Key.swift
//  Keyboard
//
//  Created by Roman Kerimov on 2018-01-12.
//

import Foundation

public final class Key: Identifiable, ObservableObject {
    public var id: Keycode {keycode}
    
    public let keycode: Keycode
    
    private init(keycode: Keycode) {
        self.keycode = keycode
    }
    
    @Published public var isEnabled = true
    @Published public var isHighlighted = false
    
    static let keys: [Key] = (0..<Keycode.keycodeMaxCount).map {Key(keycode: $0)}
    
    public static func by(keycode: Keycode) -> Key {keys[keycode]}
    
    static let keysByLabel: [String: Key] = Dictionary(
        uniqueKeysWithValues: keys
            .filter {!$0.label.isEmpty && !Key.specialKeys.contains($0)}
            .map {($0.label, $0)}
    )
    
    static func by(labelCharacter: Character) -> Key? {
        guard let key = keysByLabel[labelCharacter.description] else {
            return nil
        }
        
        return key
    }
    
    static let keysByShiftUpLabel: [String: Key] = Dictionary(
        uniqueKeysWithValues: keys
            .filter {!$0.shiftUpLabel.isEmpty}
            .map {($0.shiftUpLabel, $0)}
    )
    
    static func by(shiftUpLabelCharacter: Character) -> Key? {
        guard let key = keysByShiftUpLabel[shiftUpLabelCharacter.description] else {
            return nil
        }
        
        return key
    }
    
    static let keysByShiftDownLabel: [String: Key] = Dictionary(
        uniqueKeysWithValues: keys
            .filter {!$0.shiftDownLabel.isEmpty}
            .map {($0.shiftDownLabel.first!.description, $0)}
    )
    
    static func by(shiftDownLabelCharacter: Character) -> Key? {
        guard let key = keysByShiftDownLabel[shiftDownLabelCharacter.description] else {
            return nil
        }
        
        return key
    }
    
    private var mainComponent: CharacterComponent {
        Keyboard.default.previewLayout.characterComponent(fromKeycode: keycode)
    }
    
    public var label: String {
        
        #if canImport(Carbon)
        if Keyboard.default.previewLayout == .system {
            return keycode.label(flags: [])
        }
        #endif
        
        switch self {
        case .delete:
            return "delete"
        case .tab:
            return "tab"
        case .capsLock:
            return "complete"
        case .enter:
            return "enter"
        case .leftShift, .rightShift:
            return "shift"
        case .fn:
            return "fn"
        case .leftControl, .rightControl:
            return "control"
        case .leftOption, .rightOption:
            return "option"
        case .leftCommand, .rightCommand:
            return "command"
        case .leftArrow:
            return "←"
        case .upArrow:
            return "↑"
        case .downArrow:
            return "↓"
        case .rightArrow:
            return "→"
        case .nextKeyboard:
            return "NextKeyboard"
        case .dismissKeyboard:
            return "HideKeyboard"
        case .settings:
            return "Settings"
        default:
            return [mainComponent].character
        }
    }
    
    public var mainLabel: String {
        Keyboard.default.currentKey == self ? Keyboard.default.currentLabel : label
    }
    
    public var shiftDownLabel: String {
        
        let shiftDownCharacterComponent = KeyboardLayout.option.characterComponent(fromKeycode: keycode)
        
        let extraRightCharacter = [KeyboardLayout.shiftRightDictionary[shiftDownCharacterComponent]]
            .compactMap {$0}
            .character
        
        return [shiftDownCharacterComponent].character + extraRightCharacter + [shiftDownCharacterComponent].extraArray
            .filter {
                $0.contains(.extra0)
                || $0.contains(.extra1)
                || $0.contains(.extra2)
                || $0.contains(.reversed)
            }
            .map(\.character)
            .joined()
    }
    
    public var shiftUpLabel: String {
        if let shiftUpComponent = KeyboardLayout.shiftUpDictionary[mainComponent] {
            return [shiftUpComponent].character
        } else {
            return ""
        }
    }
    
    public var shiftRightLabel: String {
        self == .space ? .tab : ""
    }
    
    public var shiftLeftLabel: String {
        self == .space && Keyboard.default.delegate?.needsReturn != false ? .return : ""
    }
}

// MARK: -  Equatable
extension Key: Equatable {
    public static func == (lhs: Key, rhs: Key) -> Bool {
        lhs.keycode == rhs.keycode
    }
}

// MARK: - Keys
public extension Key {
    
    static let board: [[Key]] = [
        [.grave, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .zero, .hyphenMinus, .equal, .delete],
        [.tab, .q, .w, .e, .r, .t, .y, .u, .i, .o, .p, .leftSquareBracket, .rightSquareBracket, .reverseSolidus],
        [.capsLock, .a, .s, .d, .f, .g, .h, .j, .k, .l, .semicolon, .apostrophe, .enter],
        [.leftShift, .z, .x, .c, .v, .b, .n, .m, .comma, .fullStop, .solidus, .rightShift],
        [.fn, .leftControl, .leftOption, .leftCommand, .space, .rightCommand, .rightOption, .leftArrow, .upArrow, .downArrow, .rightArrow]
    ]
    
    static let arrowKeys: [Key] = [.upArrow, .leftArrow, .downArrow, .rightArrow]
    static let leftSpecialKeys: [Key] = [.tab, .capsLock, .leftShift, .fn, .leftControl, .leftOption, .leftCommand]
    static let rightSpecialKeys: [Key] = [.delete, .enter, .rightShift, .rightControl, .rightOption, .rightCommand]
    static let specialKeys: [Key] = leftSpecialKeys + rightSpecialKeys + arrowKeys
    
    static let layoutBoard: [[Key]] = board[1...3].map {Array($0[1...10])}
    static let leftLayoutBoard: [[Key]] = layoutBoard.map {Array($0.prefix($0.count/2))}
    static let rightLayoutBoard: [[Key]] = layoutBoard.map {Array($0.suffix($0.count/2))}
    static let layoutBoardRowCount = layoutBoard.count
    static let layoutBoardColumnCount = layoutBoard.first!.count
    
    static let esc = keys[53]
    static let f1 = keys[122]
    static let f2 = keys[120]
    static let f3 = keys[99]
    static let f4 = keys[118]
    static let f5 = keys[96]
    static let f6 = keys[97]
    static let f7 = keys[98]
    static let f8 = keys[100]
    static let f9 = keys[101]
    static let f10 = keys[109]
    static let f11 = keys[103]
    static let f12 = keys[111]
    
    static let grave = keys[50]
    static let one = keys[18]
    static let two = keys[19]
    static let three = keys[20]
    static let four = keys[21]
    static let five = keys[23]
    static let six = keys[22]
    static let seven = keys[26]
    static let eight = keys[28]
    static let nine = keys[25]
    static let zero = keys[29]
    static let hyphenMinus = keys[27]
    static let equal = keys[24]
    static let delete = keys[51]
    
    static let tab = keys[48]
    static let q = keys[12]
    static let w = keys[13]
    static let e = keys[14]
    static let r = keys[15]
    static let t = keys[17]
    static let y = keys[16]
    static let u = keys[32]
    static let i = keys[34]
    static let o = keys[31]
    static let p = keys[35]
    static let leftSquareBracket = keys[33]
    static let rightSquareBracket = keys[30]
    static let reverseSolidus = keys[42]
    
    static let capsLock = keys[57]
    static let a = keys[0]
    static let s = keys[1]
    static let d = keys[2]
    static let f = keys[3]
    static let g = keys[5]
    static let h = keys[4]
    static let j = keys[38]
    static let k = keys[40]
    static let l = keys[37]
    static let semicolon = keys[41]
    static let apostrophe = keys[39]
    static let enter = keys[36]
    
    static let leftShift = keys[56]
    static let z = keys[6]
    static let x = keys[7]
    static let c = keys[8]
    static let v = keys[9]
    static let b = keys[11]
    static let n = keys[45]
    static let m = keys[46]
    static let comma = keys[43]
    static let fullStop = keys[47]
    static let solidus = keys[44]
    static let rightShift = keys[60]
    
    static let fn = keys[63]
    static let leftControl = keys[59]
    static let leftOption = keys[58]
    static let leftCommand = keys[55]
    static let space = keys[49]
    static let rightCommand = keys[54]
    static let rightOption = keys[61]
    static let rightControl = keys[62]
    
    static let upArrow = keys[126]
    static let leftArrow = keys[123]
    static let downArrow = keys[125]
    static let rightArrow = keys[124]
    
    
    static let f13 = keys[105]
    static let f14 = keys[107]
    static let f15 = keys[113]
    static let f16 = keys[106]
    static let f17 = keys[64]
    static let f18 = keys[79]
    static let f19 = keys[80]
    static let f20 = keys[90]
    
    static let forwardDelete = keys[117]
    
    static let home = keys[115]
    static let end = keys[119]
    
    static let pageUp = keys[116]
    static let pageDown = keys[121]
    
    static let keypad0 = keys[82]
    static let keypad1 = keys[83]
    static let keypad2 = keys[84]
    static let keypad3 = keys[85]
    static let keypad4 = keys[86]
    static let keypad5 = keys[87]
    static let keypad6 = keys[88]
    static let keypad7 = keys[89]
    static let keypad8 = keys[91]
    static let keypad9 = keys[92]
    
    static let keypadDecimal = keys[65]
    
    static let keypadPlus = keys[69]
    static let keypadMinus = keys[78]
    static let keypadMultiply = keys[67]
    static let keypadDivide = keys[75]
    static let keypadEquals = keys[81]
    
    static let keypadClear = keys[71]
    static let keypadEnter = keys[76]
    
    
    
    static let settings = keys[256]
    static let nextKeyboard = keys[257]
    static let dismissKeyboard = keys[258]
}

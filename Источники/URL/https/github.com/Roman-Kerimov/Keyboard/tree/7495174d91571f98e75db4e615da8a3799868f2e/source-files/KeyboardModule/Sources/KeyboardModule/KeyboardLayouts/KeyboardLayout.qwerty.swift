//
//  KeyboardLayout.qwerty.swift
//  
//
//  Created by Roman Kerimov on 2020-10-29.
//

extension KeyboardLayout {
    static let qwerty = Self(
        name: "QWERTY",
        rows: [
            [ .q, .w, .e, .r, .t, .y, .u, .i,     .o,        .p,            ],
            [ .a, .s, .d, .f, .g, .h, .j, .k,     .l,        .questionMark, ],
            [ .z, .x, .c, .v, .b, .n, .m, .comma, .fullStop, .hyphen,       ],
        ],
        defaultInputSourceID: "com.apple.keylayout.ABC"
    )
}

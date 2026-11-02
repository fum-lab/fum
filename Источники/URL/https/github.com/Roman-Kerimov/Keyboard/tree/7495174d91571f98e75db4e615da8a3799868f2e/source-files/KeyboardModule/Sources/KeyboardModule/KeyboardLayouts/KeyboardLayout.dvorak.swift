//
//  KeyboardLayout.dvorak.swift
//  
//
//  Created by Roman Kerimov on 2020-10-29.
//

extension KeyboardLayout {
    static let dvorak = KeyboardLayout(
        name: "Dvorak",
        rows: [
            [ .questionMark, .comma, .fullStop, .p, .y, .f, .g, .c, .r, .l, ],
            [ .a,            .o,     .e,        .u, .i, .d, .h, .t, .n, .s, ],
            [ .hyphen,       .q,     .j,        .k, .x, .b, .m, .w, .v, .z, ],
        ],
        defaultInputSourceID: "com.apple.keylayout.DVORAK-QWERTYCMD"
    )
}

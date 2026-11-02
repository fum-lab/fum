//
//  KeyboardLayout.colemak.swift
//  
//
//  Created by Roman Kerimov on 2020-10-29.
//

extension KeyboardLayout {
    static let colemak = KeyboardLayout(
        name: "Colemak",
        rows: [
            [ .q, .w, .f, .p, .g, .j, .l, .u,     .y,        .hyphen,       ],
            [ .a, .r, .s, .t, .d, .h, .n, .e,     .i,        .o,            ],
            [ .z, .x, .c, .v, .b, .k, .m, .comma, .fullStop, .questionMark, ],
        ],
        defaultInputSourceID: "com.apple.keylayout.Colemak"
    )
}

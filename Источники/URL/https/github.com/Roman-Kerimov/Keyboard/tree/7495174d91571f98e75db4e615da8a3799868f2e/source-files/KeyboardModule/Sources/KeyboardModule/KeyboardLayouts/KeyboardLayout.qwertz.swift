//
//  KeyboardLayout.qwertz.swift
//  
//
//  Created by Roman Kerimov on 2020-10-29.
//

extension KeyboardLayout {
    static let qwertz = KeyboardLayout(
        name: "QWERTZ",
        rows: [
            [ .q, .w, .e, .r, .t, .z, .u, .i,     .o,        .p,            ],
            [ .a, .s, .d, .f, .g, .h, .j, .k,     .l,        .questionMark, ],
            [ .y, .x, .c, .v, .b, .n, .m, .comma, .fullStop, .hyphen,       ],
        ],
        defaultInputSourceID: "com.apple.keylayout.ABC-QWERTZ"
    )
}

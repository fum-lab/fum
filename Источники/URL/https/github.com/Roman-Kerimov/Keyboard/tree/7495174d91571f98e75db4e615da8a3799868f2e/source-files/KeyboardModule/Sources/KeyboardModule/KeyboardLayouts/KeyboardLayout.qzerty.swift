//
//  KeyboardLayout.qzerty.swift
//  
//
//  Created by Roman Kerimov on 2020-10-29.
//

extension KeyboardLayout {
    static let qzerty = KeyboardLayout(
        name: "QZERTY",
        rows: [
            [ .q, .z, .e, .r, .t, .y, .u, .i,     .o,        .p,            ],
            [ .a, .s, .d, .f, .g, .h, .j, .k,     .l,        .questionMark, ],
            [ .w, .x, .c, .v, .b, .n, .m, .comma, .fullStop, .hyphen,       ],
        ],
        defaultInputSourceID: "com.apple.keylayout.Italian"
    )
}

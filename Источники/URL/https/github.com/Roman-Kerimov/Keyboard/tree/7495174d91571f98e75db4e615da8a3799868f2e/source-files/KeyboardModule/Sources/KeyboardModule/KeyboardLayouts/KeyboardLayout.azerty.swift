//
//  KeyboardLayout.azerty.swift
//  
//
//  Created by Roman Kerimov on 2020-10-29.
//

extension KeyboardLayout {
    static let azerty = KeyboardLayout(
        name: "AZERTY",
        rows: [
            [ .a, .z, .e, .r, .t, .y, .u,     .i,        .o,            .p,      ],
            [ .q, .s, .d, .f, .g, .h, .j,     .k,        .l,            .m,      ],
            [ .w, .x, .c, .v, .b, .n, .comma, .fullStop, .questionMark, .hyphen, ],
        ],
        defaultInputSourceID: "com.apple.keylayout.ABC-AZERTY"
    )
}

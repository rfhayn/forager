//
//  StoreColorDot.swift
//  forager
//
//  M18.1.4: Small colored dot indicating a grocery item's assigned store.
//

import SwiftUI

struct StoreColorDot: View {
    let hex: String?
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(ForagerTheme.storeColor(hex: hex))
            .frame(width: size, height: size)
    }
}

//
//  CollectionPinnedIndicator.swift
//  Notte
//
//  Created by yuzheyuan on 2026/4/4.
//

import SwiftUI

struct CollectionPinnedIndicator: View {
    var body: some View {
        Image(systemName: "pin.fill")
            .font(.caption2)
            .foregroundStyle(ColorTokens.accent)
    }
}

#Preview {
    CollectionPinnedIndicator()
        .padding()
}

//
//  AddNodeButton.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/25.
//

import SwiftUI

/// 行末的加号按钮，点击后在该节点下创建一个新的子节点。
/// 在 NodeRowView 中悬停或长按时显示，MVP 阶段始终可见。
struct AddNodeButton: View {

    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "plus.circle")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(ColorTokens.textSecondary.opacity(0.6))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

//
//  DebugMenuView.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/28.
//

import SwiftUI

#if DEBUG
struct DebugMenuView: View {
    @Environment(\.modelContext) private var mdoelContext

    var body: some View {
        NavigationStack {
            List {
                Section("数据") {
                    Button("清空所有数据", role: .destructive) {
                        clearAllData()
                    }
                }
            }
            .navigationTitle("调试菜单")
        }
    }

    private func clearAllData() {
        // M6 示例数据功能完成后填充
    }
}
#endif

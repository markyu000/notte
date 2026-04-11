//
//  PageContextMenu.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/11.
//

import SwiftUI

struct PageContextMenu: View {
    let page: Page
    let onRename: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void

    var body: some View {
        Group {
            Button(action: onRename) {
                Label("重命名", systemImage: "pencil")
            }
            Button(action: onDuplicate) {
                Label("复制页面", systemImage: "doc.on.doc")
            }
        }

        Divider()

        Button(role: .destructive, action: onDelete) {
            Label("删除", systemImage: "trash")
        }
    }
}

//
//  CollectionContextMenu.swift
//  Notte
//
//  Created by yuzheyuan on 2026/4/1.
//

import SwiftUI

struct CollectionContextMenu: View {
    let collection: Collection
    let onRename: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Group {
            Button(action: onRename) {
                Label("重命名", systemImage: "pencil")
            }

            Button(action: onPin) {
                Label(
                    collection.isPinned ? "取消固定" : "固定",
                    systemImage: collection.isPinned ? "pin.slash" : "pin"
                )
            }

            Divider()

            Button(role: .destructive, action: onDelete) {
                Label("删除", systemImage: "trash")
            }
        }
    }
}

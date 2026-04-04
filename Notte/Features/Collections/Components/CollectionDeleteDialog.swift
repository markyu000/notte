//
//  CollectionDeleteDialog.swift
//  Notte
//
//  Created by yuzheyuan on 2026/4/4.
//

import SwiftUI

struct CollectionDeleteDialog: View {
    let collectionID: UUID
    @ObservedObject var viewModel: CollectionListViewModel

    var body: some View {
        Group {
            Button("删除", role: .destructive) {
                Task {
                    await viewModel.deleteCollection(id: collectionID)
                }
            }

            Button("取消", role: .cancel) {}
        }
    }
}

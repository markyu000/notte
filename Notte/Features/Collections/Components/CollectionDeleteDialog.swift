//
//  CollectionDeleteDialog.swift
//  Notte
//
//  Created by yuzheyuan on 2026/4/4.
//

import SwiftUI
import SwiftData

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

#Preview {
    let container = try! PersistenceController.makeContainer(inMemory: true)
    let context = ModelContext(container)
    let repo = try! CollectionRepository(context: context)
    let pageRepo = PageRepository(context: context)
    let nodeRepo = NodeRepository(context: context)
    let viewModel = CollectionListViewModel(
        repository: repo,
        pageRepository: pageRepo,
        nodeRepository: nodeRepo
    )
    let collectionID = UUID()

    Text("长按查看对话框")
        .confirmationDialog(
            "确认删除？",
            isPresented: .constant(true),
            titleVisibility: .visible
        ) {
            CollectionDeleteDialog(collectionID: collectionID, viewModel: viewModel)
        }
}

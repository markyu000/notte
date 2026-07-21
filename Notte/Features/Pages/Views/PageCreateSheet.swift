//
//  PageCreateSheet.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/11.
//

import SwiftUI
import SwiftData

struct PageCreateSheet: View {
    @ObservedObject var viewModel: PageListViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Page名称", text: $viewModel.newPageTitle)
                        .focused($isTitleFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            Task { await viewModel.createPage() }
                        }
                }
            }
            .navigationTitle("新建Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        viewModel.newPageTitle = ""
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("创建") {
                        Task { await viewModel.createPage() }
                    }
                    .disabled(viewModel.newPageTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    .tint(ColorTokens.accent)
                }
            }
            .onAppear {
                isTitleFocused = true
            }
        }
        .presentationDetents([.height(220)])
    }
}

#Preview {
    let container = try! PersistenceController.makeContainer(inMemory: true)
    let context = ModelContext(container)
    let normalizationActor = SortIndexNormalizationActor.preview(container: container)
    let pageRepo = PageRepository(context: context, normalizationActor: normalizationActor)
    let nodeRepo = NodeRepository(context: context, normalizationActor: normalizationActor)
    let blockRepo = BlockRepository(context: context, normalizationActor: normalizationActor)
    let viewModel = PageListViewModel(
        collectionID: UUID(),
        collectionTitle: "我的笔记",
        pageRepository: pageRepo,
        nodeRepository: nodeRepo,
        blockRepository: blockRepo
    )
    PageCreateSheet(viewModel: viewModel)
}

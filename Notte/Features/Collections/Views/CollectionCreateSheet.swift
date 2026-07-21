//
//  CollectionCreateSheet.swift
//  Notte
//
//  Created by yuzheyuan on 2026/4/4.
//

import SwiftUI
import SwiftData

struct CollectionCreateSheet: View {
    @ObservedObject var viewModel: CollectionListViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Collection名称", text: $viewModel.newCollectionTitle)
                        .focused($isTitleFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            Task {
                                await viewModel.createCollection()
                            }
                        }
                }
            }
            .navigationTitle("新建Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        viewModel.newCollectionTitle = ""
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("创建") {
                        Task {
                            await viewModel.createCollection()
                        }
                    }
                    .disabled(
                        viewModel.newCollectionTitle
                            .trimmingCharacters(in: .whitespaces).isEmpty
                    )
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
    let repo = CollectionRepository(context: context, normalizationActor: normalizationActor)
    let pageRepo = PageRepository(context: context, normalizationActor: normalizationActor)
    let nodeRepo = NodeRepository(context: context, normalizationActor: normalizationActor)
    let viewModel = CollectionListViewModel(
        repository: repo,
        pageRepository: pageRepo,
        nodeRepository: nodeRepo
    )
    CollectionCreateSheet(viewModel: viewModel)
}

//
//  PageRenameSheet.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/11.
//
import SwiftUI
import SwiftData

struct PageRenameSheet: View {
    @ObservedObject var viewModel: PageListViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTitleFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Page名称", text: $viewModel.renameTitle)
                        .focused($isTitleFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            guard let id = viewModel.renamingPageID else { return }
                            
                            Task {
                                await viewModel.renamePage(id: id)
                            }
                        }
                }
            }
            .navigationTitle("重命名Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        viewModel.newPageTitle = ""
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        guard let id = viewModel.renamingPageID else { return }
                        
                        Task {
                            await viewModel.renamePage(id: id)
                        }
                    }
                    .disabled(viewModel.renameTitle.trimmingCharacters(in: .whitespaces).isEmpty)
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
    let pageRepo = PageRepository(context: context)
    let nodeRepo = NodeRepository(context: context)
    let blockRepo = BlockRepository(context: context)
    let viewModel = PageListViewModel(
        collectionID: UUID(),
        collectionTitle: "我的笔记",
        pageRepository: pageRepo,
        nodeRepository: nodeRepo,
        blockRepository: blockRepo
    )
    PageRenameSheet(viewModel: viewModel)
        .onAppear { viewModel.renameTitle = "原始页面名称" }
}

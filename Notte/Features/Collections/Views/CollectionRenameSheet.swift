//
//  CollectionRenameSheet.swift
//  Notte
//
//  Created by yuzheyuan on 2026/4/4.
//

import SwiftUI

struct CollectionRenameSheet: View {
    @ObservedObject var viewModel: CollectionListViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Collection名称", text: $viewModel.renameTitle)
                        .focused($isTitleFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            guard let id = viewModel.renamingCollectionID else { return }

                            Task {
                                await viewModel.renameCollection(id: id)
                            }
                        }
                }
            }
            .navigationTitle("重命名")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        viewModel.renamingCollectionID = nil
                        viewModel.renameTitle = ""
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        guard let id = viewModel.renamingCollectionID else { return }
                        Task {
                            await viewModel.renameCollection(id: id)
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

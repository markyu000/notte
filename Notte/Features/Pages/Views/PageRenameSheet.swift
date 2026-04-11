//
//  PageRenameSheet.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/11.
//
import SwiftUI

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
            .navigationTitle("重命名")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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

//
//  PageCreateSheet.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/11.
//

import SwiftUI

struct PageCreateSheet: View {
    @ObservedObject var viewModel: PageListViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("页面名称", text: $viewModel.newPageTitle)
                        .focused($isTitleFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            Task { await viewModel.createPage() }
                        }
                }
            }
            .navigationTitle("新建页面")
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

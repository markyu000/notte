//
//  PageEditorView.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/25.
//

import SwiftUI

struct PageEditorView: View {

    @ObservedObject var viewModel: PageEditorViewModel
    @ObservedObject private var persistenceCoordinator: NodePersistenceCoordinator

    init(viewModel: PageEditorViewModel) {
        self.viewModel = viewModel
        _persistenceCoordinator = ObservedObject(wrappedValue: viewModel.persistenceCoordinator)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if viewModel.visibleNodes.isEmpty {
                        // 空状态：通过顶部按钮创建第一个顶级节点
                        ColorTokens.backgroundPrimary
                            .frame(maxWidth: .infinity, minHeight: 400)
                            .overlay(
                                Text("点击左上角加号创建顶级节点")
                                    .font(TypographyTokens.body)
                                    .foregroundStyle(ColorTokens.textSecondary)
                            )
                    } else {
                        ForEach(viewModel.visibleNodes) { node in
                            NodeRowView(
                                node: node,
                                isFocused: viewModel.focusedNodeID == node.id
                                    || viewModel.pendingFocusNodeID == node.id,
                                onTitleChanged: { title in
                                    viewModel.onTitleChanged(nodeID: node.id, title: title)
                                },
                                onContentChanged: { blockID, content in
                                    viewModel.onContentChanged(blockID: blockID, content: content)
                                },
                                onCommand: { command in
                                    viewModel.send(command)
                                },
                                onFocused: { id in
                                    viewModel.didFocusNode(id)
                                }
                            )
                            .id(node.id)
                        }

                        ColorTokens.backgroundPrimary
                            .frame(height: 200)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onChange(of: viewModel.focusedNodeID) { _, newID in
                guard let id = newID else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        }
        .navigationTitle(viewModel.pageTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPage()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .alert("错误", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("好") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    viewModel.createTopLevelNode()
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(ColorTokens.accent)
                }
            }
            if persistenceCoordinator.hasUnsavedChanges {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.saveChanges()
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundStyle(ColorTokens.textPrimary)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ColorTokens.accent)
                    .disabled(persistenceCoordinator.saveState == .saving)
                }
            }
        }
    }
}

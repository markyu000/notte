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
                        // 空状态：点击任意位置创建第一个节点
                        ColorTokens.backgroundPrimary
                            .frame(maxWidth: .infinity, minHeight: 400)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.createFirstNode()
                            }
                            .overlay(
                                Text("点击任意位置开始")
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

                        // 底部空白点击区域：在末尾插入新节点
                        ColorTokens.backgroundPrimary
                            .frame(height: 200)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let lastNode = viewModel.visibleNodes.last {
                                    viewModel.send(.insertAfter(nodeID: lastNode.id))
                                }
                            }
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

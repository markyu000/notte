//
//  PageEditorView.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/25.
//

import SwiftUI
import UIKit

struct PageEditorView: View {

    @ObservedObject var viewModel: PageEditorViewModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if viewModel.visibleNodes.isEmpty {
                        // 空状态：点击任意位置创建第一个节点
                        Color.clear
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
                        Color.clear
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
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    if let id = viewModel.focusedNodeID {
                        viewModel.send(.indent(nodeID: id))
                    }
                } label: {
                    Image(systemName: "increase.indent")
                }
                Button {
                    if let id = viewModel.focusedNodeID {
                        viewModel.send(.outdent(nodeID: id))
                    }
                } label: {
                    Image(systemName: "decrease.indent")
                }
                Button {
                    if let id = viewModel.focusedNodeID {
                        viewModel.send(.moveUp(nodeID: id))
                    }
                } label: {
                    Image(systemName: "arrow.up")
                }
                Button {
                    if let id = viewModel.focusedNodeID {
                        viewModel.send(.moveDown(nodeID: id))
                    }
                } label: {
                    Image(systemName: "arrow.down")
                }
            }
        }
    }
}

//
//  PageEditorView.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/25.
//

import SwiftUI

struct PageEditorView: View {

    @ObservedObject var viewModel: PageEditorViewModel

    var body: some View {
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
                } else {
                    ForEach(viewModel.visibleNodes) { node in
                        NodeRowView(
                            node: node,
                            onTitleChanged: { title in
                                viewModel.onTitleChanged(nodeID: node.id, title: title)
                            },
                            onContentChanged: { blockID, content in
                                viewModel.onContentChanged(blockID: blockID, content: content)
                            },
                            onCommand: { command in
                                viewModel.send(command)
                            }
                        )
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("缩进") {
                    if let second = viewModel.visibleNodes.dropFirst().first {
                        viewModel.send(.indent(nodeID: second.id))
                    }
                }
            }
        }
    }
}

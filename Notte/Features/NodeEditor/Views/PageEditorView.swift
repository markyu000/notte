//
//  PageEditorView.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/25.
//

import SwiftUI
import SwiftData

struct PageEditorView: View {

    @ObservedObject var viewModel: PageEditorViewModel
    @ObservedObject private var persistenceCoordinator:
        NodePersistenceCoordinator
    @State private var showAddMenu = false

    init(viewModel: PageEditorViewModel) {
        self.viewModel = viewModel
        _persistenceCoordinator = ObservedObject(
            wrappedValue: viewModel.persistenceCoordinator
        )
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
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
                        ForEach(Array(viewModel.visibleNodes.enumerated()), id: \.element.id) { index, node in
                            NodeRowView(
                                node: node,
                                isFocused: viewModel.focusedNodeID == node.id
                                    || viewModel.pendingFocusNodeID == node.id,
                                shouldFocusTitle: viewModel.pendingFocusNodeID == node.id,
                                onTitleChanged: { title in
                                    viewModel.onTitleChanged(
                                        nodeID: node.id,
                                        title: title
                                    )
                                },
                                onContentChanged: { blockID, content in
                                    viewModel.onContentChanged(
                                        blockID: blockID,
                                        content: content
                                    )
                                },
                                onCommand: { command in
                                    viewModel.send(command)
                                },
                                onBlockCommand: { command in
                                    viewModel.send(command)
                                },
                                onFocused: { id in
                                    viewModel.didFocusNode(id)
                                }
                            )
                            .id(node.id)
                            .transition(nodeExpandTransition(childIndex: index))
                            // depth 越深 zIndex 越低，子节点渲染在父节点下层
                            .zIndex(Double(1000 - index) - Double(node.depth) * 1000.0)
                            // 折叠时 b 慢速跟进，展开时 b 快速下移让出空间
                            .transaction(value: viewModel.visibleNodes.map(\.id)) { t in
                                if viewModel.isCollapsingAnimation {
                                    t.animation = .spring(response: 0.5, dampingFraction: 0.9)
                                } else {
                                    t.animation = .spring(response: 0.2, dampingFraction: 0.85)
                                }
                            }
                        }

                        ColorTokens.backgroundPrimary
                            .frame(height: 200)
                    }
                }
                .padding(.leading, 10)
                .padding(.trailing, 20)
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
        .alert(
            "错误",
            isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )
        ) {
            Button("好") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button {
                        handleAddSibling()
                    } label: {
                        Label("添加同级节点", systemImage: "text.append")
                    }
                    .disabled(viewModel.focusedNodeID == nil)

                    Button {
                        handleAddChild()
                    } label: {
                        Label("添加子节点", systemImage: "arrow.turn.down.right")
                    }
                    .disabled(viewModel.focusedNodeID == nil)

                    Button {
                        handleAddRoot()
                    } label: {
                        Label("添加根节点", systemImage: "text.alignleft")
                    }
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(ColorTokens.textPrimary)
                } primaryAction: {
                    handleSmartAdd()
                }
            }
            if viewModel.focusedNodeID != nil || persistenceCoordinator.hasUnsavedChanges {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.saveChanges()
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.black)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ColorTokens.accent)
                    .disabled(persistenceCoordinator.saveState == .saving)
                }
            }
        }
    }

    // MARK: - + 按钮处理

    private func handleSmartAdd() {
        if let focusedID = viewModel.focusedNodeID {
            // 有焦点 → 在当前节点后插入同级
            viewModel.send(.insertAfter(nodeID: focusedID))
        } else {
            // 无焦点 → 创建顶级节点
            viewModel.createTopLevelNode()
        }
    }

    private func handleAddSibling() {
        guard let focusedID = viewModel.focusedNodeID else {
            viewModel.createTopLevelNode()
            return
        }
        viewModel.send(.insertAfter(nodeID: focusedID))
    }

    private func handleAddChild() {
        guard let focusedID = viewModel.focusedNodeID else {
            viewModel.createTopLevelNode()
            return
        }
        viewModel.send(.insertChild(nodeID: focusedID))
    }

    private func handleAddRoot() {
        viewModel.createTopLevelNode()
    }

    // 根据子节点与父节点的距离计算偏移：所有子节点从父节点位置出现/消失
    private func nodeExpandTransition(childIndex: Int) -> AnyTransition {
        let parentIdx = viewModel.collapsingParentIndex
        let estimatedRowHeight: CGFloat = 44
        let offsetY = -CGFloat(childIndex - parentIdx) * estimatedRowHeight
        return .asymmetric(
            insertion: .modifier(
                active: NodeCollapseOffsetModifier(offsetY: offsetY, opacity: 0),
                identity: NodeCollapseOffsetModifier(offsetY: 0, opacity: 1)
            ),
            removal: .modifier(
                active: NodeCollapseOffsetModifier(offsetY: offsetY, opacity: 0),
                identity: NodeCollapseOffsetModifier(offsetY: 0, opacity: 1)
            )
        )
    }
}

private struct NodeCollapseOffsetModifier: ViewModifier {
    let offsetY: CGFloat
    let opacity: Double
    func body(content: Content) -> some View {
        content.offset(y: offsetY).opacity(opacity)
    }
}

#Preview {
    let pageID = UUID()
    let container = try! PersistenceController.makeContainer(inMemory: true)
    let context = ModelContext(container)
    let nodeRepo = NodeRepository(context: context)
    let blockRepo = BlockRepository(context: context)
    let viewModel = PageEditorViewModel(
        pageID: pageID,
        pageTitle: "示例页面",
        nodeRepository: nodeRepo,
        blockRepository: blockRepo
    )
    NavigationStack {
        PageEditorView(viewModel: viewModel)
    }
}

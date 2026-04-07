//
//  CollectionListScreen.swift
//  Notte
//
//  Created by yuzheyuan on 2026/4/1.
//

import SwiftUI
import SwiftData

struct CollectionListScreen: View {
    @StateObject private var viewModel: CollectionListViewModel
    @EnvironmentObject private var router: AppRouter
    @State private var editMode: EditMode = .inactive
    @State private var collectionToDelete: Collection?

    init(repository: CollectionRepositoryProtocol) {
        _viewModel = StateObject(
            wrappedValue: CollectionListViewModel(repository: repository)
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.collections.isEmpty {
                    CollectionEmptyState {
                        viewModel.isShowingCreateSheet = true
                    }
                } else {
                    collectionList
                }
            }
            .navigationTitle("Notte")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.isShowingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(ColorTokens.accent)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                        .tint(ColorTokens.accent)
                        .disabled(viewModel.collections.isEmpty)
                }
            }
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $viewModel.isShowingCreateSheet) {
                CollectionCreateSheet(viewModel: viewModel)
            }
            .sheet(
                isPresented: Binding(
                    get: { viewModel.renamingCollectionID != nil},
                    set: { if !$0 { viewModel.renamingCollectionID = nil } }
                )
            ) {
                CollectionRenameSheet(viewModel: viewModel)
            }
            .alert("出错了", isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            ), presenting: viewModel.error) { _ in
                Button("好", role: .cancel) { viewModel.error = nil }
            } message: { error in
                Text(error.errorDescription ?? "未知错误")
            }
            .alert("确认删除", isPresented: Binding(
                get: { collectionToDelete != nil },
                set: { if !$0 { collectionToDelete = nil } }
            ), presenting: collectionToDelete) { collection in
                Button("取消", role: .cancel) {
                    collectionToDelete = nil
                }
                Button("删除", role: .destructive) {
                    Task {
                        await viewModel.deleteCollection(id: collection.id)
                        collectionToDelete = nil
                    }
                }
            } message: { collection in
                Text("确定要删除「\(collection.title)」吗？此操作无法撤销。")
            }
            .task {
                await viewModel.loadCollections()
            }
        }
    }

    private var collectionList: some View {
        List {
            ForEach(Array(viewModel.collections.enumerated()), id: \.element.id) { index, collection in
                VStack(spacing: 0) {
                    CollectionCard(collection: collection)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard editMode == .inactive else { return }
                            router
                                .navigate(
                                    to: .pageList(collectionID: collection.id)
                                )
                        }
                        .contextMenu {
                            CollectionContextMenu(
                                collection: collection,
                                onRename: {
                                    viewModel.renamingCollectionID = collection.id
                                    viewModel.renameTitle = collection.title
                                },
                                onPin: {
                                    Task {
                                        await viewModel
                                            .pinCollection(id: collection.id)
                                    }
                                },
                                onDelete: {
                                    collectionToDelete = collection
                                }
                            )
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                collectionToDelete = collection
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                            
                            Button {
                                viewModel.renamingCollectionID = collection.id
                                viewModel.renameTitle = collection.title
                            } label: {
                                Label("重命名", systemImage: "pencil")
                            }
                            .tint(ColorTokens.accent)
                        }
                    
                    // 在最后一个 pinned collection 后添加分割线
                    if isLastPinnedCollection(at: index) {
                        VStack(spacing: 0) {
                            Spacer()
                                .frame(height: SpacingTokens.md)
                            
                            Rectangle()
                                .fill(ColorTokens.separator)
                                .frame(height: 0.5)
                                .padding(.horizontal, SpacingTokens.md)
                            
                            Spacer()
                                .frame(height: SpacingTokens.sm)
                        }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onMove { from, to in
                guard let sourceIndex = from.first else { return }
                let movingID = viewModel.collections[sourceIndex].id
                let targetID: UUID? = to > 0 ? viewModel.collections[min(to - 1, viewModel.collections.count - 1)].id : nil
                Task {
                    await viewModel
                        .reorderCollection(
                            moving: movingID,
                            after: targetID
                        )
                }
            }
        }
        .listStyle(.plain)
        .listRowSpacing(-20)
        .background(ColorTokens.backgroundPrimary)
    }
    
    /// 判断指定索引的 collection 是否是最后一个 pinned collection
    private func isLastPinnedCollection(at index: Int) -> Bool {
        guard index < viewModel.collections.count else { return false }
        let collection = viewModel.collections[index]
        
        // 当前 collection 必须是 pinned
        guard collection.isPinned else { return false }
        
        // 检查后面是否有非 pinned 的 collection
        let hasUnpinnedAfter = viewModel.collections
            .dropFirst(index + 1)
            .contains { !$0.isPinned }
        
        return hasUnpinnedAfter
    }
}

#Preview {
    let container = try! PersistenceController.makeContainer(inMemory: true)
    let repo = try! CollectionRepository(context: ModelContext(container))
    
    CollectionListScreen(repository: repo)
        .task {
            let createUsecase = CreateCollectionUseCase(repository: repo)
            try! await createUsecase.execute(title: "实例1")
            try! await createUsecase.execute(title: "实例2")
        }
        .environmentObject(AppRouter())
}

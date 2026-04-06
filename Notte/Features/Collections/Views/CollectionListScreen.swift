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
            .navigationTitle("我的 Colleciton")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.isShowingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
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
            .task {
                await viewModel.loadCollections()
            }
        }
    }

    private var collectionList: some View {
        List {
            ForEach(viewModel.collections) { collection in
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
                                Task {
                                    await viewModel
                                        .deleteCollection(id: collection.id)
                                }
                            }
                        )
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            Task {
                                await viewModel
                                    .deleteCollection(id: collection.id)
                            }
                        } label: {
                            Label("删除", systemImage: "trash")
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
        .background(ColorTokens.backgroundPrimary)
    }
}

#Preview {
    var container = try! PersistenceController.makeContainer(inMemory: true)
    var repo = try! CollectionRepository(context: ModelContext(container))
    CollectionListScreen(repository: repo)
}

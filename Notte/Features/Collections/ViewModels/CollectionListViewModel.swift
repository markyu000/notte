//
//  CollectionListViewModel.swift
//  Notte
//
//  Created by yuzheyuan on 2026/4/1.
//

import Foundation
import Combine

@MainActor
class CollectionListViewModel: ObservableObject {
    // MARK: - 数据状态
    @Published var collections: [Collection] = []
    @Published var isLoading: Bool = false
    @Published var error: AppError?

    // MARK: - 创建弹窗状态
    @Published var isShowingCreateSheet: Bool = false
    @Published var newCollectionTitle: String = ""

    // MARK: - 重命名状态
    @Published var renamingCollectionID: UUID?
    @Published var renameTitle: String = ""

    // MARK: - UseCases
    private let fetchUseCase: FetchCollectionsUseCase
    private let createUseCase: CreateCollectionUseCase
    private let renameUseCase: RenameCollectionUseCase
    private let deleteUseCase: DeleteCollectionUseCase
    private let pinUseCase: PinCollectionUseCase
    private let reorderUseCase: ReorderCollectionsUseCase

    init(
        repository: CollectionRepositoryProtocol,
        pageRepository: PageRepositoryProtocol,
        nodeRepository: NodeRepositoryProtocol
    ) {
        self.fetchUseCase = FetchCollectionsUseCase(repository: repository)
        self.createUseCase = CreateCollectionUseCase(repository: repository)
        self.renameUseCase = RenameCollectionUseCase(repository: repository)
        self.deleteUseCase = DeleteCollectionUseCase(
            repository: repository,
            pageRepository: pageRepository,
            nodeRepository: nodeRepository
        )
        self.pinUseCase = PinCollectionUseCase(repository: repository)
        self.reorderUseCase = ReorderCollectionsUseCase(repository: repository)
    }

    //MARK: - 操作方法
    func loadCollections() async {
        isLoading = true
        defer { isLoading = false }
        do {
            collections = try await fetchUseCase.execute()
        } catch {
            self.error = error as? AppError
        }
    }

    func createCollection() async {
        guard !newCollectionTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            try await createUseCase.execute(title: newCollectionTitle)
            newCollectionTitle = ""
            isShowingCreateSheet = false
            await loadCollections()
        } catch {
            self.error = error as? AppError
        }
    }

    func renameCollection(id: UUID) async {
        guard !renameTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            try await renameUseCase.execute(id: id, newTitle: renameTitle)
            renamingCollectionID = nil
            await loadCollections()
        } catch {
            self.error = error as? AppError
        }
    }

    func deleteCollection(id: UUID) async {
        do {
            try await deleteUseCase.execute(id: id)
            await loadCollections()
        } catch {
            self.error = error as? AppError
        }
    }

    func pinCollection(id: UUID) async {
        do {
            try await pinUseCase.execute(id: id)
            await loadCollections()
        } catch {
            self.error = error as? AppError
        }
    }

    func handlePendingCreateFirst() {
        isShowingCreateSheet = true
    }

    func reorderCollection(moving id: UUID, after targetID: UUID?) async {
        do {
            try await reorderUseCase.execute(moving: id, after: targetID)
            await loadCollections()
        } catch {
            self.error = error as? AppError
        }
    }
    
    func importSampleData(using factory: ExampleDataFactory) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await factory.importAll()
            await loadCollections()
        } catch {
            self.error = AppError.unknown(error.localizedDescription)
        }
    }
}

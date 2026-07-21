//
//  DependencyContainer.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/23.
//

import Combine
import SwiftData
import Foundation

@MainActor
class DependencyContainer: ObservableObject {
    let collectionRepository: CollectionRepositoryProtocol
    let pageRepository: PageRepositoryProtocol
    let nodeRepository: NodeRepositoryProtocol
    let blockRepository: BlockRepositoryProtocol

    init(modelContainer: ModelContainer) {
        let context = ModelContext(modelContainer)
        let normalizationActor = SortIndexNormalizationActor(modelContainer: modelContainer)

        self.collectionRepository = CollectionRepository(context: context, normalizationActor: normalizationActor)
        self.pageRepository = PageRepository(context: context, normalizationActor: normalizationActor)
        self.nodeRepository = NodeRepository(context: context, normalizationActor: normalizationActor)
        self.blockRepository = BlockRepository(context: context, normalizationActor: normalizationActor)
    }
    
    // MARK: - ViewModel 工厂方法

    func makePageEditorViewModel(pageID: UUID, pageTitle: String) -> PageEditorViewModel {
        PageEditorViewModel(
            pageID: pageID,
            pageTitle: pageTitle,
            nodeRepository: nodeRepository,
            blockRepository: blockRepository
        )
    }
    
    func makeExampleDataFactory() -> ExampleDataFactory {
        ExampleDataFactory(
            collectionRepository: collectionRepository,
            pageRepository: pageRepository,
            nodeRepository: nodeRepository,
            blockRepository: blockRepository
        )
    }
}

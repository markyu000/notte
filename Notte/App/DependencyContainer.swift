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

        self.collectionRepository = CollectionRepository(context: context)
        self.pageRepository = PageRepository(context: context)
        self.nodeRepository = NodeRepository(context: context)
        self.blockRepository = BlockRepository(context: context)
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
}

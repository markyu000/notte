//
//  RootView.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/23.
//

import Foundation
import SwiftUI

struct RootView: View {
    @StateObject private var router = AppRouter()
    @EnvironmentObject private var dependencyContainer: DependencyContainer

    var body: some View {
        NavigationStack(path: $router.path) {
            CollectionListScreen(
                repository: dependencyContainer.collectionRepository,
                pageRepository: dependencyContainer.pageRepository,
                nodeRepository: dependencyContainer.nodeRepository
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .pageList(let collectionID, let collectionTitle):
                    PageListScreen(
                        collectionID: collectionID,
                        collectionTitle: collectionTitle,
                        pageRepository: dependencyContainer.pageRepository,
                        nodeRepository: dependencyContainer.nodeRepository,
                        blockRepository: dependencyContainer.blockRepository
                    )
                case .nodeEditor(let pageID, let pageTitle):
                    PageEditorView(
                        viewModel: dependencyContainer.makePageEditorViewModel(
                            pageID: pageID,
                            pageTitle: pageTitle
                        )
                    )
                }
            }
        }
        .environmentObject(router)
    }
}

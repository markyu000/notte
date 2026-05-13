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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var pendingAction: PostOnboardingAction?

    enum PostOnboardingAction { case createFirst, importSamples }

    var body: some View {
        ZStack {
            if !hasCompletedOnboarding {
                OnboardingView(
                    onCreateFirstCollection: { pendingAction = .createFirst },
                    onImportSampleData: { pendingAction = .importSamples }
                )
                .transition(.opacity.combined(with: .scale(scale: 1.04)))
            } else {
                mainNavigation
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.easeInOut(duration: 0.45), value: hasCompletedOnboarding)
    }

    private var mainNavigation: some View {
        NavigationStack(path: $router.path) {
            CollectionListScreen(
                repository: dependencyContainer.collectionRepository,
                pageRepository: dependencyContainer.pageRepository,
                nodeRepository: dependencyContainer.nodeRepository,
                pendingAction: pendingAction,
                onActionConsumed: { pendingAction = nil }
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

//
//  RootView.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/23.
//

import Foundation
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var syncLogger: CloudKitSyncLogger
    @StateObject private var router = AppRouter()
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var pendingAction: PostOnboardingAction?
    @State private var collectionCreateTrigger = false
    @State private var pageCreateTrigger = false

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
        .overlay(alignment: .top) {
            if syncLogger.syncFailed {
                SyncFailureBanner()
                    .padding(.top, SpacingTokens.sm)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: syncLogger.syncFailed)
    }

    private var shouldShowFAB: Bool {
        if router.path.isEmpty { return true }
        if case .pageList = router.path.last { return true }
        return false
    }

    private var mainNavigation: some View {
        NavigationStack(path: $router.path) {
            CollectionListScreen(
                showCreateTrigger: $collectionCreateTrigger,
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
                        showCreateTrigger: $pageCreateTrigger,
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
        .overlay(alignment: .bottomTrailing) {
            if shouldShowFAB {
                fab
                    .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .bottomTrailing)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: shouldShowFAB)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .environmentObject(router)
    }

    private var fab: some View {
        Button {
            if router.path.isEmpty {
                collectionCreateTrigger = true
            } else if case .pageList = router.path.last {
                pageCreateTrigger = true
            }
        } label: {
            Image(systemName: "plus")
                .font(.title.weight(.semibold))
                .frame(width: 50, height: 50)
                .foregroundStyle(Color.black)
                .contentShape(Rectangle())
        }
        .buttonStyle(.glassProminent)
        .tint(ColorTokens.accent)
        .buttonBorderShape(.circle)
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .padding(.trailing, SpacingTokens.md)
        .padding(.bottom, SpacingTokens.lg)
    }
}

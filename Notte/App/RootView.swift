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
    @EnvironmentObject private var dependencyCountainer: DependencyContainer

    var body: some View {
        NavigationStack(path: $router.path) {
            CollectionListScreen(
                repository: dependencyCountainer.collecitonRepository
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .pageList(let collectionID):
                    Text("Page List 占位 \(collectionID)")
                case .nodeEditor(let pageID):
                    Text("Node Editor 占位 \(pageID)")
                }
            }
        }
        .environmentObject(router)
    }
}

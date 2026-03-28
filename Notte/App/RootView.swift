//
//  RootView.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/23.
//

import SwiftUI
import Foundation

struct RootView: View {
    @StateObject private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            Text("Collection List占位")
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .pageList(let collectionID):
                        Text("Page List占位 \(collectionID)")
                    case .nodeEditor(let pageID):
                        Text("Node Editor占位 \(pageID)")
                    }
                }
        }
        .environmentObject(router)
    }
}

//
//  AppRouter.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation
import Combine

enum AppRoute: Hashable {
    case pageList(collectionID: UUID, collectionTitle: String)
    case nodeEditor(pageID: UUID)
}

@MainActor
class AppRouter: ObservableObject {
    @Published var path: [AppRoute] = []

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func goBack() {
        path.removeLast()
    }

    func goRoot() {
        path.removeAll()
    }
}

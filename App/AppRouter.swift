//
//  AppRouter.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation

enum AppRoute: Hashable {
    case pageList(collectionID: UUID)
    case nodeEditor(pageID: UUID)
}

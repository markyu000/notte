//
//  CollectionRepository.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import SwiftData

class CollectionRepository: CollectionRepositoryProtocol {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }
}

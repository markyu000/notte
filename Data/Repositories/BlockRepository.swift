//
//  BlockRepository.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import SwiftData

class BlockRepository: BlockRepositoryProtocol {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }
}

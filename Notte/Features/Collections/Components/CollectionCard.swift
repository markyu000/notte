//
//  CollectionCard.swift
//  Notte
//
//  Created by yuzheyuan on 2026/4/1.
//

import SwiftUI

struct CollectionCard: View {
    let collection: Collection

    var body: some View {
        Text(collection.title)
    }
}

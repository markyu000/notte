//
//  AppBootStrap.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/23.
//
import Combine
import SwiftData

@MainActor
class AppBootStrap: ObservableObject {
    @Published var isReady: Bool = false
    private(set) var modelContainer: ModelContainer?

    init() {
        Task {
            await setup()
        }
    }

    private func setup() async {
        do {
            let schema = Schema([
                CollectionModel.self,
                PageModel.self,
                NodeModel.self,
                BlockModel.self
            ])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: config
            )
            isReady = true
        } catch {
            fatalError("SwiftData初始化失败：\(error)")
        }
    }
}

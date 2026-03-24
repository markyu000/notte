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
    let modelContainer: ModelContainer
    private(set) var dependencyContainer: DependencyContainer?

    init() {
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

            dependencyContainer = DependencyContainer(
                modelContainer: modelContainer
            )
            isReady = true
        } catch {
            fatalError("SwiftData初始化失败：\(error)")
        }
    }
}

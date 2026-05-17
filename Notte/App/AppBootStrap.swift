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
    let syncLogger = CloudKitSyncLogger()

    init() {
        do {
            modelContainer = try PersistenceController.makeContainer()
            dependencyContainer = DependencyContainer(modelContainer: modelContainer)
            isReady = true
            syncLogger.startObserving()
        } catch {
            fatalError("SwiftData初始化失败：\(error)")
        }
    }
}

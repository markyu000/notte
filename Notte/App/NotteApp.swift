//
//  NotteApp.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/17.
//

import SwiftUI
import SwiftData

@main
struct NotteApp: App {
    @StateObject private var appBootstrap = AppBootStrap()

    var body: some Scene {
        WindowGroup {
            if appBootstrap.isReady {
                RootView()
                    .environmentObject(appBootstrap)
                    .environmentObject(appBootstrap.dependencyContainer!)
                    .environmentObject(appBootstrap.syncLogger)
            } else {
                ProgressView("启动中...")
            }
        }
        .modelContainer(appBootstrap.modelContainer)
    }
}

//
//  SettingsViewModel.swift
//  Notte
//
//  Created by 余哲源 on 2026/5/14.
//

import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var appVersion: String = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(version) (\(build))"
    }()
}

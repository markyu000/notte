//
//  SettingsView.swift
//  Notte
//
//  Created by 余哲源 on 2026/5/14.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                SettingsSyncSection()
                SettingsAppearanceSection()
                SettingsAboutSection(version: viewModel.appVersion)
                #if DEBUG
                SettingsDebugSection()
                #endif
            }
            .listStyle(.insetGrouped)
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .background(ColorTokens.backgroundPrimary)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(ColorTokens.accent)
                }
            }
        }
    }
}

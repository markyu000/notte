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
            .background(ColorTokens.backgroundPrimary)
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "checkmark")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.black)
            }
            .buttonStyle(.glass)
            .padding(.trailing, SpacingTokens.md)
            .padding(.bottom, SpacingTokens.lg)
        }
    }
}

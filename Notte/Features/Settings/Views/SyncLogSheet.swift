//
//  SyncLogSheet.swift
//  Notte
//
//  Created by 余哲源 on 2026/5/17.
//

import SwiftUI

#if DEBUG
struct SyncLogSheet: View {
    @ObservedObject var logger: CloudKitSyncLogger
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if logger.eventLog.isEmpty {
                    Text("暂无同步记录")
                        .foregroundStyle(ColorTokens.textSecondary)
                        .font(TypographyTokens.body)
                } else {
                    ForEach(logger.eventLog) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: event.succeeded ? "checkmark.circle" : "xmark.circle")
                                    .foregroundStyle(event.succeeded ? Color.green : Color.red)
                                Text(event.eventType.uppercased())
                                    .font(TypographyTokens.caption.weight(.semibold))
                                    .foregroundStyle(ColorTokens.textSecondary)
                                Spacer()
                                Text(event.date, format: .dateTime.hour().minute().second())
                                    .font(TypographyTokens.caption)
                                    .foregroundStyle(ColorTokens.textSecondary)
                            }
                            if let errorDesc = event.errorDescription {
                                Text(errorDesc)
                                    .font(TypographyTokens.caption)
                                    .foregroundStyle(Color.red)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("同步日志")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}
#endif

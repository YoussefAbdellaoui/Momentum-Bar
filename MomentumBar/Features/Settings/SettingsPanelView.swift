//
//  SettingsPanelView.swift
//  MomentumBar
//
//  Created by Codex on behalf of Youssef Abdellaoui.
//

import SwiftUI

struct SettingsPanelView: View {
    let onClose: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            SettingsView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)
        }
        .frame(minWidth: 900, minHeight: 620)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(.headline)
                Text("Customize MomentumBar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let onClose {
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
                .help("Close")
            }
        }
        .padding()
    }
}

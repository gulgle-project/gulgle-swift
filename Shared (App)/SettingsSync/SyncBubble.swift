//
//  SyncBubble.swift
//  Gulgle
//
//  Created by Wolfgang Schwendtbauer on 28.03.26.
//

import SwiftUI

struct SyncBubble: View {
    
    let status: SyncStatus
    
    var body: some View {
        HStack(spacing: 8) {
            switch status {
            case .syncing:
                ProgressView()
                    #if os(iOS)
                    .controlSize(.small)
                    #endif
                Text("Syncing...")
                    .font(.subheadline.weight(.medium))
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Synced")
                    .font(.subheadline.weight(.medium))
            default:
                EmptyView()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }
}

#Preview {
    SyncBubble(status: .success)
}

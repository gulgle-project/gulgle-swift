//
//  BangRowView.swift
//  Gulgle
//
//  Created by Wolfgang Schwendtbauer on 03.11.25.
//

import SwiftUI

struct BangRowView: View {
    let bang: Bang

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("!\(bang.trigger)")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.blue)

                if let additionalTriggers = bang.additionalTriggers, !additionalTriggers.isEmpty {
                    Text("(\(additionalTriggers.map { "!\($0)" }.joined(separator: ", ")))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(bang.domain)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(bang.name)
                .font(.subheadline)
                .foregroundColor(.primary)

            Text(bang.urlTemplate)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let bang = Bang(
        trigger: "g",
        name: "Google",
        category: "Online Services",
        subCategory: "Search",
        urlTemplate: "https://google.com?q=%s",
        domain: "google.com",
        additionalTriggers: ["go", "goog", "google"],
        isCustom: false)

    List {
        BangRowView(bang: bang)
        BangRowView(bang: bang)
        BangRowView(bang: bang)
    }
}

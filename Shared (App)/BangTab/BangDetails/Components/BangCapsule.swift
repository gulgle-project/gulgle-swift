//
//  BangCapsule.swift
//  Gulgle
//
//  Created by Wolfgang Schwendtbauer on 02.11.25.
//

import SwiftUI

struct BangCapsule: View {
    var trigger: String

    init(_ trigger: String) {
        self.trigger = trigger
    }

    var body: some View {
        Text("!\(trigger)")
            .font(.system(.body, design: .monospaced))
            .foregroundColor(.accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.accentColor.opacity(0.1)))
    }
}

struct MutedBangCapsule: View {
    var trigger: String

    init(_ trigger: String) {
        self.trigger = trigger
    }

    var body: some View {
        Text("!\(trigger)")
            .font(.system(.body, design: .monospaced))
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.secondary.opacity(0.08)))
    }
}

#Preview {
    BangCapsule("g")
    MutedBangCapsule("g")

    BangCapsule("goog")
    MutedBangCapsule("goog")

    BangCapsule("google")
    MutedBangCapsule("google")
}

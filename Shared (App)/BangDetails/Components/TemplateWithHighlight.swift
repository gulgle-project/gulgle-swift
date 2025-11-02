//
//  TemplateWithHighlight.swift
//  Gulgle
//
//  Created by Wolfgang Schwendtbauer on 02.11.25.
//

import SwiftUI

struct TemplateWithHighlight: View {
    var templateUrl: String

    init(_ templateUrl: String) {
        self.templateUrl = templateUrl
    }

    var body: some View {
        let components = templateUrl.components(separatedBy: "%s")
        if components.count == 1 {
            Text(templateUrl)
                .font(.system(.body, design: .monospaced))
        } else {
            let before = components[0]
            let after = components.dropFirst().joined(separator: "%s")
            (
                Text(before)
                + Text("%s")
                    .foregroundColor(.secondary)
                + Text(after)
            )
                .font(.system(.footnote, design: .monospaced))
        }
    }
}

#Preview {
    TemplateWithHighlight("https://google.com?q=%s&zhu=1")

    TemplateWithHighlight("https://google.com?q=hello&zhu=1")
}

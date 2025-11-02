//
//  BuiltinBangDetails.swift
//  Gulgle
//
//  Created by Wolfgang Schwendtbauer on 02.11.25.
//

import SwiftUI

struct BuiltinBangDetails: View {
    var bang: Bang

    var body: some View {
        List {
            Section(header: Text("Trigger")) {
                HStack {
                    Text("Primary")
                    Spacer()
                    BangCapsule(bang.trigger)
                }

                if let additional = bang.additionalTriggers, !additional.isEmpty {
                    HStack(alignment: .top) {
                        Text("Additional")
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            ForEach(additional, id: \.self) { trig in
                                MutedBangCapsule(trig)
                            }
                        }
                    }
                }
            }

            Section(header: Text("Details"), footer: Text("This is a built-in bang and cannot be edited or deleted.")) {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(bang.name)
                }
                if bang.category != nil {
                    HStack {
                        Text("Category")
                        Spacer()
                        Text(bang.category!)
                    }
                }
                if bang.subCategory != nil {
                    HStack {
                        Text("Subcategory")
                        Spacer()
                        Text(bang.subCategory!)
                            .foregroundStyle(.secondary)
                    }
                }
                HStack {
                    Text("Domain")
                    Spacer()
                    if let url = URL(string: "https://\(bang.domain)") {
                        Link(bang.domain, destination: url)
                    } else {
                        Text(bang.domain)
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Template")
                    TemplateWithHighlight(bang.urlTemplate)
                }
            }
        }
        .navigationTitle(bang.name)
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

    BuiltinBangDetails(bang: bang)
}

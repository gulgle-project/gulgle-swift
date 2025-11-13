//
//  BangDetails.swift
//  Gulgle
//
//  Created by Wolfgang Schwendtbauer on 03.11.25.
//

import SwiftUI

struct BangDetails: View {
    var bang: Bang

    @State private var showingDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

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

            Section(header: Text("Details")) {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(bang.name)
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
                if let category = bang.category, !category.isEmpty {
                    HStack {
                        Text("Category")
                        Spacer()
                        HStack(spacing: 4) {
                            Text(category)
                            if let subCategory = bang.subCategory, !subCategory.isEmpty {
                                Text("/")
                                Text(subCategory)
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Template")
                    TemplateWithHighlight(bang.urlTemplate)
                }
            }

            if bang.isCustom == true {
                Section(header: Text("Actions")) {
                    Button("Delete", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                }
            }
        }
        .navigationTitle(bang.name)
        .alert("Delete Custom Bang?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                BangRepository.shared.deleteCustomBang(withTrigger: bang.trigger)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this custom bang? This action cannot be undone.")
        }
    }
}

#Preview("Builtin Bang") {
    let builtinBang = Bang(
        trigger: "g",
        name: "Google",
        category: "Online Services",
        subCategory: "Search",
        urlTemplate: "https://google.com?q=%s",
        domain: "google.com",
        additionalTriggers: ["go", "goog", "google"],
        isCustom: false)

    BangDetails(bang: builtinBang)
}

#Preview("Custom Bang") {
    let customBang = Bang(
        trigger: "g",
        name: "Gulgle",
        category: "Online Services",
        subCategory: "Search",
        urlTemplate: "https://gulgle.link?q=%s",
        domain: "gulgle.link",
        additionalTriggers: ["gu", "guldner"],
        isCustom: true)

    BangDetails(bang: customBang)
}

//
//  CustomBangDetails.swift
//  Gulgle
//
//  Created by Wolfgang Schwendtbauer on 02.11.25.
//

import SwiftUI

struct CustomBangDetails: View {
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("Template")
                    TemplateWithHighlight(bang.urlTemplate)
                }
            }

            Section(header: Text("Actions")) {
                Button("Delete", role: .destructive) {
                    showingDeleteConfirmation = true
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

#Preview {
    let bang = Bang(
        trigger: "g",
        name: "Gulgle",
        category: "Online Services",
        subCategory: "Search",
        urlTemplate: "https://gulgle.link?q=%s",
        domain: "gulgle.link",
        additionalTriggers: ["gu", "guldner"],
        isCustom: false)

    CustomBangDetails(bang: bang)
}

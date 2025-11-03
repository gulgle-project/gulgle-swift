//
//  BangAddView.swift
//  Gulgle
//
//  Created by Wolfgang Schwendtbauer on 24.10.25.
//

import SwiftUI

struct BangAddView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var trigger: String = ""
    @State private var name: String = ""
    @State private var category: String = ""
    @State private var subCategory: String = ""
    @State private var urlTemplate: String = ""
    @State private var domain: String = ""
    @State private var additional: String = "" // comma-separated
    @State private var error: String?

    let onSaved: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Trigger") {
                        TextField("g", text: $trigger)
                        #if os(iOS)
                            .textInputAutocapitalization(.never)
                        #endif
                    }
                    LabeledContent("Name") {
                        TextField("Google", text: $name)
                    }
                    LabeledContent("Category") {
                        TextField("Services", text: $category)
                    }
                    LabeledContent("Subcategory") {
                        TextField("Search", text: $subCategory)
                    }
                    LabeledContent("Domain") {
                        TextField("google.com", text: $domain)
                    }
                    LabeledContent("URL Template") {
                        TextField("google.com/q=%s", text: $urlTemplate)
                    }
                    LabeledContent("Additional Triggers") {
                        TextField("goo,goog", text: $additional)
                    }
                }
                .multilineTextAlignment(.trailing)

                if let error = error {
                    Text(error).foregroundColor(.red)
                }
            }
            .navigationTitle("Custom Bang")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseButton { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    ConfirmButton {
                        do {
                            let extras = additional
                                .split(separator: ",")
                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                .filter { !$0.isEmpty }

                            let newBang = Bang(
                                trigger: trigger.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                category: category.trimmingCharacters(in: .whitespacesAndNewlines),
                                subCategory: subCategory.trimmingCharacters(in: .whitespacesAndNewlines),
                                urlTemplate: urlTemplate.trimmingCharacters(in: .whitespacesAndNewlines),
                                domain: domain.trimmingCharacters(in: .whitespacesAndNewlines),
                                additionalTriggers: extras.isEmpty ? nil : extras,
                                isCustom: true
                            )
                            // Local validation using repository’s rules
                            try BangRepository.shared.addOrUpdateCustomBang(newBang)
                            onSaved()
                        } catch {
                            self.error = "Invalid input or trigger conflict. Ensure trigger is alphanumeric and URL template contains '%s'."
                        }
                    }
                    .disabled(trigger.isEmpty || name.isEmpty || domain.isEmpty || urlTemplate.isEmpty)
                }
            }
        }
    }
}

#Preview {
    BangAddView {
    }
}

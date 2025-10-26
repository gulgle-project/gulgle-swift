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
    @State private var urlTemplate: String = ""
    @State private var domain: String = ""
    @State private var additional: String = "" // comma-separated
    @State private var error: String?

    let onSave: (Bang) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Trigger") {
                        TextField("g", text: $trigger)
                    }
                    LabeledContent("Name") {
                        TextField("Google", text: $name)
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
                                trigger: trigger.trimmingCharacters(in: .whitespacesAndNewlines),
                                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                urlTemplate: urlTemplate.trimmingCharacters(in: .whitespacesAndNewlines),
                                domain: domain.trimmingCharacters(in: .whitespacesAndNewlines),
                                additionalTriggers: extras.isEmpty ? nil : extras
                            )
                            // Local validation using repository’s rules
                            try BangRepository.shared.addOrUpdateCustomBang(newBang)
                            onSave(newBang)
                        } catch {
                            self.error = "Invalid input or trigger conflict. Ensure trigger is alphanumeric and URL template contains %s or {{{s}}}."
                        }
                    }
                    .disabled(trigger.isEmpty || name.isEmpty || domain.isEmpty || urlTemplate.isEmpty)
                }
            }
        }
    }
}


#Preview {
    BangAddView { newBang in
        print(newBang)
    }
}

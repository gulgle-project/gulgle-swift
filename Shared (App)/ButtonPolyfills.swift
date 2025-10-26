//
//  ConfirmButton.swift
//  Gulgle
//
//  Created by Wolfgang Schwendtbauer on 24.10.25.
//

import SwiftUI

struct ConfirmButton: View {
    let function: () -> Void

    var body: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            Button(role: .confirm) {
                self.function()
            }
        } else {
            Button {
                self.function()
            } label: {
                Text("Done").bold()
            }
        }
    }
}

struct CloseButton: View {
    let function: () -> Void

    var body: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            Button(role: .close) {
                self.function()
            }
        } else {
            Button {
                self.function()
            } label: {
                Text("Close")
            }
        }
    }
}

struct CancelButton: View {
    let function: () -> Void

    var body: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            Button(role: .cancel) {
                self.function()
            }
        } else {
            Button {
                self.function()
            } label: {
                Text("Cancel")
            }
        }
    }
}

#Preview {
    ConfirmButton { }
    CancelButton { }
}

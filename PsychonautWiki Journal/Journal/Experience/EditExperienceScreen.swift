//
//  EditExperience.swift
//  PsychonautWiki Journal
//
//  Created by Isaak Hanimann on 08.12.22.
//

import SwiftUI

struct EditExperienceScreen: View {

    let experience: Experience
    @State private var title = ""
    @State private var notes = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        EditExperienceContent(
            title: $title,
            notes: $notes,
            save: save,
            dismiss: {dismiss()}
        )
        .onAppear {
            title = experience.titleUnwrapped
            notes = experience.textUnwrapped
        }
    }

    private func save() {
        experience.title = title
        experience.text = notes
        PersistenceController.shared.saveViewContext()
        dismiss()
    }
}

struct EditExperienceContent: View {

    @Binding var title: String
    @Binding var notes: String
    let save: () -> Void
    let dismiss: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section("Title") {
                    TextField("Enter Title", text: $title)
                        .autocapitalization(.sentences)
                }
                Section("Notes") {
                    TextEditor(text: $notes)
                        .autocapitalization(.sentences)
                        .frame(minHeight: 300)
                }
            }
            .optionalScrollDismissesKeyboard()
            .navigationTitle("Edit Experience")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: dismiss)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: save)
                }
            }
        }
    }
}

struct EditExperienceContent_Previews: PreviewProvider {
    static var previews: some View {
        EditExperienceContent(
            title: .constant("This is my title"),
            notes: .constant("These are my notes. They can be very long and should work with many lines. If this should be editable then create a view inside this preview struct that has state."),
            save: {},
            dismiss: {}
        )
    }
}

import SwiftUI

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss

    private let originalNote: Note
    private let onSave: (Note) -> Void

    @State private var title: String
    @State private var content: String
    @State private var isPinned: Bool

    init(note: Note, onSave: @escaping (Note) -> Void) {
        originalNote = note
        self.onSave = onSave
        _title = State(initialValue: note.title)
        _content = State(initialValue: note.content)
        _isPinned = State(initialValue: note.isPinned)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                TextField("Title", text: $title, axis: .vertical)
                    .font(.system(size: 30, weight: .bold, design: .default))
                    .textFieldStyle(.plain)
                    .lineLimit(1...3)
                    .textInputAutocapitalization(.sentences)
                    .accessibilityLabel("Note title")

                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 1)

                ZStack(alignment: .topLeading) {
                    if content.isEmpty {
                        Text("Start writing...")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $content)
                        .font(.body)
                        .textInputAutocapitalization(.sentences)
                        .scrollContentBackground(.hidden)
                        .accessibilityLabel("Note content")
                }
                .frame(maxHeight: .infinity)
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)
            .background(Color(uiColor: .systemBackground))
            .navigationTitle(originalNote.isEmpty ? "New Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isPinned.toggle()
                    } label: {
                        Image(systemName: isPinned ? "pin.fill" : "pin")
                    }
                    .tint(isPinned ? .orange : .primary)
                    .accessibilityLabel(isPinned ? "Unpin note" : "Pin note")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveAndClose()
                    }
                    .fontWeight(.semibold)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onDisappear(perform: saveDraft)
        }
    }

    private func saveDraft() {
        var updated = originalNote
        updated.title = title
        updated.content = content
        updated.isPinned = isPinned
        onSave(updated)
    }

    private func saveAndClose() {
        saveDraft()
        dismiss()
    }
}

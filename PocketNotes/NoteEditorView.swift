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
            VStack(alignment: .leading, spacing: 14) {
                TextField("Title", text: $title, axis: .vertical)
                    .font(.title2.weight(.semibold))
                    .textFieldStyle(.plain)
                    .lineLimit(1...2)
                    .accessibilityLabel("Note title")

                Rectangle()
                    .fill(Color(uiColor: .separator).opacity(0.55))
                    .frame(height: 1)

                ZStack(alignment: .topLeading) {
                    if content.isEmpty {
                        Text("Start writing...")
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $content)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .accessibilityLabel("Note content")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isPinned.toggle()
                    } label: {
                        Image(systemName: isPinned ? "pin.fill" : "pin")
                    }
                    .accessibilityLabel(isPinned ? "Unpin note" : "Pin note")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveAndClose()
                    }
                    .fontWeight(.semibold)
                }
            }
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

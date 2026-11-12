import SwiftUI

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss

    private let originalNote: Note
    private let onSave: (Note) -> Void

    @State private var title: String
    @State private var content: String
    @State private var isPinned: Bool
    @State private var isFavorite: Bool
    @State private var folder: String

    init(note: Note, onSave: @escaping (Note) -> Void) {
        originalNote = note
        self.onSave = onSave
        _title = State(initialValue: note.title)
        _content = State(initialValue: note.content)
        _isPinned = State(initialValue: note.isPinned)
        _isFavorite = State(initialValue: note.isFavorite)
        _folder = State(initialValue: note.folder)
    }

    private var wordCount: Int {
        content.split { $0.isWhitespace || $0.isNewline }.count
    }

    private var shareText: String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayedTitle = trimmedTitle.isEmpty ? "Untitled Note" : trimmedTitle
        return content.isEmpty ? displayedTitle : "\(displayedTitle)\n\n\(content)"
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Menu {
                        Picker("Folder", selection: $folder) {
                            ForEach(NoteFolder.allCases) { option in
                                Label(option.rawValue, systemImage: option.symbol)
                                    .tag(option.rawValue)
                            }
                        }
                    } label: {
                        Label(folder, systemImage: NoteFolder(rawValue: folder)?.symbol ?? "folder")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                    }
                    .buttonStyle(.plain)
                    .modifier(EditorGlassCapsule())

                    Spacer()

                    Button {
                        isFavorite.toggle()
                    } label: {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .foregroundStyle(isFavorite ? Color.yellow : Color.primary)
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(.plain)
                    .modifier(EditorGlassCapsule())
                    .accessibilityLabel(isFavorite ? "Remove favorite" : "Add favorite")
                }

                TextField("Title", text: $title, axis: .vertical)
                    .font(.system(size: 32, weight: .bold, design: .default))
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack {
                    Text("\(wordCount) words · \(content.count) characters")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Spacer()

                    Text("Saved when you leave")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 10)
            .background(Color(uiColor: .systemBackground).ignoresSafeArea())
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

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            insertChecklistItem()
                        } label: {
                            Label("Checklist Item", systemImage: "checklist")
                        }

                        Button {
                            insertBullet()
                        } label: {
                            Label("Bullet Point", systemImage: "list.bullet")
                        }

                        Button {
                            insertDate()
                        } label: {
                            Label("Insert Date", systemImage: "calendar")
                        }
                    } label: {
                        Image(systemName: "text.badge.plus")
                    }
                    .accessibilityLabel("Insert into note")

                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share note")

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

    private func appendAtEnd(_ text: String) {
        if content.isEmpty || content.hasSuffix("\n") {
            content += text
        } else {
            content += "\n" + text
        }
    }

    private func insertChecklistItem() {
        appendAtEnd("☐ ")
    }

    private func insertBullet() {
        appendAtEnd("• ")
    }

    private func insertDate() {
        appendAtEnd(Date.now.formatted(date: .long, time: .shortened))
    }

    private func saveDraft() {
        var updated = originalNote
        updated.title = title
        updated.content = content
        updated.isPinned = isPinned
        updated.isFavorite = isFavorite
        updated.folder = folder
        onSave(updated)
    }

    private func saveAndClose() {
        saveDraft()
        dismiss()
    }
}

private struct EditorGlassCapsule: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: Capsule())
        } else {
            content.background(.ultraThinMaterial, in: Capsule())
        }
    }
}

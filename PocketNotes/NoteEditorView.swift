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
    @State private var tagsText: String
    @State private var color: String

    init(note: Note, onSave: @escaping (Note) -> Void) {
        originalNote = note
        self.onSave = onSave
        _title = State(initialValue: note.title)
        _content = State(initialValue: note.content)
        _isPinned = State(initialValue: note.isPinned)
        _isFavorite = State(initialValue: note.isFavorite)
        _folder = State(initialValue: note.folder)
        _tagsText = State(initialValue: note.tags.joined(separator: ", "))
        _color = State(initialValue: note.color)
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

                    Menu {
                        ForEach(NoteColor.allCases) { option in
                            Button {
                                color = option.rawValue
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(noteColor(option.rawValue))
                                        .frame(width: 12, height: 12)
                                    Text(option.rawValue)
                                    if color == option.rawValue {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Circle()
                            .fill(noteColor(color))
                            .frame(width: 18, height: 18)
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(.plain)
                    .modifier(EditorGlassCapsule())
                    .accessibilityLabel("Choose note color")

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

                TextField("Add tags, separated by commas", text: $tagsText)
                    .font(.subheadline)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Note tags")

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
                            insertNumberedItem()
                        } label: {
                            Label("Numbered Item", systemImage: "list.number")
                        }

                        Button {
                            insertHeading()
                        } label: {
                            Label("Heading", systemImage: "textformat.size.larger")
                        }

                        Button {
                            insertQuote()
                        } label: {
                            Label("Quote", systemImage: "text.quote")
                        }

                        Button {
                            insertDivider()
                        } label: {
                            Label("Divider", systemImage: "minus")
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

    private func insertNumberedItem() {
        let existingNumbers = content
            .split(separator: "\\n")
            .compactMap { line -> Int? in
                let firstPart = line.split(separator: ".", maxSplits: 1).first
                return firstPart.flatMap { Int($0) }
            }
        appendAtEnd("\\((existingNumbers.max() ?? 0) + 1). ")
    }

    private func insertHeading() {
        appendAtEnd("## ")
    }

    private func insertQuote() {
        appendAtEnd("> ")
    }

    private func insertDivider() {
        appendAtEnd("────────────")
    }

    private func parsedTags() -> [String] {
        var seen = Set<String>()
        return tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
    }

    private func noteColor(_ value: String) -> Color {
        switch NoteColor(rawValue: value) {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        default: return Color(uiColor: .tertiarySystemFill)
        }
    }

    private func saveDraft() {
        var updated = originalNote
        updated.title = title
        updated.content = content
        updated.isPinned = isPinned
        updated.isFavorite = isFavorite
        updated.folder = folder
        updated.tags = parsedTags()
        updated.color = color
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

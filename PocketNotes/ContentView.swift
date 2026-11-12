import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: NotesStore
    @State private var searchText = ""
    @State private var editingNote: Note?

    private var visibleNotes: [Note] {
        let filtered = store.notes.filter { note in
            searchText.isEmpty ||
            note.title.localizedCaseInsensitiveContains(searchText) ||
            note.content.localizedCaseInsensitiveContains(searchText)
        }

        return filtered.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    private var pinnedNotes: [Note] {
        visibleNotes.filter(\.isPinned)
    }

    private var regularNotes: [Note] {
        visibleNotes.filter { !$0.isPinned }
    }

    var body: some View {
        NavigationStack {
            Group {
                if visibleNotes.isEmpty {
                    emptyState
                } else {
                    notesContent
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search your notes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editingNote = Note()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .accessibilityLabel("Create note")
                }
            }
            .sheet(item: $editingNote) { note in
                NoteEditorView(note: note) { savedNote in
                    store.save(savedNote)
                }
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var notesContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 26) {
                if !pinnedNotes.isEmpty {
                    notesSection(
                        title: "Pinned",
                        subtitle: "Kept close at hand",
                        notes: pinnedNotes
                    )
                }

                if !regularNotes.isEmpty {
                    notesSection(
                        title: pinnedNotes.isEmpty ? "All Notes" : "More Notes",
                        subtitle: nil,
                        notes: regularNotes
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 32)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }

    private func notesSection(title: String, subtitle: String?, notes: [Note]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("\(notes.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(uiColor: .tertiarySystemFill), in: Capsule())

                Spacer()
            }

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, -8)
            }

            LazyVStack(spacing: 11) {
                ForEach(notes) { note in
                    noteCard(note)
                }
            }
        }
    }

    private func noteCard(_ note: Note) -> some View {
        Button {
            editingNote = note
        } label: {
            NoteCard(note: note)
                .padding(17)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 23, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 23, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.045), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                store.togglePin(note)
            } label: {
                Label(
                    note.isPinned ? "Unpin Note" : "Pin Note",
                    systemImage: note.isPinned ? "pin.slash" : "pin"
                )
            }

            Button(role: .destructive) {
                store.delete(note)
            } label: {
                Label("Delete Note", systemImage: "trash")
            }
        }
        .accessibilityHint("Open note. Touch and hold for more actions.")
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "note.text" : "magnifyingglass")
                .font(.system(size: 43, weight: .light))
                .foregroundStyle(.secondary)
                .padding(.bottom, 3)

            Text(searchText.isEmpty ? "A fresh page" : "No matching notes")
                .font(.title2.weight(.semibold))

            Text(searchText.isEmpty
                 ? "Your thoughts, reminders, and ideas will find a home here."
                 : "Try another title or search term.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 270)

            if searchText.isEmpty {
                Button {
                    editingNote = Note()
                } label: {
                    Label("Create your first note", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 5)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(28)
    }
}

private struct NoteCard: View {
    let note: Note

    private var displayedTitle: String {
        let trimmed = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        let firstLine = note.content
            .split(separator: "\n", omittingEmptySubsequences: true)
            .first
        return firstLine.map(String.init) ?? "Untitled Note"
    }

    private var preview: String {
        let titleIsEmpty = note.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if titleIsEmpty {
            let lines = note.content.split(separator: "\n", omittingEmptySubsequences: true)
            return lines.dropFirst().joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return note.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Text(displayedTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 4)

                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(7)
                        .background(Color(uiColor: .tertiarySystemFill), in: Circle())
                        .accessibilityLabel("Pinned")
                }
            }

            if !preview.isEmpty {
                Text(preview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Label(note.updatedAt.formatted(date: .abbreviated, time: .omitted), systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 2)
        }
        .contentShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
    }
}

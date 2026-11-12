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

    var body: some View {
        NavigationStack {
            Group {
                if visibleNotes.isEmpty {
                    emptyState
                } else {
                    notesList
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search your notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
            }
        }
    }

    private var notesList: some View {
        List {
            if visibleNotes.contains(where: \.isPinned) {
                Section("Pinned") {
                    ForEach(visibleNotes.filter(\.isPinned)) { note in
                        noteRow(note)
                    }
                }
            }

            let regularNotes = visibleNotes.filter { !$0.isPinned }
            if !regularNotes.isEmpty {
                Section(visibleNotes.contains(where: \.isPinned) ? "Other Notes" : "All Notes") {
                    ForEach(regularNotes) { note in
                        noteRow(note)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func noteRow(_ note: Note) -> some View {
        Button {
            editingNote = note
        } label: {
            NoteRow(note: note)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                store.delete(note)
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                store.togglePin(note)
            } label: {
                Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
            }
            .tint(.orange)
        }
        .contextMenu {
            Button {
                store.togglePin(note)
            } label: {
                Label(note.isPinned ? "Unpin Note" : "Pin Note", systemImage: note.isPinned ? "pin.slash" : "pin")
            }

            Button(role: .destructive) {
                store.delete(note)
            } label: {
                Label("Delete Note", systemImage: "trash")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: searchText.isEmpty ? "note.text" : "magnifyingglass")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            Text(searchText.isEmpty ? "Your notes live here" : "No matching notes")
                .font(.title3.weight(.semibold))

            Text(searchText.isEmpty ? "Capture an idea, make a list, or write something down." : "Try another search term.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)

            if searchText.isEmpty {
                Button {
                    editingNote = Note()
                } label: {
                    Label("Create your first note", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

private struct NoteRow: View {
    let note: Note

    private var displayedTitle: String {
        let trimmed = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        let firstLine = note.content.split(separator: "\n", omittingEmptySubsequences: true).first
        return firstLine.map(String.init) ?? "Untitled Note"
    }

    private var preview: String {
        let titleIsEmpty = note.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if titleIsEmpty {
            let lines = note.content.split(separator: "\n", omittingEmptySubsequences: true)
            return lines.dropFirst().joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return note.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Text(displayedTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer(minLength: 4)

                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Pinned")
                }
            }

            if !preview.isEmpty {
                Text(preview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Text(note.updatedAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

import SwiftUI

private enum NotesFilter: String, CaseIterable, Identifiable {
    case all = "All Notes"
    case favorites = "Favorites"
    case personal = "Personal"
    case work = "Work"
    case ideas = "Ideas"
    case trash = "Recently Deleted"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .all: return "note.text"
        case .favorites: return "star"
        case .personal: return "person"
        case .work: return "briefcase"
        case .ideas: return "lightbulb"
        case .trash: return "trash"
        }
    }

    var folder: String? {
        switch self {
        case .personal: return NoteFolder.personal.rawValue
        case .work: return NoteFolder.work.rawValue
        case .ideas: return NoteFolder.ideas.rawValue
        default: return nil
        }
    }

    func includes(_ note: Note) -> Bool {
        switch self {
        case .all: return !note.isDeleted
        case .favorites: return !note.isDeleted && note.isFavorite
        case .personal, .work, .ideas:
            return !note.isDeleted && note.folder == folder
        case .trash: return note.isDeleted
        }
    }
}

private enum NoteSort: String, CaseIterable, Identifiable {
    case recentlyEdited = "Recently Edited"
    case oldestFirst = "Oldest First"
    case title = "Title"

    var id: String { rawValue }
}

struct ContentView: View {
    @EnvironmentObject private var store: NotesStore
    @State private var searchText = ""
    @State private var activeFilter: NotesFilter = .all
    @State private var sortOrder: NoteSort = .recentlyEdited
    @State private var editingNote: Note?

    private var visibleNotes: [Note] {
        let filtered = store.notes.filter { note in
            activeFilter.includes(note) &&
            (searchText.isEmpty ||
             note.title.localizedCaseInsensitiveContains(searchText) ||
             note.content.localizedCaseInsensitiveContains(searchText))
        }

        return filtered.sorted { lhs, rhs in
            if activeFilter != .trash && lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }

            switch sortOrder {
            case .recentlyEdited:
                return lhs.updatedAt > rhs.updatedAt
            case .oldestFirst:
                return lhs.updatedAt < rhs.updatedAt
            case .title:
                return displayTitle(for: lhs).localizedCaseInsensitiveCompare(displayTitle(for: rhs)) == .orderedAscending
            }
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        filterBar

                        if visibleNotes.isEmpty {
                            emptyState
                                .frame(minHeight: max(geometry.size.height - 100, 280))
                        } else {
                            notesGrid(for: geometry.size.width)
                        }
                    }
                    .padding(.horizontal, horizontalPadding(for: geometry.size.width))
                    .padding(.top, 12)
                    .padding(.bottom, 36)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .scrollIndicators(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search your notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Sort Notes", selection: $sortOrder) {
                            ForEach(NoteSort.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .accessibilityLabel("Sort notes")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        createNote()
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
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var filterBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 9) {
                ForEach(NotesFilter.allCases) { filter in
                    filterChip(filter)
                }
            }
            .padding(.vertical, 3)
        }
        .scrollIndicators(.hidden)
    }

    private func filterChip(_ filter: NotesFilter) -> some View {
        let selected = activeFilter == filter
        let count = store.notes.filter(filter.includes).count

        return Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                activeFilter = filter
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: filter.symbol)
                    .font(.system(size: 13, weight: .semibold))
                Text(filter.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .fixedSize()
                Text("\(count)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(selected ? Color.primary : Color.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.primary.opacity(selected ? 0.09 : 0.055), in: Capsule())
            }
            .foregroundStyle(selected ? Color.primary : Color.secondary)
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .modifier(FilterChipGlass())
        .overlay {
            Capsule()
                .strokeBorder(selected ? Color.accentColor.opacity(0.42) : Color.primary.opacity(0.06), lineWidth: 1)
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func notesGrid(for width: CGFloat) -> some View {
        let columnCount = width >= 980 ? 3 : (width >= 620 ? 2 : 1)
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 14, alignment: .top),
            count: columnCount
        )

        return LazyVGrid(columns: columns, alignment: .center, spacing: 14) {
            ForEach(visibleNotes) { note in
                noteCard(note)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func noteCard(_ note: Note) -> some View {
        Button {
            editingNote = note
        } label: {
            NoteCard(note: note, isInTrash: activeFilter == .trash)
                .padding(18)
                .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
                .background(
                    Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
                }
                .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu {
            if note.isDeleted {
                Button {
                    store.restore(note)
                } label: {
                    Label("Restore Note", systemImage: "arrow.uturn.backward")
                }

                Button(role: .destructive) {
                    store.deletePermanently(note)
                } label: {
                    Label("Delete Permanently", systemImage: "trash")
                }
            } else {
                Button {
                    store.togglePin(note)
                } label: {
                    Label(note.isPinned ? "Unpin Note" : "Pin Note", systemImage: note.isPinned ? "pin.slash" : "pin")
                }

                Button {
                    store.toggleFavorite(note)
                } label: {
                    Label(note.isFavorite ? "Remove Favorite" : "Add to Favorites", systemImage: note.isFavorite ? "star.slash" : "star")
                }

                ShareLink(item: shareText(for: note)) {
                    Label("Share Note", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive) {
                    store.moveToTrash(note)
                } label: {
                    Label("Move to Recently Deleted", systemImage: "trash")
                }
            }
        }
        .accessibilityHint("Open note. Touch and hold for more actions.")
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: activeFilter == .trash ? "trash" : (searchText.isEmpty ? "note.text" : "magnifyingglass"))
                .font(.system(size: 43, weight: .light))
                .foregroundStyle(.secondary)
                .padding(.bottom, 3)

            Text(emptyTitle)
                .font(.title2.weight(.semibold))

            Text(emptyDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)

            if activeFilter != .trash && searchText.isEmpty {
                Button {
                    createNote()
                } label: {
                    Label("Create a Note", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 5)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(28)
    }

    private var emptyTitle: String {
        if !searchText.isEmpty { return "No matching notes" }
        if activeFilter == .trash { return "Recently Deleted is Empty" }
        if activeFilter == .favorites { return "No Favorites Yet" }
        return "A Fresh Page"
    }

    private var emptyDescription: String {
        if !searchText.isEmpty { return "Try another title or search term." }
        if activeFilter == .trash { return "Notes you move here will stay until you permanently delete or restore them." }
        if activeFilter == .favorites { return "Mark notes with a star to keep your important ideas together." }
        return "Your thoughts, reminders, and ideas will find a home here."
    }

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        width >= 980 ? 28 : 18
    }

    private func createNote() {
        let folder = activeFilter.folder ?? NoteFolder.personal.rawValue
        editingNote = Note(folder: folder)
    }

    private func displayTitle(for note: Note) -> String {
        let title = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty { return title }
        return note.content.split(separator: "\n", omittingEmptySubsequences: true).first.map(String.init) ?? "Untitled Note"
    }

    private func shareText(for note: Note) -> String {
        let title = displayTitle(for: note)
        return note.content.isEmpty ? title : "\(title)\n\n\(note.content)"
    }
}

private struct NoteCard: View {
    let note: Note
    let isInTrash: Bool

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
            HStack(alignment: .top, spacing: 8) {
                Text(displayedTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 4)

                if note.isPinned && !isInTrash {
                    Image(systemName: "pin.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                if note.isFavorite && !isInTrash {
                    Image(systemName: "star.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.yellow)
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

            Spacer(minLength: 4)

            HStack(spacing: 6) {
                Label(note.folder, systemImage: folderSymbol(note.folder))
                    .lineLimit(1)

                Spacer(minLength: 4)

                Text(note.updatedAt.formatted(date: .abbreviated, time: .omitted))
                    .lineLimit(1)
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
    }

    private func folderSymbol(_ folder: String) -> String {
        NoteFolder(rawValue: folder)?.symbol ?? "folder"
    }
}

private struct FilterChipGlass: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: Capsule())
        } else {
            content.background(.ultraThinMaterial, in: Capsule())
        }
    }
}

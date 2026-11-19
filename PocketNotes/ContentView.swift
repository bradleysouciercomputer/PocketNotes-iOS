import SwiftUI
import UniformTypeIdentifiers

private enum NotesFilter: String, CaseIterable, Identifiable {
    case all = "All Notes"
    case favorites = "Favorites"
    case reminders = "Reminders"
    case recent = "Recently Edited"
    case personal = "Personal"
    case work = "Work"
    case ideas = "Ideas"
    case archived = "Archived"
    case trash = "Recently Deleted"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .all: return "note.text"
        case .favorites: return "star"
        case .reminders: return "bell"
        case .recent: return "clock"
        case .personal: return "person"
        case .work: return "briefcase"
        case .ideas: return "lightbulb"
        case .archived: return "archivebox"
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
        case .all: return !note.isDeleted && !note.isArchived
        case .favorites: return !note.isDeleted && !note.isArchived && note.isFavorite
        case .reminders: return !note.isDeleted && !note.isArchived && note.reminderAt != nil
        case .recent: return !note.isDeleted && !note.isArchived && note.updatedAt >= Date().addingTimeInterval(-7 * 24 * 60 * 60)
        case .personal, .work, .ideas:
            return !note.isDeleted && !note.isArchived && note.folder == folder
        case .archived: return !note.isDeleted && note.isArchived
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
    @State private var showingEmptyTrashConfirmation = false
    @State private var showingBackupImporter = false
    @State private var backupDataForImport: Data?
    @State private var showingBackupImportOptions = false
    @State private var backupImportAlert: BackupImportAlert?

    private var visibleNotes: [Note] {
        let filtered = store.notes.filter { note in
            activeFilter.includes(note) &&
            (searchText.isEmpty ||
             note.title.localizedCaseInsensitiveContains(searchText) ||
             note.content.localizedCaseInsensitiveContains(searchText) ||
             note.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) }))
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
                        if activeFilter == .trash {
                            Divider()
                            Button(role: .destructive) {
                                showingEmptyTrashConfirmation = true
                            } label: {
                                Label("Empty Recently Deleted", systemImage: "trash.slash")
                            }
                        }
                        Divider()
                        Button {
                            showingBackupImporter = true
                        } label: {
                            Label("Import Backup (JSON)", systemImage: "square.and.arrow.down")
                        }
                        if let backup = store.exportBackup() {
                            ShareLink(item: backup) {
                                Label("Export All Notes (JSON)", systemImage: "square.and.arrow.up")
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .accessibilityLabel("Sort notes")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            createNote()
                        } label: {
                            Label("Blank Note", systemImage: "square.and.pencil")
                        }
                        Divider()
                        Button {
                            createNote(title: "Meeting Notes", content: "Date: \(Date.now.formatted(date: .long, time: .omitted))\nAttendees:\n\nAgenda\n• \n\nNotes\n\nAction Items\n☐ ")
                        } label: {
                            Label("Meeting Notes", systemImage: "person.3")
                        }
                        Button {
                            createNote(title: "Daily Journal", content: "Today I feel...\n\nWhat happened today?\n\nOne thing I'm grateful for:\n")
                        } label: {
                            Label("Daily Journal", systemImage: "book.closed")
                        }
                        Button {
                            createNote(title: "To-Do List", content: "☐ First task\n☐ Second task\n☐ Third task")
                        } label: {
                            Label("To-Do List", systemImage: "checklist")
                        }
                        Button {
                            createNote(title: "Project Plan", content: "Overview\n\nGoals\n• \n\nMilestones\n1. \n\nTasks\n☐ \n\nNotes\n")
                        } label: {
                            Label("Project Plan", systemImage: "chart.bar")
                        }
                        Button {
                            createNote(title: "Shopping List", content: "☐ Produce\n☐ Dairy\n☐ Pantry\n☐ Household\n☐ Other")
                        } label: {
                            Label("Shopping List", systemImage: "cart")
                        }
                        Button {
                            createNote(title: "Reading List", content: "Book:\nAuthor:\n\nKey Takeaways\n• \n\nFavorite Quotes\n")
                        } label: {
                            Label("Reading List", systemImage: "books.vertical")
                        }
                        Button {
                            createNote(title: "Weekly Review", content: "Wins this week\n• \n\nWhat I learned\n• \n\nWhat needs attention\n☐ \n\nPriorities for next week\n1. ")
                        } label: {
                            Label("Weekly Review", systemImage: "calendar.badge.clock")
                        }
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
            .confirmationDialog(
                "Permanently delete all notes in Recently Deleted?",
                isPresented: $showingEmptyTrashConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All Permanently", role: .destructive) {
                    store.emptyTrash()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone.")
            }
            .fileImporter(
                isPresented: $showingBackupImporter,
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case .success(let url):
                    let hasAccess = url.startAccessingSecurityScopedResource()
                    defer {
                        if hasAccess { url.stopAccessingSecurityScopedResource() }
                    }
                    do {
                        backupDataForImport = try Data(contentsOf: url)
                        showingBackupImportOptions = true
                    } catch {
                        backupImportAlert = BackupImportAlert(
                            title: "Could Not Read Backup",
                            message: error.localizedDescription
                        )
                    }
                case .failure(let error):
                    backupImportAlert = BackupImportAlert(
                        title: "Import Cancelled",
                        message: error.localizedDescription
                    )
                }
            }
            .confirmationDialog(
                "Import this backup?",
                isPresented: $showingBackupImportOptions,
                titleVisibility: .visible
            ) {
                Button("Merge with Existing Notes") {
                    performBackupImport(replacingExisting: false)
                }
                Button("Replace All Notes", role: .destructive) {
                    performBackupImport(replacingExisting: true)
                }
                Button("Cancel", role: .cancel) {
                    backupDataForImport = nil
                }
            } message: {
                Text("Merge keeps your current notes and adds the backup. Replace removes your current library and uses only the backup.")
            }
            .alert(item: $backupImportAlert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func performBackupImport(replacingExisting: Bool) {
        guard let data = backupDataForImport else { return }
        do {
            let count = try store.importBackup(data, replacingExisting: replacingExisting)
            let action = replacingExisting ? "replaced your library with" : "merged"
            backupImportAlert = BackupImportAlert(
                title: "Backup Imported",
                message: "\(count) notes were \(action) successfully."
            )
        } catch {
            backupImportAlert = BackupImportAlert(
                title: "Import Failed",
                message: error.localizedDescription
            )
        }
        backupDataForImport = nil
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
                    noteBackground(note.color),
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
                    if note.isArchived {
                        store.unarchive(note)
                    } else {
                        store.archive(note)
                    }
                } label: {
                    Label(note.isArchived ? "Unarchive Note" : "Archive Note", systemImage: note.isArchived ? "tray.and.arrow.up" : "archivebox")
                }

                Button {
                    store.toggleFavorite(note)
                } label: {
                    Label(note.isFavorite ? "Remove Favorite" : "Add to Favorites", systemImage: note.isFavorite ? "star.slash" : "star")
                }

                Button {
                    editingNote = store.duplicate(note)
                } label: {
                    Label("Duplicate Note", systemImage: "plus.square.on.square")
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
        if activeFilter == .archived { return "No Archived Notes" }
        if activeFilter == .favorites { return "No Favorites Yet" }
        if activeFilter == .reminders { return "No Reminders Scheduled" }
        return "A Fresh Page"
    }

    private var emptyDescription: String {
        if !searchText.isEmpty { return "Try another title or search term." }
        if activeFilter == .trash { return "Notes you move here will stay until you permanently delete or restore them." }
        if activeFilter == .archived { return "Archived notes are tucked away from your main list. Unarchive them whenever you need them again." }
        if activeFilter == .favorites { return "Mark notes with a star to keep your important ideas together." }
        if activeFilter == .reminders { return "Turn on a reminder inside any note to see it here." }
        return "Your thoughts, reminders, and ideas will find a home here."
    }

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        width >= 980 ? 28 : 18
    }

    private func noteBackground(_ value: String) -> Color {
        switch NoteColor(rawValue: value) {
        case .some(.red): return Color.red.opacity(0.11)
        case .some(.orange): return Color.orange.opacity(0.13)
        case .some(.yellow): return Color.yellow.opacity(0.16)
        case .some(.green): return Color.green.opacity(0.11)
        case .some(.blue): return Color.blue.opacity(0.11)
        case .some(.purple): return Color.purple.opacity(0.11)
        case .some(.pink): return Color.pink.opacity(0.12)
        default: return Color(uiColor: .secondarySystemGroupedBackground)
        }
    }

    private func createNote(title: String = "", content: String = "") {
        let folder = activeFilter.folder ?? NoteFolder.personal.rawValue
        editingNote = Note(title: title, content: content, folder: folder)
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

            if !note.tags.isEmpty {
                HStack(spacing: 5) {
                    ForEach(note.tags.prefix(3), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2.weight(.medium))
                            .lineLimit(1)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(Color.primary.opacity(0.06), in: Capsule())
                    }
                }
                .padding(.top, 1)
            }

            Spacer(minLength: 4)

            HStack(spacing: 6) {
                if let reminderAt = note.reminderAt, !isInTrash {
                    Label(reminderAt.formatted(date: .abbreviated, time: .shortened), systemImage: "bell")
                        .lineLimit(1)
                } else {
                    Label(note.folder, systemImage: folderSymbol(note.folder))
                    .lineLimit(1)
                }

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


private struct BackupImportAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

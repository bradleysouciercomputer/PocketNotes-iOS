import Foundation
import SwiftUI

@MainActor
final class NotesStore: ObservableObject {
    @Published private(set) var notes: [Note] = []

    private let fileURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("pocket-notes.json", isDirectory: false)
    }()

    init() {
        load()
    }

    func save(_ draft: Note) {
        var note = draft

        if let existingIndex = notes.firstIndex(where: { $0.id == draft.id }) {
            let existing = notes[existingIndex]
            note.createdAt = existing.createdAt

            let changed = existing.title != draft.title ||
                existing.content != draft.content ||
                existing.isPinned != draft.isPinned
            note.updatedAt = changed ? Date() : existing.updatedAt
            notes[existingIndex] = note
        } else {
            guard !draft.isEmpty else { return }
            note.createdAt = Date()
            note.updatedAt = Date()
            notes.append(note)
        }

        persist()
    }

    func delete(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        persist()
    }

    func togglePin(_ note: Note) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index].isPinned.toggle()
        notes[index].updatedAt = Date()
        persist()
    }

    private func load() {
        do {
            let data = try Data(contentsOf: fileURL)
            notes = try JSONDecoder().decode([Note].self, from: data)
        } catch {
            // A missing file simply means this is the app's first launch.
            notes = []
        }
    }

    private func persist() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(notes)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Pocket Notes could not save notes: \(error.localizedDescription)")
        }
    }
}

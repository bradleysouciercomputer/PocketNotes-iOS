import Foundation
import SwiftUI
import UserNotifications

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
                existing.isPinned != draft.isPinned ||
                existing.isFavorite != draft.isFavorite ||
                existing.isDeleted != draft.isDeleted ||
                existing.isArchived != draft.isArchived ||
                existing.folder != draft.folder ||
                existing.tags != draft.tags ||
                existing.color != draft.color ||
                existing.reminderAt != draft.reminderAt
            note.updatedAt = changed ? Date() : existing.updatedAt
            notes[existingIndex] = note
        } else {
            guard !draft.isEmpty else { return }
            note.createdAt = Date()
            note.updatedAt = Date()
            notes.append(note)
        }

        persist()
        Task {
            await Self.updateReminder(for: note)
        }
    }

    @discardableResult
    func duplicate(_ note: Note) -> Note {
        var copy = note
        copy.id = UUID()
        copy.title = note.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Copy of Note"
            : "Copy of \(note.title)"
        copy.createdAt = Date()
        copy.updatedAt = Date()
        copy.isPinned = false
        copy.isFavorite = false
        copy.isDeleted = false
        copy.isArchived = false
        copy.reminderAt = nil
        notes.append(copy)
        persist()
        return copy
    }

    func togglePin(_ note: Note) {
        update(note) { $0.isPinned.toggle() }
    }

    func toggleFavorite(_ note: Note) {
        update(note) { $0.isFavorite.toggle() }
    }

    func archive(_ note: Note) {
        update(note) {
            $0.isArchived = true
            $0.isPinned = false
        }
    }

    func unarchive(_ note: Note) {
        update(note) { $0.isArchived = false }
    }

    func moveToTrash(_ note: Note) {
        update(note) {
            $0.isDeleted = true
            $0.isPinned = false
            $0.isArchived = false
        }
    }

    func restore(_ note: Note) {
        update(note) { $0.isDeleted = false }
    }

    func deletePermanently(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        persist()
        Task {
            await UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: [note.id.uuidString])
        }
    }

    func emptyTrash() {
        let deletedIDs = notes.filter(\.isDeleted).map { $0.id.uuidString }
        notes.removeAll { $0.isDeleted }
        persist()
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: deletedIDs)
    }

    func exportBackup() -> String? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(notes)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Pocket Notes could not export backup: \(error.localizedDescription)")
            return nil
        }
    }

    @discardableResult
    func importBackup(_ data: Data, replacingExisting: Bool) throws -> Int {
        let imported: [Note]
        do {
            let isoDecoder = JSONDecoder()
            isoDecoder.dateDecodingStrategy = .iso8601
            imported = try isoDecoder.decode([Note].self, from: data)
        } catch {
            // Also accept older JSON backups using JSONEncoder's numeric date format.
            let legacyDecoder = JSONDecoder()
            imported = try legacyDecoder.decode([Note].self, from: data)
        }

        let previousIDs = Set(notes.map { $0.id })
        if replacingExisting {
            notes = imported
        } else {
            var merged = Dictionary(uniqueKeysWithValues: notes.map { ($0.id, $0) })
            for note in imported { merged[note.id] = note }
            notes = merged.values.sorted { $0.updatedAt > $1.updatedAt }
        }
        persist()

        let currentIDs = Set(notes.map { $0.id })
        let removedIDs = previousIDs.subtracting(currentIDs).map { $0.uuidString }
        Task {
            let center = UNUserNotificationCenter.current()
            if !removedIDs.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: removedIDs)
            }
            for note in imported {
                await Self.updateReminder(for: note)
            }
        }
        return imported.count
    }

    private func update(_ note: Note, changes: (inout Note) -> Void) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        changes(&notes[index])
        notes[index].updatedAt = Date()
        let updated = notes[index]
        persist()
        Task {
            await Self.updateReminder(for: updated)
        }
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

    private static func updateReminder(for note: Note) async {
        let center = UNUserNotificationCenter.current()
        let identifier = note.id.uuidString

        guard !note.isDeleted, let reminderDate = note.reminderAt, reminderDate > Date() else {
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            return
        }

        do {
            var settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                guard granted else { return }
                settings = await center.notificationSettings()
            }

            guard settings.authorizationStatus == .authorized ||
                  settings.authorizationStatus == .provisional else {
                return
            }

            let content = UNMutableNotificationContent()
            let trimmedTitle = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
            content.title = trimmedTitle.isEmpty ? "Pocket Notes Reminder" : trimmedTitle
            content.body = note.content.isEmpty ? "You asked to be reminded about this note." : String(note.content.prefix(180))
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminderDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            try await center.add(request)
        } catch {
            print("Pocket Notes could not schedule reminder: \(error.localizedDescription)")
        }
    }
}

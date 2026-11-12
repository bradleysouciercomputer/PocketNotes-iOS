import Foundation

enum NoteFolder: String, CaseIterable, Identifiable {
    case personal = "Personal"
    case work = "Work"
    case ideas = "Ideas"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .personal: return "person"
        case .work: return "briefcase"
        case .ideas: return "lightbulb"
        }
    }
}

struct Note: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var isFavorite: Bool
    var isDeleted: Bool
    var folder: String

    init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isPinned: Bool = false,
        isFavorite: Bool = false,
        isDeleted: Bool = false,
        folder: String = NoteFolder.personal.rawValue
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
        self.isFavorite = isFavorite
        self.isDeleted = isDeleted
        self.folder = folder
    }

    var isEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, content, createdAt, updatedAt
        case isPinned, isFavorite, isDeleted, folder
    }

    // New fields are optional during decoding so notes created by earlier
    // Pocket Notes versions remain readable after an app update.
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        title = try values.decodeIfPresent(String.self, forKey: .title) ?? ""
        content = try values.decodeIfPresent(String.self, forKey: .content) ?? ""
        createdAt = try values.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try values.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
        isPinned = try values.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        isFavorite = try values.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        isDeleted = try values.decodeIfPresent(Bool.self, forKey: .isDeleted) ?? false
        folder = try values.decodeIfPresent(String.self, forKey: .folder) ?? NoteFolder.personal.rawValue
    }
}

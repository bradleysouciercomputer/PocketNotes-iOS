import SwiftUI

@main
struct PocketNotesApp: App {
    @StateObject private var notesStore = NotesStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notesStore)
                .tint(Color.accentColor)
        }
    }
}

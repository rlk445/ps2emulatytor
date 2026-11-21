import SwiftUI
import SwiftData

@main
struct PS2LauncherApp: App {
    var body: some Scene {
        WindowGroup { LibraryView() }
            .modelContainer(for: Game.self)
    }
}

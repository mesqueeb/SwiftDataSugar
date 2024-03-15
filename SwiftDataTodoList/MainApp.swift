import SwiftData
import SwiftUI

@main
struct MainApp: App {
  var body: some Scene {
    WindowGroup {
      TodoListView()
    }
    .modelContainer(PersistentDb.sharedModelContainer)
  }
}

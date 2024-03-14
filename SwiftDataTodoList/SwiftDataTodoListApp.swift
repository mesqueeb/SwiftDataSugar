import SwiftData
import SwiftUI

@main
struct SwiftDataTodoListApp: App {
  var body: some Scene {
    WindowGroup {
      TodoListView()
    }
    .modelContainer(PersistentDb.sharedModelContainer)
  }
}

import SwiftData
import SwiftUI

let sharedModelContainer: ModelContainer = {
  let schema = Schema([
    TodoItem.self,
  ])
  let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

  do {
    return try ModelContainer(for: schema, configurations: [modelConfiguration])
  } catch {
    fatalError("Could not create ModelContainer: \(error)")
  }
}()

@MainActor
let dbTodo = DbHandler<TodoItem>(modelContainer: sharedModelContainer)

@main
struct MainApp: App {
  var body: some Scene {
    WindowGroup {
      TodoListView()
    }
    .modelContainer(sharedModelContainer)
  }
}

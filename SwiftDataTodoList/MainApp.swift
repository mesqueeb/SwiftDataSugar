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
    WindowGroup(id: "main") {
      TodoListView()
    }
    .modelContainer(sharedModelContainer)

    WindowGroup(id: "item", for: UUID.self) { $uid in
      if let uid {
        SwiftDataQuery(predicate: #Predicate<TodoItem> { $0.uid == uid }) { item in
          TodoItemDetailsView(item: item)
        }
      } else {
        Text("ID not provided")
      }
    }
    .modelContainer(sharedModelContainer)
  }
}

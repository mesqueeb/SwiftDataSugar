import SwiftData
import SwiftUI

public let sharedModelContainer: ModelContainer = {
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
public let dbTodos = DbCollection<TodoItem>(modelContainer: sharedModelContainer)

@main
struct MainApp: App {
  var body: some Scene {
    WindowGroup(id: "main") {
      TodoListView()
    }
    .modelContainer(sharedModelContainer)

    WindowGroup(id: "item", for: UUID.self) { $uid in
      if let uid {
        DbQuery(predicate: #Predicate<TodoItem> { $0.uid == uid }) { item, doc in
          TodoItemDetailsView(item: item, doc: doc)
        }
      } else {
        Text("ID not provided")
      }
    }
    .modelContainer(sharedModelContainer)
  }
}

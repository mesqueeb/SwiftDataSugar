import DatabaseKit
import SwiftData
import SwiftUI

@MainActor public let modelContainer = initModelContainer(for: TodoItem.self, with: MigrationPlan.self, inMemory: false)

@MainActor public let dbTodos = DbCollection<TodoItem>(modelContainer: modelContainer)

@main
struct MainApp: App {
  var body: some Scene {
    WindowGroup(id: "main") {
      TodoListView()
    }
    .modelContainer(modelContainer)

    WindowGroup(id: "item", for: UUID.self) { $uid in
      if let uid {
        DbQuery(predicate: #Predicate<TodoItem> { $0.uid == uid }) { item in
          TodoItemDetailsView(item: item)
        }
      } else {
        Text("ID not provided")
      }
    }
    .modelContainer(modelContainer)
  }
}

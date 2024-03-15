import SwiftData
import SwiftUI

struct CrashTests: View {
  let items: [TodoItem]

  @Environment(\.modelContext) private var modelContext

  func insertTests() {
    // The following 4 tasks all use the Actor to insert, so the app should not crash.
    // Question 1: Why does it crash?
    Task { @MainActor in
      dbTodo.insert(TodoItem(summary: "Inserted via Actor on @MainActor 1"))
    }
    Task { @MainActor in
      dbTodo.insert(TodoItem(summary: "Inserted via Actor on @MainActor 2"))
    }
    Task.detached {
      dbTodo.insert(TodoItem(summary: "Inserted via Actor detached 1"))
    }
    Task.detached {
      dbTodo.insert(TodoItem(summary: "Inserted via Actor detached 2"))
    }
    // Adding the following 4 tasks should not crash the app, because inserting should not ever clash.
    // Question 2: Why does including the following code crash the app?
    // Task { @MainActor in
    //   modelContext.insert(TodoItem(summary: "Inserted via @MainActor modelContext on @MainActor 1"))
    // }
    // Task { @MainActor in
    //   modelContext.insert(TodoItem(summary: "Inserted via @MainActor modelContext on @MainActor 2"))
    // }
    // Task.detached {
    //   modelContext.insert(TodoItem(summary: "Inserted via @MainActor modelContext detached 1"))
    // }
    // Task.detached {
    //   modelContext.insert(TodoItem(summary: "Inserted via @MainActor modelContext detached 2"))
    // }
  }

  func deleteTests() {
    let items: [TodoItem] = Array(repeating: 0, count: 4).enumerated().map { i, _ in
      TodoItem(summary: "Inserted to be deleted #\(i)")
    }

    Task {
      await withThrowingTaskGroup(of: Void.self) { group in
        for item in items {
          group.addTask {
            try await dbTodo.dbHandler.insert(item)
          }
        }
      }
      dbTodo.reQuery()
      await wait(ms: 50)

      // The following 4 tasks all use the Actor to delete, so the app should not crash.
      // Question 3: Why does it crash?
      Task { @MainActor in
        dbTodo.delete(id: items[0].id)
      }
      Task { @MainActor in
        dbTodo.delete(id: items[1].id)
      }
      Task.detached {
        dbTodo.delete(id: items[2].id)
      }
      Task.detached {
        dbTodo.delete(id: items[3].id)
      }
      // Deleting should always happen in the context an item was created in, so the following code will crash:
      // Question 4: Is the above assumption correct?
      // Task { @MainActor in
      //   modelContext.delete(items[4])
      // }
    }
  }

  func editTests() {
    let item = TodoItem(summary: "Item to edit")
    Task {
      try await dbTodo.dbHandler.insert(item)
      dbTodo.reQuery()
      await wait(ms: 50)

      // The following 4 tasks all use the Actor to update, so the app should not crash.
      // Question 5: Why does it crash?
      Task { @MainActor in
        dbTodo.update(id: item.id, \.summary, "Edit A")
      }
      Task { @MainActor in
        dbTodo.update(id: item.id, \.summary, "Edit B")
      }
      Task.detached {
        dbTodo.update(id: item.id, \.summary, "Edit C")
      }
      Task.detached {
        dbTodo.update(id: item.id, \.summary, "Edit D")
      }

      // The following will have data races, so will crash the app:
      // Question 6: Is the above assumption correct?
      // Task { @MainActor in
      //   item.summary = "Edit E"
      // }
      // Task { @MainActor in
      //   item.summary = "Edit F"
      // }
      // Task.detached {
      //   item.summary = "Edit G"
      // }
      // Task.detached {
      //   item.summary = "Edit H"
      // }

      await wait(ms: 1000) // wait 1 second
      // One of the edits above should by now have been applied and reQuery'ing should refresh the list of items
      // Question 7: Why does the list of items not get refreshed. (re-running the app _will_ show the edit reflected)
      dbTodo.reQuery()
    }
  }

  var body: some View {
    Menu {
      Button("Insert Tests", action: insertTests)
      Button("Delete Tests", action: deleteTests)
      Button("Edit Tests", action: editTests)
    } label: { Label("Options", systemImage: "ellipsis.curlybraces") }
      .pickerStyle(.inline)
  }
}

#Preview {
  CrashTests(items: [])
}

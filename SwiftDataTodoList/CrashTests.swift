import SwiftData
import SwiftUI

struct CrashTests: View {
  @Environment(\.modelContext) private var modelContext

  func insertTests() {
    Task { @MainActor in try await dbTodo.insert(TodoItem(summary: "Inserted via Actor on @MainActor 1")) }
    Task { @MainActor in try await dbTodo.insert(TodoItem(summary: "Inserted via Actor on @MainActor 2")) }
    Task.detached { try await dbTodo.insert(TodoItem(summary: "Inserted via Actor detached 1")) }
    Task.detached { try await dbTodo.insert(TodoItem(summary: "Inserted via Actor detached 2")) }
    Task { @MainActor in modelContext.insert(TodoItem(summary: "Inserted via environment modelContext on @MainActor 1")) }
    Task { @MainActor in modelContext.insert(TodoItem(summary: "Inserted via environment modelContext on @MainActor 2")) }
    // The following would crash the app:
    // Using `modelContext` from SwiftUI inside of `Task.detached`
    // Task.detached { modelContext.insert(TodoItem(summary: "Inserted via @MainActor modelContext detached 1")) }
  }

  func deleteTests() {
    let items: [TodoItem] = Array(repeating: 0, count: 4).enumerated().map { i, _ in
      TodoItem(summary: "Inserted to be deleted #\(i)")
    }

    Task {
      await withThrowingTaskGroup(of: Void.self) { group in
        for item in items {
          group.addTask { try await dbTodo.insert(item) }
        }
      }
      await wait(ms: 50)

      Task { @MainActor in try await dbTodo.delete(id: items[0].id) }
      Task { @MainActor in try await dbTodo.delete(id: items[1].id) }
      Task.detached { try await dbTodo.delete(id: items[2].id) }
      Task.detached { try await dbTodo.delete(id: items[3].id) }
      // The following would crash the app:
      // Deleting an item by instance reference in a context it was not created in.
      // Task { @MainActor in modelContext.delete(items[4]) }
    }
  }

  func editTests() {
    let item = TodoItem(summary: "Item to edit")
    Task {
      try await dbTodo.insert(item)
      await wait(ms: 50)

      // The following tasks all use the Actor to update, so the app should not crash.
      Task { @MainActor in try await dbTodo.update(id: item.id, \.summary, "Edit A") }
      Task { @MainActor in try await dbTodo.update(id: item.id, \.summary, "Edit B") }
      Task.detached { try await dbTodo.update(id: item.id, \.summary, "Edit C") }
      Task.detached { try await dbTodo.update(id: item.id, \.summary, "Edit D") }

      // One of the edits above should by now have been applied the `@Query` _should_ pick up this update automatically
      // Question: Why does the list of items not get refreshed. (re-running the app _will_ show the edit reflected)
    }
  }

  func inspectPID() {
    let item = TodoItem(summary: "Inspect PID")
    let uid: String = item.uid.uuidString
    let pid: PersistentIdentifier = item.id
    print("uid →", uid)
    print("pid →", pid)
    modelContext.insert(item)
    try! modelContext.save()
    let pidAfterSave: PersistentIdentifier = item.id
    print("pidAfterSave →", pidAfterSave)
  }

  var body: some View {
    Menu {
      Button("Insert Tests", action: insertTests)
      Button("Delete Tests", action: deleteTests)
      Button("Edit Tests", action: editTests)
      Button("Inspect PID", action: inspectPID)
    } label: { Label("Options", systemImage: "ellipsis.curlybraces") }
      .pickerStyle(.inline)
  }
}

#Preview {
  CrashTests()
}

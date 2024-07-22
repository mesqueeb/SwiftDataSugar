import SwiftData
import SwiftUI

struct MenuCrashTests: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var queryItems: [TodoItem]

  func insertTests() {
    Task { @MainActor in try await dbTodos.insert(TodoItem(summary: "Inserted via Actor on @MainActor 1")) }
    Task { @MainActor in try await dbTodos.insert(TodoItem(summary: "Inserted via Actor on @MainActor 2")) }
    Task.detached { try await dbTodos.insert(TodoItem(summary: "Inserted via Actor detached 1")) }
    Task.detached { try await dbTodos.insert(TodoItem(summary: "Inserted via Actor detached 2")) }
    Task { @MainActor in modelContext.insert(TodoItem(summary: "Inserted via environment modelContext on @MainActor 1")) }
    Task { @MainActor in modelContext.insert(TodoItem(summary: "Inserted via environment modelContext on @MainActor 2")) }
    // The following would crash the app:
    // Using `modelContext` from SwiftUI inside of `Task.detached`
    // Task.detached { modelContext.insert(TodoItem(summary: "Inserted via @MainActor modelContext detached 1")) }
  }

  func deleteTests() {
    let items: [TodoItem] = Array(repeating: 0, count: 8).enumerated().map { i, _ in
      TodoItem(summary: "Inserted to be deleted #\(i)")
    }

    Task {
      await withThrowingTaskGroup(of: Void.self) { group in
        for item in items {
          group.addTask { try await dbTodos.insert(item) }
        }
      }
      await wait(ms: 50)

      Task { @MainActor in try await dbTodos.delete(id: items[0].id) }
      Task { @MainActor in try await dbTodos.delete(id: items[1].id) }
      Task.detached { try await dbTodos.delete(id: items[2].id) }
      Task.detached { try await dbTodos.delete(id: items[3].id) }

      await wait(ms: 50)

      let queryItemsToDelete: [PersistentIdentifier] = [queryItems[0].id, queryItems[1].id, queryItems[2].id, queryItems[3].id]
      Task { @MainActor in try await dbTodos.delete(id: queryItemsToDelete[0]) }
      Task { @MainActor in try await dbTodos.delete(id: queryItemsToDelete[1]) }
      Task.detached { try await dbTodos.delete(id: queryItemsToDelete[2]) }
      Task.detached { try await dbTodos.delete(id: queryItemsToDelete[3]) }

      // The following would crash the app:
      // Deleting an item by instance reference in a context it was not created in.
      // Task { @MainActor in modelContext.delete(items[4]) }
    }
  }

  func editTests() {
    let item = TodoItem(summary: "Item to edit")
    Task {
      try await dbTodos.insert(item)
      await wait(ms: 50)

      // The following tasks all use the Actor to update, so the app should not crash.
      Task { @MainActor in try await dbTodos.update(id: item.id, \.summary, "Edit A") }
      Task { @MainActor in try await dbTodos.update(id: item.id, \.summary, "Edit B") }
      Task.detached { try await dbTodos.update(id: item.id, \.summary, "Edit C") }
      Task.detached { try await dbTodos.update(id: item.id, \.summary, "Edit D") }

      await wait(ms: 50)

      Task { @MainActor in try await dbTodos.update(id: queryItems[0].id, \.summary, "Edit A") }
      Task { @MainActor in try await dbTodos.update(id: queryItems[0].id, \.summary, "Edit B") }
      Task.detached { try await dbTodos.update(id: queryItems[0].id, \.summary, "Edit C") }
      Task.detached { try await dbTodos.update(id: queryItems[0].id, \.summary, "Edit D") }

      // One of the edits above should by now have been applied the `@Query` _should_ pick up this update automatically
      // Question: Why does the list of items not get refreshed. (re-running the app _will_ show the edit reflected)
    }
  }

  func raceTests() {
    let item = TodoItem(summary: "RACE")
    Task {
      try await dbTodos.insert(item)
      await wait(ms: 50)

      let newDate = Date()

      Task.detached { try await dbTodos.update(id: item.id) { data in data.isChecked = true } }
      Task.detached { try await dbTodos.update(id: item.id) { data in data.summary = "RACED" } }
      Task.detached { try await dbTodos.update(id: item.id) { data in data.dateChecked = newDate } }

      await wait(ms: 50)

      Task.detached {
        if let data = try await dbTodos.fetch(id: item.id) {
          print("data.isChecked == true →", data.isChecked == true)
          print("data.summary == \"RACED\" →", data.summary == "RACED")
          print("data.dateChecked == newDate →", data.dateChecked == newDate)
        }
      }

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
      Button("Race Tests", action: raceTests)
      Button("Inspect PID", action: inspectPID)
    } label: { Label("Run Tests", systemImage: "ellipsis.curlybraces") }
      .pickerStyle(.inline)
    #if os(visionOS)
      .glassBackgroundEffect()
    #endif
  }
}

#Preview {
  MenuCrashTests()
}

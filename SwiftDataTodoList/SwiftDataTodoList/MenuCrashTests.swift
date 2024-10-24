import Foundation
import SwiftData
import SwiftUI

public struct MenuCrashTests: View {
  @Query private var queryItems: [TodoItem]

  public init() {
    let descriptor = FetchDescriptor<TodoItem>(predicate: nil, sortBy: [])
    _queryItems = Query(descriptor)
  }

  @Environment(\.modelContext) private var modelContext

  func insertTests() {
    Task { @MainActor in
      try await dbTodos.insert(TodoItemSnapshot(summary: "Inserted via Actor on @MainActor 1"))
    }
    Task { @MainActor in
      try await dbTodos.insert(TodoItemSnapshot(summary: "Inserted via Actor on @MainActor 2"))
    }
    Task.detached {
      try await dbTodos.insert(TodoItemSnapshot(summary: "Inserted via Actor detached 1"))
    }
    Task.detached {
      try await dbTodos.insert(TodoItemSnapshot(summary: "Inserted via Actor detached 2"))
    }
    Task { @MainActor in
      modelContext.insert(
        TodoItem(summary: "Inserted via environment modelContext on @MainActor 1")
      )
    }
    Task { @MainActor in
      modelContext.insert(
        TodoItem(summary: "Inserted via environment modelContext on @MainActor 2")
      )
    }
    // The following would crash the app:
    // Using `modelContext` from SwiftUI inside of `Task.detached`
    // Task.detached { modelContext.insert(TodoItem(summary: "Inserted via @MainActor modelContext detached 1")) }
  }

  func deleteTests() {
    let items: [TodoItemSnapshot] = Array(repeating: 0, count: 8).enumerated()
      .map { i, _ in TodoItemSnapshot(summary: "Inserted to be deleted #\(i)") }

    Task {
      try! await withThrowingTaskGroup(of: Void.self) { group in
        for item in items { group.addTask { try await dbTodos.insert(item) } }
        for try await _task in group {}
      }
      try! await Task.sleep(for: .milliseconds(50))

      Task { @MainActor in try await dbTodos.delete(uid: items[0].uid) }
      Task { @MainActor in try await dbTodos.delete(uid: items[1].uid) }
      Task.detached { try await dbTodos.delete(uid: items[2].uid) }
      Task.detached { try await dbTodos.delete(uid: items[3].uid) }

      try! await Task.sleep(for: .milliseconds(50))

      let queryItemsToDelete: [PersistentIdentifier] = [
        queryItems[0].id, queryItems[1].id, queryItems[2].id, queryItems[3].id,
      ]
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
    let item = TodoItemSnapshot(summary: "Item to edit")
    Task {
      try await dbTodos.insert(item)
      try! await Task.sleep(for: .milliseconds(50))

      // The following tasks all use the Actor to update, so the app should not crash.
      Task.detached { try await dbTodos.update(uid: item.uid) { data in data.summary = "Edit A" } }
      Task.detached { try await dbTodos.update(uid: item.uid) { data in data.summary = "Edit B" } }

      try! await Task.sleep(for: .milliseconds(50))

      let queryItemId = queryItems[0].id
      Task.detached {
        try await dbTodos.update(id: queryItemId) { data in data.summary = "Edit C" }
      }
      Task.detached {
        try await dbTodos.update(id: queryItemId) { data in data.summary = "Edit D" }
      }

      // One of the edits above should by now have been applied the `@Query` _should_ pick up this update automatically
      // Question: Why does the list of items not get refreshed. (re-running the app _will_ show the edit reflected)
    }
  }

  func raceTests() {
    let item = TodoItemSnapshot(summary: "RACE")
    Task {
      try await dbTodos.insert(item)
      try! await Task.sleep(for: .milliseconds(50))

      let newDate = Date()

      Task.detached { try await dbTodos.update(uid: item.uid) { data in data.isChecked = true } }
      Task.detached { try await dbTodos.update(uid: item.uid) { data in data.summary = "RACED" } }
      Task.detached {
        try await dbTodos.update(uid: item.uid) { data in data.dateChecked = newDate }
      }

      try! await Task.sleep(for: .milliseconds(50))

      Task.detached {
        if let data = try! await dbTodos.fetch(uid: item.uid) {
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

  public var body: some View {
    Menu {
      Button("Insert Tests", action: insertTests)
      Button("Delete Tests", action: deleteTests)
      Button("Edit Tests", action: editTests)
      Button("Race Tests", action: raceTests)
      Button("Inspect PID", action: inspectPID)
    } label: {
      Label("Run Tests", systemImage: "ellipsis.curlybraces")
    }
    .pickerStyle(.inline)  // swift-format-ignore
    #if os(visionOS)
      .glassBackgroundEffect()
    #endif
  }
}

#Preview { MenuCrashTests() }

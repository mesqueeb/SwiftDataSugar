import Foundation
import SwiftData

public enum PersistentDb {
  public static var sharedModelContainer: ModelContainer = {
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
}

public enum FetchStatus {
  case unfetched, fetching, fetched
}

@ModelActor public actor DbHandler<T: PersistentModel> {
  // @ModelActor additions:
  // ---------------------
  // nonisolated let modelExecutor: any SwiftData.ModelExecutor
  // nonisolated let modelContainer: SwiftData.ModelContainer
  // init(modelContainer: SwiftData.ModelContainer) {
  //   let modelContext = ModelContext(modelContainer)
  //   self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
  //   self.modelContainer = modelContainer
  // }
  // ---------------------

  public func insert(_ data: T) throws {
    printGCDThread("[insert]")
    printMemoryAddress("[insert] before insert data. modelContext", data.modelContext)
    printMemoryAddress("[insert] before insert actor modelContext", modelContext)
    modelContext.insert(data)
    printMemoryAddress("[insert] after  insert data. modelContext", data.modelContext)
    try modelContext.save()
    printMemoryAddress("[insert] after  save   data. modelContext", data.modelContext)
  }

  public func delete(id: PersistentIdentifier) throws {
    guard let data = fetch(id: id) else { return }
    printGCDThread("[delete]")
    printMemoryAddress("[delete] data. modelContext", data.modelContext)
    printMemoryAddress("[delete] actor modelContext", modelContext)
    modelContext.delete(data)
    try modelContext.save()
  }

  public func update<Value>(id: PersistentIdentifier, _ keyPath: WritableKeyPath<T, Value>, _ newValue: Value) throws {
    guard var data = fetch(id: id) else { return }
    data[keyPath: keyPath] = newValue
    printGCDThread("[update] {\(keyPath): \(newValue)}")
    printMemoryAddress("[update] data. modelContext", data.modelContext)
    printMemoryAddress("[update] actor modelContext", modelContext)
    try modelContext.save()
  }

  public func fetch(id: PersistentIdentifier) -> T? {
    let data = self[id, as: T.self]

    printGCDThread("[fetch]")
    printMemoryAddress("[fetch] data. modelContext", data?.modelContext)
    printMemoryAddress("[fetch] actor modelContext", modelContext)

    return data
  }
}

@Observable public final class DbService<T: PersistentModel> {
  public var dbHandler: DbHandler<T> {
    DbHandler<T>(modelContainer: PersistentDb.sharedModelContainer)
  }

  public func insert(_ data: T) {
    Task.detached {
      try await self.dbHandler.insert(data)
    }
  }

  public func delete(id: PersistentIdentifier) {
    Task.detached {
      try await self.dbHandler.delete(id: id)
    }
  }

  public func update<Value>(id: PersistentIdentifier, _ keyPath: WritableKeyPath<T, Value>, _ newValue: Value) {
    Task.detached {
      try await self.dbHandler.update(id: id, keyPath, newValue)
    }
  }
}

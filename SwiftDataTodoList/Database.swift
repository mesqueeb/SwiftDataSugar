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

  /// ```swift
  /// let predicate = #Predicate<TodoItem> { data in data.summary.contains(keyword) }
  /// let results = await Scribe.search(predicate)
  /// ```
  public func query(predicate: Predicate<T>? = nil, sortBy: [SortDescriptor<T>] = []) throws -> [T] {
    let descriptor = FetchDescriptor(predicate: predicate, sortBy: sortBy)

    return try modelContext.fetch(descriptor)
  }

  public func fetch(id: PersistentIdentifier) -> T? {
    let data = self[id, as: T.self]

    printGCDThread("[fetch]")
    printMemoryAddress("[fetch] data. modelContext", data?.modelContext)
    printMemoryAddress("[fetch] actor modelContext", modelContext)

    return data
  }

  public func fetchAll() throws -> [T] {
    return try query()
  }
}

@Observable public final class DbService<T: PersistentModel> {
  /// Use this in your swiftUI views
  public var fetchedData: [T] = []
  /// Use this in your swiftUI views
  public var fetchStatus: FetchStatus = .unfetched

  private var lastUsedQuery: (predicate: Predicate<T>?, sortBy: [SortDescriptor<T>]) = (predicate: nil, sortBy: [])

  private var dbHandler: DbHandler<T> {
    DbHandler<T>(modelContainer: PersistentDb.sharedModelContainer)
  }

  public func insert(_ data: T) {
    Task.detached {
      try await self.dbHandler.insert(data)
      self.reQuery()
    }
  }

  public func delete(id: PersistentIdentifier) {
    Task.detached {
      try await self.dbHandler.delete(id: id)
      self.reQuery()
    }
  }

  public func update<Value>(id: PersistentIdentifier, _ keyPath: WritableKeyPath<T, Value>, _ newValue: Value) {
    Task.detached {
      try await self.dbHandler.update(id: id, keyPath, newValue)
    }
  }

  public func query(predicate: Predicate<T>? = nil, sortBy: [SortDescriptor<T>] = []) {
    Task.detached {
      self.fetchStatus = .fetching
      let result = try await self.dbHandler.query(predicate: predicate, sortBy: sortBy)
      self.lastUsedQuery = (predicate: predicate, sortBy: sortBy)
      self.fetchedData = result
      self.fetchStatus = .fetched
    }
  }

  /// Executes `query` again with the last used predicate and sortBy
  public func reQuery() {
    query(predicate: lastUsedQuery.predicate, sortBy: lastUsedQuery.sortBy)
  }

  public func fetch(id: PersistentIdentifier) async -> T? {
    return await dbHandler.fetch(id: id)
  }

  public func fetchAll() {
    lastUsedQuery = (predicate: nil, sortBy: [])
    Task.detached {
      self.fetchStatus = .fetching
      let result = try await self.dbHandler.fetchAll()
      self.fetchedData = result
      self.fetchStatus = .fetched
    }
  }
}

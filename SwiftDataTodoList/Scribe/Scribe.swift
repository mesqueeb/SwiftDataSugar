import Foundation
import SwiftData

public enum ScribeLedger {
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

public func printMemoryAddress(_ description: String, _ ctx: ModelContext?) {
  if let ctx {
    let memoryAddress = Unmanaged.passUnretained(ctx).toOpaque()
    print("\(description) @\(memoryAddress)")
  } else {
    print("\(description) @--- NIL")
  }
}

public func printGCDThread() {
  print("Thread: \(String(validatingUTF8: __dispatch_queue_get_label(nil)) ?? "unknown")")
}

@ModelActor public actor Quill<T> where T: PersistentModel {
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
    printMemoryAddress("before insert data.modelContext", data.modelContext)
    printMemoryAddress("before insert actor modelContext", modelContext)
    printGCDThread()
    modelContext.insert(data)
    printMemoryAddress("after insert data.modelContext", data.modelContext)
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

    printGCDThread()
    printMemoryAddress("data.modelContext", data?.modelContext)
    printMemoryAddress("actor modelContext", modelContext)

    return data
  }

  public func delete(id: PersistentIdentifier) throws {
    guard let data = fetch(id: id) else { return }
    printGCDThread()
    printMemoryAddress("data.modelContext", data.modelContext)
    printMemoryAddress("actor modelContext", modelContext)
    modelContext.delete(data)
    try modelContext.save()
  }

  public func fetchAll() throws -> [T] {
    return try query()
  }
}

@Observable public final class Scribe<T: PersistentModel> {
  public var fetchData: [T] = []
  public var fetchStatus: FetchStatus = .unfetched

  private var lastUsedQuery: (predicate: Predicate<T>?, sortBy: [SortDescriptor<T>]) = (predicate: nil, sortBy: [])

  private var quill: Quill<T> {
    Quill<T>(modelContainer: ScribeLedger.sharedModelContainer)
  }

  public func insert(_ data: T) {
    Task.detached {
      try await self.quill.insert(data)
      self.reQuery()
    }
  }

  public func query(predicate: Predicate<T>? = nil, sortBy: [SortDescriptor<T>] = []) {
    lastUsedQuery = (predicate: predicate, sortBy: sortBy)
    Task.detached {
      self.fetchStatus = .fetching
      let result = try await self.quill.query(predicate: predicate, sortBy: sortBy)
      self.fetchData = result
      self.fetchStatus = .fetched
    }
  }

  public func reQuery() {
    query(predicate: lastUsedQuery.predicate, sortBy: lastUsedQuery.sortBy)
  }

  public func fetch(id: PersistentIdentifier) async -> T? {
    return await quill.fetch(id: id)
  }

  public func delete(id: PersistentIdentifier) {
    Task.detached {
      try await self.quill.delete(id: id)
      self.reQuery()
    }
  }

  public func fetchAll() {
    lastUsedQuery = (predicate: nil, sortBy: [])
    Task.detached {
      self.fetchStatus = .fetching
      let result = try await self.quill.fetchAll()
      self.fetchData = result
      self.fetchStatus = .fetched
    }
  }
}

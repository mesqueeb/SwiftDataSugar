import Foundation
import SwiftData

/// Makes sure there's a `dateUpdated` because it's required to better track
/// updates to instances that were modified from a detached thread, sometimes a @Query won't pick up on those.
public protocol Timestamped {
  var dateUpdated: Date { get set }
}

public actor DbCollection<T>: ModelActor where T: PersistentModel, T: Timestamped {
  // -----------------------
  // ModelActor conformance:
  // -----------------------
  public nonisolated let modelExecutor: any SwiftData.ModelExecutor
  public nonisolated let modelContainer: SwiftData.ModelContainer

  @MainActor
  public init(modelContainer: SwiftData.ModelContainer) {
    let modelContext = modelContainer.mainContext
    modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
    self.modelContainer = modelContainer
  }

  // ---------------------

  public func insert(_ data: T) throws {
    modelContext.insert(data)
    try modelContext.save()
  }

  public func delete(id: PersistentIdentifier) throws {
    guard let data = fetch(id: id) else { return }
    modelContext.delete(data)
    try modelContext.save()
  }

  public func update<Value>(id: PersistentIdentifier, _ keyPath: WritableKeyPath<T, Value>, _ newValue: Value) throws {
    guard var data = fetch(id: id) else { return }
    data[keyPath: keyPath] = newValue
    data.dateUpdated = .now
    try modelContext.save()
  }

  public func update(id: PersistentIdentifier, _ updateFn: @escaping @Sendable (T) -> Void) throws {
    guard var data = fetch(id: id) else { return }
    updateFn(data)
    data.dateUpdated = .now
    try modelContext.save()
  }

  public func fetch(id: PersistentIdentifier) -> T? {
    let data = self[id, as: T.self]
    return data
  }
}

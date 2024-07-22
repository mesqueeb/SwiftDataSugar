import Foundation
import SwiftData

/// Makes sure there's a `dateUpdated` because it's required to better track
public protocol CollectionDocument {
  var dateUpdated: Date { get set }
}

public actor DbCollection<T>: ModelActor where T: PersistentModel, T: CollectionDocument {
  // -----------------------
  // ModelActor conformance:
  // -----------------------
  public nonisolated let modelExecutor: any SwiftData.ModelExecutor
  public nonisolated let modelContainer: SwiftData.ModelContainer

  @MainActor
  public init(modelContainer: SwiftData.ModelContainer) {
    let modelContext = modelContainer.mainContext
    self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
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

  /// Returns `nil` if the record is not found, otherwise it returns the result of the `updateFn` closure being passed
  public func update<Result: Sendable>(id: PersistentIdentifier, _ updateFn: @escaping (T) -> Result) throws -> Result? {
    guard var data = fetch(id: id) else { return nil }
    let result = updateFn(data)
    data.dateUpdated = .now
    try modelContext.save()
    return result
  }

  public func fetch(id: PersistentIdentifier) -> T? {
    let data = self[id, as: T.self]
    return data
  }
}

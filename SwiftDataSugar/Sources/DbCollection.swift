import Foundation
import SwiftData

public actor DbCollection<T>: ModelActor
where T: PersistentModel & CollectionDocument & SendableDocument, T.SendableType: Sendable {
  // -----------------------
  // ModelActor conformance:
  // -----------------------
  public nonisolated let modelExecutor: any SwiftData.ModelExecutor
  public nonisolated let modelContainer: SwiftData.ModelContainer

  @MainActor public init(modelContainer: SwiftData.ModelContainer) {
    let modelContext = modelContainer.mainContext
    self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
    self.modelContainer = modelContainer
  }

  // ---------------------
  // State
  // ---------------------
  private var fetchedLast: T? = nil

  // ---------------------

  public func insert(_ data: T.SendableType) throws {
    modelContext.insert(T(from: data))
    try modelContext.save()
  }

  /// Gets the document instance `T` for internal use
  /// Returns `nil` if the record is not found
  private func get(id: PersistentIdentifier) -> T? {
    let data = self[id, as: T.self]
    self.fetchedLast = data
    return data
  }

  /// Gets the document instance `T` for internal use
  /// Returns `nil` if the record is not found
  private func get(uid: UUID) throws -> T? {
    if self.fetchedLast?.uid == uid { return self.fetchedLast }
    let dataArr = try self.modelContext.fetch(
      FetchDescriptor<T>(predicate: #Predicate { $0.uid == uid })
    )
    let data = dataArr.first
    self.fetchedLast = data
    return data
  }

  /// Returns a Sendable version of the document instance `T`
  /// Returns `nil` if the record is not found
  public func fetch(id: PersistentIdentifier) -> T.SendableType? {
    return self.get(id: id)?.toSendable()
  }

  /// Returns a Sendable version of the document instance `T`
  /// Returns `nil` if the record is not found
  public func fetch(uid: UUID) throws -> T.SendableType? {
    return try self.get(uid: uid)?.toSendable()
  }

  /// Deletes the document and saves
  public func delete(id: PersistentIdentifier) throws {
    guard let data = get(id: id) else { return }
    self.fetchedLast = nil
    modelContext.delete(data)
    try modelContext.save()
  }

  /// Deletes the document and saves
  public func delete(uid: UUID) throws {
    guard let data = try get(uid: uid) else { return }
    self.fetchedLast = nil
    modelContext.delete(data)
    try modelContext.save()
  }

  /// Returns `nil` if the record is not found, otherwise it returns the result of the `updateFn` closure being passed
  ///
  /// Always use this from `Task.detached` instead of just `Task` to ensure the passed `updateFn` closure is being
  /// executed in the actor's context. (otherwise `Task` might inherit the `@MainActor` and this shows a compile error)
  public func updateAndSave<Result: Sendable>(
    id: PersistentIdentifier,
    _ updateFn: @escaping (inout T) -> Result
  ) throws -> Result? {
    guard var data = get(id: id) else { return nil }
    let result = updateFn(&data)
    data.dateUpdated = .now
    try modelContext.save()
    return result
  }

  /// Returns `nil` if the record is not found, otherwise it returns the result of the `updateFn` closure being passed
  ///
  /// Always use this from `Task.detached` instead of just `Task` to ensure the passed `updateFn` closure is being
  /// executed in the actor's context. (otherwise `Task` might inherit the `@MainActor` and this shows a compile error)
  public func updateAndSave<Result: Sendable>(
    uid: UUID,
    _ updateFn: @escaping (inout T) -> Result
  ) throws -> Result? {
    guard var data = try get(uid: uid) else { return nil }
    let result = updateFn(&data)
    data.dateUpdated = .now
    try modelContext.save()
    return result
  }

  var saveTask: Task<Void, Never>? = nil

  public func saveDebounced() {
    if let saveTask { saveTask.cancel() }
    self.saveTask = Task {
      try? await Task.sleep(for: .seconds(1))
      if Task.isCancelled { return }
      do { try self.modelContext.save() } catch { print("❗️[DbCollection] Error saving", error) }
      self.saveTask = nil
    }
  }

  /// Returns `nil` if the record is not found, otherwise it returns the result of the `updateFn` closure being passed
  ///
  /// Always use this from `Task.detached` instead of just `Task` to ensure the passed `updateFn` closure is being
  /// executed in the actor's context. (otherwise `Task` might inherit the `@MainActor` and this shows a compile error)
  public func updateAndSaveLater<Result: Sendable>(
    uid: UUID,
    _ updateFn: @escaping (inout T) -> Result
  ) throws -> Result? {
    guard var data = try get(uid: uid) else { return nil }
    let result = updateFn(&data)
    data.dateUpdated = .now
    saveDebounced()
    return result
  }
}

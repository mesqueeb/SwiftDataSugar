import Foundation
import SwiftData

public actor DbDocument<T>: ModelActor where T: PersistentModel, T: Timestamped {
  public let id: PersistentIdentifier
  // -----------------------
  // ModelActor conformance:
  // -----------------------
  public nonisolated let modelExecutor: any SwiftData.ModelExecutor
  public nonisolated let modelContainer: SwiftData.ModelContainer

  @MainActor
  public init(modelContainer: SwiftData.ModelContainer, id: PersistentIdentifier) throws {
    let modelContext = modelContainer.mainContext
    modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
    self.modelContainer = modelContainer
    // Custom props
    self.id = id
  }

  // ---------------------

  public lazy var data: T = {
    guard var foundData = self[id, as: T.self] else {
      print("❗️ data not found")
      fatalError("❗️ data not found")
    }
    return foundData
  }()

  public func delete() throws {
    guard let data = fetch() else { return }
    modelContext.delete(data)
    try modelContext.save()
  }

  public func update(_ updateFn: @escaping @Sendable (T) -> Void) throws {
    guard var data = fetch() else { return }
    updateFn(data)
    data.dateUpdated = .now
    try modelContext.save()
  }

  public func fetch() -> T? {
    let data = self[id, as: T.self]
    return data
  }
}

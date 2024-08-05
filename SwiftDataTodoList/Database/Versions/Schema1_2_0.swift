import DatabaseKit
import Foundation
import SwiftData
import SwiftUI

public extension Dictionary {
  func mapKeys<K: Hashable>(_ transform: (Key) -> K) -> [K: Value] {
    return self.reduce(into: [K: Value]()) { result, pair in
      let (key, value) = pair
      result[transform(key)] = value
    }
  }
}

/// In this schema we introduce a new Codable implementation for EditHistory
/// and added a new "version" (`v`) prop to `TodoItem`
public enum Schema1_2_0: VersionedSchema, MockableSchema {
  public static let versionIdentifier = Schema.Version(1, 2, 0)

  public static var models: [any PersistentModel.Type] {
    [Schema1_2_0.TodoItem.self]
  }

  public struct HistoryEntry: Sendable, Codable {
    let summary: String
    let isChecked: Bool
  }

  public struct EditHistory: Sendable, Codable {
    var history: [Date: HistoryEntry]

    public init(history: [Date: HistoryEntry]) {
      self.history = history
    }

    // ╔═════════╗
    // ║ CODABLE ║
    // ╚═════════╝

    enum CodingKeys: String, CodingKey {
      case history, lastAccess
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      /// converted dates into strings
      let encoded = self.history.mapKeys { key in ISO8601DateFormatter().string(from: key) }
      try container.encode(encoded, forKey: .history)
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      /// we'll need to convert strings back into dates
      let encoded = try container.decode([String: HistoryEntry].self, forKey: .history)
      self.history = encoded.mapKeys { key in ISO8601DateFormatter().date(from: key) ?? Date() }
    }
  }

  @Model public final class TodoItem: CollectionDocument, Codable {
    /// The Schema version
    public var v: String
    /// If you plan to reuse the data with other databases in the future, you might consider adding a uid.
    /// Directly use the UUID type, as SQLite supports this type, which would result in smaller storage consumption.
    ///
    /// ❗️ Do not define an `id` variable because it will clash with the `id: PersistentIdentifier` added by `@Model` macro.
    public var uid: UUID
    public var dateCreated: Date
    public var dateUpdated: Date
    public var dateChecked: Date?
    public var summary: String
    public var isChecked: Bool
    public var editHistory: EditHistory

    public init(
      uid: UUID,
      dateCreated: Date,
      dateUpdated: Date,
      dateChecked: Date?,
      summary: String,
      isChecked: Bool,
      editHistory: EditHistory
    ) {
      self.v = versionIdentifier.description
      self.uid = uid
      self.dateCreated = dateCreated
      self.dateUpdated = dateUpdated
      self.dateChecked = dateChecked
      self.summary = summary
      self.isChecked = isChecked
      self.editHistory = editHistory
    }

    // ╔═════════╗
    // ║ CODABLE ║
    // ╚═════════╝

    enum CodingKeys: String, CodingKey {
      case v, uid, dateCreated, dateUpdated, dateChecked, summary, isChecked, editHistory
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(self.v, forKey: .v)
      try container.encode(self.uid, forKey: .uid)
      try container.encode(self.dateCreated, forKey: .dateCreated)
      try container.encode(self.dateUpdated, forKey: .dateUpdated)
      try container.encodeIfPresent(self.dateChecked, forKey: .dateChecked)
      try container.encode(self.summary, forKey: .summary)
      try container.encode(self.isChecked, forKey: .isChecked)
      try container.encode(self.editHistory, forKey: .editHistory)
    }

    public required init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.v = try container.decode(String.self, forKey: .v)
      self.uid = try container.decode(UUID.self, forKey: .uid)
      self.dateCreated = try container.decode(Date.self, forKey: .dateCreated)
      self.dateUpdated = try container.decode(Date.self, forKey: .dateUpdated)
      self.dateChecked = try container.decodeIfPresent(Date.self, forKey: .dateChecked)
      self.summary = try container.decode(String.self, forKey: .summary)
      self.isChecked = try container.decode(Bool.self, forKey: .isChecked)
      self.editHistory = try container.decode(EditHistory.self, forKey: .editHistory)
    }
  }

  public static func insertMocks(context: ModelContext) {
    let mock = Schema1_2_0.TodoItem(
      uid: UUID(),
      dateCreated: Date(),
      dateUpdated: Date(),
      dateChecked: Date(),
      summary: "Test",
      isChecked: false,
      editHistory: EditHistory(history: [:])
    )
    context.insert(mock)
    try! context.save()
  }
}

enum MigrateTo1_2_0: MigrationStep {
  static let toVersion: any VersionedSchema.Type = Schema1_2_0.self

  nonisolated(unsafe) static var retainer: [Schema1_1_0.TodoItem] = []

  /// See related `VersionedSchema` enums for differences
  static let stage = MigrationStage.custom(
    fromVersion: Schema1_1_0.self,
    toVersion: Schema1_2_0.self,
    willMigrate: { modelContext in
      let oldSaves = try modelContext.fetch(FetchDescriptor<Schema1_1_0.TodoItem>())
      MigrateTo1_2_0.retainer.append(contentsOf: oldSaves)
      for oldSave in oldSaves {
        modelContext.delete(oldSave)
      }
      try modelContext.save()
    },
    didMigrate: { modelContext in
      for oldSave in MigrateTo1_2_0.retainer {
        let newSave = Schema1_2_0.TodoItem(
          uid: oldSave.uid,
          dateCreated: oldSave.dateCreated,
          dateUpdated: oldSave.dateUpdated,
          dateChecked: oldSave.dateChecked,
          summary: oldSave.summary,
          isChecked: oldSave.isChecked,
          editHistory: Schema1_2_0.EditHistory(history: [:])
        )
        modelContext.insert(newSave)
      }
      try modelContext.save()
      MigrateTo1_2_0.retainer.removeAll()
    }
  )
}

import DatabaseKit
import Foundation
import SwiftData
import SwiftUI

public enum Schema1_0_0: VersionedSchema, MockableSchema {
  public static let versionIdentifier = Schema.Version(1, 0, 0)

  public static var models: [any PersistentModel.Type] {
    [Schema1_0_0.TodoItem.self]
  }

  @Model public final class TodoItem: CollectionDocument, Codable {
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
    
    public init(
      uid: UUID,
      dateCreated: Date,
      dateUpdated: Date,
      dateChecked: Date?,
      summary: String,
      isChecked: Bool
    ) {
      self.uid = uid
      self.dateCreated = dateCreated
      self.dateUpdated = dateUpdated
      self.dateChecked = dateChecked
      self.summary = summary
      self.isChecked = isChecked
    }
    
    public init(summary: String) {
      self.uid = UUID()
      self.dateCreated = Date()
      self.dateUpdated = Date()
      self.dateChecked = nil
      self.summary = summary
      self.isChecked = false
    }
    
    // ╔═════════╗
    // ║ CODABLE ║
    // ╚═════════╝
    
    enum CodingKeys: String, CodingKey {
      case uid, dateCreated, dateUpdated, dateChecked, summary, isChecked
    }
    
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(self.uid, forKey: .uid)
      try container.encode(self.dateCreated, forKey: .dateCreated)
      try container.encode(self.dateUpdated, forKey: .dateUpdated)
      try container.encodeIfPresent(self.dateChecked, forKey: .dateChecked)
      try container.encode(self.summary, forKey: .summary)
      try container.encode(self.isChecked, forKey: .isChecked)
    }
    
    public required init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.uid = try container.decode(UUID.self, forKey: .uid)
      self.dateCreated = try container.decode(Date.self, forKey: .dateCreated)
      self.dateUpdated = try container.decode(Date.self, forKey: .dateUpdated)
      self.dateChecked = try container.decodeIfPresent(Date.self, forKey: .dateChecked)
      self.summary = try container.decode(String.self, forKey: .summary)
      self.isChecked = try container.decode(Bool.self, forKey: .isChecked)
    }
  }
  
  public static func insertMocks(context: ModelContext) {
    let mock = Schema1_0_0.TodoItem(summary: "test")
    context.insert(mock)
    try! context.save()
  }
}

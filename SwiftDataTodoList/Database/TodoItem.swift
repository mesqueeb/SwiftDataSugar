import Foundation
import SwiftData

@Model public final class TodoItem: Equatable, CollectionDocument {
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

  public init(summary: String) {
    self.uid = UUID()
    self.dateCreated = Date()
    self.dateUpdated = Date()
    self.dateChecked = nil
    self.summary = summary
    self.isChecked = false
  }

  public static func == (lhs: TodoItem, rhs: TodoItem) -> Bool {
    lhs.uid == rhs.uid
  }

  public static func query(searchText: String = "", showChecked: Bool = true) -> Predicate<TodoItem>? {
    let q = searchText.lowercased()
    if q.isEmpty && showChecked {
      return nil
    }
    if q.isEmpty && !showChecked {
      return #Predicate<TodoItem> { item in
        item.isChecked == false
      }
    }
    if !q.isEmpty && showChecked {
      return #Predicate<TodoItem> { item in
        item.summary.localizedStandardContains(q)
      }
    }
    if !q.isEmpty && !showChecked {
      return #Predicate<TodoItem> { item in
        item.summary.localizedStandardContains(q) && item.isChecked == false
      }
    }
    return nil
  }
}

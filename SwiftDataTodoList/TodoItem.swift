import Foundation
import SwiftData

@Model public final class TodoItem: Identifiable, Equatable {
  @Attribute(.unique) public let id: String
  public let dateCreated: Date
  public var dateUpdated: Date?
  public var dateChecked: Date?
  public var summary: String
  public var isChecked: Bool

  public init(summary: String) {
    self.id = UUID().uuidString
    self.dateCreated = Date()
    self.dateUpdated = nil
    self.dateChecked = nil
    self.summary = summary
    self.isChecked = false
  }

  public static func == (lhs: TodoItem, rhs: TodoItem) -> Bool {
    lhs.id == rhs.id
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

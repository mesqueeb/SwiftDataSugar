import DatabaseKit
import Foundation
import SwiftData

public typealias TodoItem = LatestSchema.TodoItem
let currentVersion: String = LatestSchema.versionIdentifier.description

public extension TodoItem {
  convenience init(summary: String) {
    self.init(
      uid: UUID(),
      dateCreated: Date(),
      dateUpdated: Date(),
      dateChecked: nil,
      summary: summary,
      isChecked: false,
      editHistory: EditHistory(history: [:])
    )
  }

  /// QUERY
  static func query(searchText: String = "", showChecked: Bool = true) -> Predicate<TodoItem>? {
    let q = searchText.lowercased()
    if q.isEmpty, showChecked {
      return nil
    }
    if q.isEmpty, !showChecked {
      return #Predicate<TodoItem> { item in
        item.isChecked == false
      }
    }
    if !q.isEmpty, showChecked {
      return #Predicate<TodoItem> { item in
        item.summary.localizedStandardContains(q)
      }
    }
    if !q.isEmpty, !showChecked {
      return #Predicate<TodoItem> { item in
        item.summary.localizedStandardContains(q) && item.isChecked == false
      }
    }
    return nil
  }
}

public struct TodoItemSnapshot: Codable, Sendable {
  public var v: String
  public var uid: UUID
  public var dateCreated: Date
  public var dateUpdated: Date
  public var dateChecked: Date?
  public var summary: String
  public var isChecked: Bool
  public var editHistory: EditHistory

  public init(
    v: String,
    uid: UUID,
    dateCreated: Date,
    dateUpdated: Date,
    dateChecked: Date?,
    summary: String,
    isChecked: Bool,
    editHistory: EditHistory
  ) {
    self.v = v
    self.uid = uid
    self.dateCreated = dateCreated
    self.dateUpdated = dateUpdated
    self.dateChecked = dateChecked
    self.summary = summary
    self.isChecked = isChecked
    self.editHistory = editHistory
  }

  public init(summary: String) {
    self.init(
      v: currentVersion,
      uid: UUID(),
      dateCreated: Date(),
      dateUpdated: Date(),
      dateChecked: nil,
      summary: summary,
      isChecked: false,
      editHistory: EditHistory()
    )
  }
}

extension TodoItem: SendableDocument {
  public typealias SendableType = TodoItemSnapshot

  public convenience init(from snapshot: SendableType) {
    self.init(
      uid: snapshot.uid,
      dateCreated: snapshot.dateCreated,
      dateUpdated: snapshot.dateUpdated,
      dateChecked: snapshot.dateChecked,
      summary: snapshot.summary,
      isChecked: snapshot.isChecked,
      editHistory: snapshot.editHistory
    )
  }

  public func toSendable() -> SendableType {
    return SendableType(
      v: self.v,
      uid: uid,
      dateCreated: dateCreated,
      dateUpdated: dateUpdated,
      dateChecked: dateChecked,
      summary: summary,
      isChecked: isChecked,
      editHistory: editHistory
    )
  }
}

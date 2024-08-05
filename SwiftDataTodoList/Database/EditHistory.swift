import DatabaseKit
import Foundation
import SwiftData

public typealias EditHistory = LatestSchema.EditHistory
public typealias HistoryEntry = LatestSchema.HistoryEntry

public extension EditHistory {
  init() {
    self.history = [:]
  }

  mutating func addEntry(from: TodoItem) {
    let entry = HistoryEntry(from: from)
    let date = from.dateUpdated
    history[date] = entry
  }
}

public extension HistoryEntry {
  init(from: TodoItem) {
    self.init(summary: from.summary, isChecked: from.isChecked)
  }
}

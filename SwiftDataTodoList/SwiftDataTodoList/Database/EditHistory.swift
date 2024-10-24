import SwiftDataSugar
import Foundation
import SwiftData

public typealias EditHistory = LatestSchema.EditHistory
public typealias HistoryEntry = LatestSchema.HistoryEntry

extension EditHistory {
  public init() { self.history = [:] }

  public mutating func addEntry(from: TodoItem) {
    let entry = HistoryEntry(from: from)
    let date = from.dateUpdated
    history[date] = entry
  }
}

extension HistoryEntry {
  public init(from: TodoItem) { self.init(summary: from.summary, isChecked: from.isChecked) }
}

import Foundation
import SwiftData

extension MigrationStage: @unchecked @retroactive Sendable {}
extension Schema.Version: @unchecked @retroactive Sendable {}

public protocol MockableSchema {
  static func insertMocks(context: ModelContext)
}

enum MigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] {
    [
      Schema1_0_0.self,
      Schema1_1_0.self,
    ]
  }

  private nonisolated(unsafe) static var migration1_0_0Retainer: [Schema1_0_0.TodoItem] = []

  /// See related `VersionedSchema` enums for differences
  static let migrate1_0_0to1_1_0 = MigrationStage.custom(
    fromVersion: Schema1_0_0.self,
    toVersion: Schema1_1_0.self,
    willMigrate: { modelContext in
      let oldSaves = try modelContext.fetch(FetchDescriptor<Schema1_0_0.TodoItem>())
      migration1_0_0Retainer.append(contentsOf: oldSaves)
      for oldSave in oldSaves {
        modelContext.delete(oldSave)
      }
      try modelContext.save()
    },
    didMigrate: { modelContext in
      for oldSave in migration1_0_0Retainer {
        let newSave = Schema1_1_0.TodoItem(
          uid: oldSave.uid,
          dateCreated: oldSave.dateCreated,
          dateUpdated: oldSave.dateUpdated,
          dateChecked: oldSave.dateChecked,
          summary: oldSave.summary,
          isChecked: oldSave.isChecked,
          editHistory: EditHistory()
        )
        modelContext.insert(newSave)
      }
      try modelContext.save()
      migration1_0_0Retainer.removeAll()
    }
  )

  static var stages: [MigrationStage] {
    [migrate1_0_0to1_1_0]
  }
}

import Foundation
import SwiftData

struct MigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] {
    [
      Schema1_0_0.self,
      MigrateTo1_1_0.toVersion,
      MigrateTo1_2_0.toVersion
    ]
  }

  static var stages: [MigrationStage] {
    [MigrateTo1_1_0.stage, MigrateTo1_2_0.stage]
  }
}

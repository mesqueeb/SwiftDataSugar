import Foundation
import SwiftData

/// Use like this:
/// ```swift
/// @MainActor public let modelContainer = initModelContainer(
///   for: TodoListSchema1_0_0.self,
///   with: TodoListMigrationPlan.self,
///   inMemory: false
/// )
/// ```
public func initModelContainer(
  for schema: VersionedSchema.Type,
  with migrationPlan: (any SchemaMigrationPlan.Type)?,
  inMemory: Bool = false,
  storeUrl: URL? = nil
) -> ModelContainer {
  let schema = SwiftData.Schema(versionedSchema: schema)
  let config = if inMemory {
    ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
  } else if let storeUrl {
    ModelConfiguration(schema: schema, url: storeUrl)
  } else {
    ModelConfiguration(schema: schema)
  }
  do {
    if inMemory {
      return try SwiftData.ModelContainer(
        for: schema,
        configurations: [config]
      )
    }
    return try SwiftData.ModelContainer(
      for: schema,
      migrationPlan: migrationPlan,
      configurations: [config]
    )
  } catch {
    // it's always good to try twice. See: https://forums.developer.apple.com/forums/thread/758275?answerId=797470022#797470022
    return try! SwiftData.ModelContainer(
      for: schema,
      migrationPlan: migrationPlan,
      configurations: [config]
    )
  }
}

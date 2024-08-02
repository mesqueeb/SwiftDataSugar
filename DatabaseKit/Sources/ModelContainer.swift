import SwiftData

/// Use like this:
/// ```swift
/// @MainActor public let modelContainer = initModelContainer(
///   for: TodoItem.self,
///   with: MigrationPlanSaveData.self,
///   inMemory: false
/// )
/// ```
public func initModelContainer<T: PersistentModel & CollectionDocument, M: SchemaMigrationPlan>(
  for type: T.Type,
  with migrationPlan: M.Type,
  inMemory: Bool
) -> ModelContainer {
  do {
    if inMemory {
      return try ModelContainer(
        for: SwiftData.Schema([type]),
        configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
      )
    }
    return try ModelContainer(
      for: SwiftData.Schema([type]),
      migrationPlan: migrationPlan
    )
  } catch {
    // it's always good to try twice. See: https://forums.developer.apple.com/forums/thread/758275?answerId=797470022#797470022
    return try! ModelContainer(
      for: SwiftData.Schema([type]),
      migrationPlan: migrationPlan
    )
  }
}

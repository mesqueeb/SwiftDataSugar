import DatabaseKit
import Foundation
import SwiftData
@testable import SwiftDataTodoList
import Testing

final class MigrationTests {
  var url: URL!
  var container: ModelContainer!
  var context: ModelContext!

  // TODO: I’m not sure if you can migrate in memory DB, as they’re deleted when closed and you need to close and reopen to migrate afaik.
  func initModelContainer<VS: VersionedSchema & MockableSchema>(
    for schema: VS.Type,
    with migrationPlan: (any SchemaMigrationPlan.Type)?
  ) -> ModelContainer {
    let schema = SwiftData.Schema(versionedSchema: schema)
    let config = ModelConfiguration(schema: schema, url: url)
    return try! SwiftData.ModelContainer(
      for: schema,
      migrationPlan: migrationPlan,
      configurations: [config]
    )
  }

  init() {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    url = FileManager.default.temporaryDirectory.appending(component: "default.store")
  }

  deinit {
    // Put teardown code here. This method is called after the invocation of each test method in the class.

    // Cleanup resources
    self.container = nil
    self.context = nil

    // Delete database
    try? FileManager.default.removeItem(at: url)
    try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("store-shm"))
    try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("store-wal"))
  }

  @Test func migrateTo1_1_0() async throws {
    struct RelevantMigrationPlan: SchemaMigrationPlan {
      static var schemas: [any VersionedSchema.Type] { [Schema1_0_0.self, MigrateTo1_1_0.toVersion] }
      static var stages: [MigrationStage] { [MigrateTo1_1_0.stage] }
    }

    container = initModelContainer(for: Schema1_0_0.self, with: nil)
    context = ModelContext(container)

    Schema1_0_0.insertMocks(context: context)
    let oldRecords = try context.fetch(FetchDescriptor<Schema1_0_0.TodoItem>())

    #expect(oldRecords.count == 1, "mocks not inserted or cleaned up")

    // ============================================================
    // Perform the migration by reinitialising the model container!
    // ============================================================

    container = initModelContainer(for: Schema1_1_0.self, with: RelevantMigrationPlan.self)
    context = ModelContext(container)

    let newRecords = try context.fetch(FetchDescriptor<Schema1_1_0.TodoItem>())
    #expect(newRecords.allSatisfy { $0.editHistory.history.isEmpty })
    #expect(oldRecords.count == newRecords.count, "Number of records before and after migration are different.")
  }

  @Test func migrateTo1_2_0() async throws {
    struct RelevantMigrationPlan: SchemaMigrationPlan {
      static var schemas: [any VersionedSchema.Type] { [Schema1_1_0.self, MigrateTo1_2_0.toVersion] }
      static var stages: [MigrationStage] { [MigrateTo1_2_0.stage] }
    }

    container = initModelContainer(for: Schema1_1_0.self, with: nil)
    context = ModelContext(container)

    Schema1_1_0.insertMocks(context: context)
    let oldRecords = try context.fetch(FetchDescriptor<Schema1_1_0.TodoItem>())

    #expect(oldRecords.count == 1, "mocks not inserted or cleaned up")

    // ============================================================
    // Perform the migration by reinitialising the model container!
    // ============================================================

    container = initModelContainer(for: Schema1_2_0.self, with: RelevantMigrationPlan.self)
    context = ModelContext(container)

    let newRecords = try context.fetch(FetchDescriptor<Schema1_2_0.TodoItem>())
    #expect(newRecords.allSatisfy { $0.v == "1.2.0" })
    #expect(oldRecords.count == newRecords.count, "Number of records before and after migration are different.")
  }
}

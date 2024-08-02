import Foundation
import SwiftData
@testable import SwiftDataTodoList
import Testing

final class MigrationTests {
  var url: URL!
  var container: ModelContainer!
  var context: ModelContext!

  // TODO: I’m not sure if you can migrate in memory DB, as they’re deleted when closed and you need to close and reopen to migrate afaik.
  func initModelContainer<VS: VersionedSchema & MockableSchema, M: SchemaMigrationPlan>(
    for schema: VS.Type,
    with migrationPlan: M.Type
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

  @Test func testMigration1_0_0to1_1_0() async throws {
    container = initModelContainer(for: Schema1_0_0.self, with: MigrationPlan.self)
    context = ModelContext(container)

    Schema1_0_0.insertMocks(context: context)
    let records1_0_0 = try context.fetch(FetchDescriptor<Schema1_0_0.TodoItem>())

    #expect(records1_0_0.count == 1, "mocks not inserted")

    // Migration 1_0_0 → 1_1_0
    container = initModelContainer(for: Schema1_1_0.self, with: MigrationPlan.self)
    context = ModelContext(container)

    // Assert: schema changes
    let records1_1_0 = try context.fetch(FetchDescriptor<Schema1_1_0.TodoItem>())
    #expect(records1_1_0.allSatisfy { $0.editHistory.history.isEmpty })

    // Assert: there are the same number of records before and after the migration
    #expect(records1_0_0.count == records1_1_0.count, "Number of records before and after migration are different.")
  }
}

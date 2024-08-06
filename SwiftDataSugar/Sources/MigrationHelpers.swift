import Foundation
import SwiftData

extension MigrationStage: @unchecked Sendable {}
extension Schema.Version: @unchecked Sendable {}

/// A MockableSchema forces you to add a `insertMocks` method to your schema in which you add a mocked record to a given context.actor
/// This method can be used during migration testing.
///
/// Example:
/// ```swift
/// public enum Schema1_0_0: VersionedSchema, MockableSchema {
///   public static let versionIdentifier = Schema.Version(1, 0, 0)
///   public static var models: [any PersistentModel.Type] { [Schema1_0_0.TodoItem.self] }
///   @Model public final class TodoItem: CollectionDocument, Codable {
///     // ...
///   }
///   public static func insertMocks(context: ModelContext) {
///     let mock = Schema1_0_0.TodoItem(/* ... */)
///     context.insert(mock)
///     try! context.save()
///   }
/// }
/// ```
public protocol MockableSchema {
  static func insertMocks(context: ModelContext)
}

/// A single step of migration, a protocol to be implemented to help with defining migrations.
/// Actual use of each step can be as simple as:
/// ```swift
/// // you could define each of the steps in the file where you define the relevant schema
/// enum MigrateTo1_1_0: MigrationStep {
///   static let toVersion: any VersionedSchema.Type = Schema1_1_0.self
///   static let stage = MigrationStage.custom(/* ... */)
/// }
///
/// // your eventual migration plan can now stay super clean
/// struct MyMigrationPlan: SchemaMigrationPlan {
///   static var schemas: [any VersionedSchema.Type] { [
///     Schema1_0_0.self, // the base version
///     MigrateTo1_1_0.toVersion
///     // ... add other versions here
///   ] }
///   static var stages: [MigrationStage] { [
///     MigrateTo1_1_0.stage
///     // ... add other stages here
///   ] }
/// }
/// ```
public protocol MigrationStep {
  /// Migrate to which schema
  static var toVersion: any VersionedSchema.Type { get }
  /// The migration function
  static var stage: MigrationStage { get }
}

import Foundation
import SwiftData

/// Makes sure there's a `uid` and `dateUpdated` because it's required for `DbCollection`
///
/// You wanna conform to this as part of your VersionedSchema `@Model`. Eg.
/// ```swift
/// @Model public final class TodoItem: CollectionDocument {
///   public var uid: UUID
///   public var dateUpdated: Date
///   // ...
/// }
/// ```
///
/// # General Advice for your @Models
///
/// - You must use a versioned schema from the start.
///   - Creating a migration from a non-versioned @Model to one in a `VersionedSchema` will not work correctly. In this case best to start over by choosing a different class name for your model.
/// - You must not implement manual `Equatable` conformance on your models, because this will mess with the Migration code and give errors.
public protocol CollectionDocument {
  /// Make sure there is a unique ID assigned to each document different from the `Model` added `id: PersistentIdentifier`
  ///
  /// This is because, we cannot always rely on the `id: PersistentIdentifier` to be the same across threads and sessions
  var uid: UUID { get }
  /// Make sure this field exists on all documents to automatically keep track of the last date this document was edited
  var dateUpdated: Date { get set }
}

/// Makes sure there's a `sendableType` defined because it's required for `DbCollection`
///
/// For this conformance it's O.K. to define it as an extension outside of your VersionedSchema. Eg.
/// ```swift
/// extension TodoItem: SendableDocument {
///   public typealias SendableType = TodoItemSnapshot
///
///   public convenience init(from snapshot: SendableType) {
///     self.init(
///       uid: snapshot.uid,
///       dateUpdated: snapshot.dateUpdated,
///       // ...
///     )
///   }
///
///   public func toSendable() -> SendableType {
///     return SendableType(
///       uid: uid,
///       dateUpdated: dateUpdated,
///       // ...
///     )
///   }
/// }
/// ```
public protocol SendableDocument {
  /// Make sure the collection document can be initialised from a sendable type
  associatedtype SendableType: Sendable
  init(from sendable: SendableType)
  func toSendable() -> SendableType
}

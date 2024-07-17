import SwiftData
import SwiftUI

public struct DbQuery<T, Content: View>: View where T: PersistentModel, T: Timestamped {
  @Query private var items: [T]

  let content: (_ item: T) -> Content

  public init(
    predicate: Predicate<T>? = nil,
    sortBy: [SortDescriptor<T>] = [],
    fetchLimit: Int? = nil,
    @ViewBuilder content: @escaping (_ item: T) -> Content // Slot Content
  ) {
    var descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
    if let fetchLimit { descriptor.fetchLimit = fetchLimit }

    _items = Query(descriptor)
    self.content = content
  }

  public var body: some View {
    ForEach(items, id: \.id) { item in
      self.content(item)
        .id(item.id) // Use ID for List reordering and animations
    }
  }
}

import SwiftData
import SwiftUI

public struct DbQuery<T, Content: View>: View where T: PersistentModel, T: Timestamped {
  @Environment(\.modelContext) private var modelContext
  @Query private var items: [T]
  @State private var docs: [PersistentIdentifier: DbDocument<T>]

  let content: (_ item: T, _ doc: DbDocument<T>) -> Content

  public init(
    predicate: Predicate<T>? = nil,
    sortBy: [SortDescriptor<T>] = [],
    fetchLimit: Int? = nil,
    @ViewBuilder content: @escaping (_ item: T, _ doc: DbDocument<T>) -> Content // Slot Content
  ) {
    var descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
    if let fetchLimit { descriptor.fetchLimit = fetchLimit }

    _items = Query(descriptor)
    _docs = State(initialValue: [:])
    for item in _items.wrappedValue {
      print("item.id \(item.id)")
    }
    self.content = content
  }

  public var body: some View {
    ForEach(items, id: \.id) { item in
      if let doc = docs[item.id] {
        self.content(item, doc)
          .id(item.id) // Use ID for List reordering and animations
      } else {
        EmptyView()
      }
    }
    .onChange(of: items, initial: true) { _, newItems in
      for item in newItems {
        docs[item.id] = try! DbDocument(modelContainer: sharedModelContainer, id: item.id)
      }
    }
    // .onAppear {
    //   for item in items {
    //     docs[item.id] = try! DbDocument(modelContainer: sharedModelContainer, id: item.id)
    //   }
    // }
  }
}

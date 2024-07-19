import SwiftData
import SwiftUI

public struct TodoItemDetailsView: View {
  @Environment(\.modelContext) private var modelContext
  let item: TodoItem
  let doc: DbDocument<TodoItem>

  public init(item: TodoItem, doc: DbDocument<TodoItem>) {
    self.item = item
    self.doc = doc
  }

  public var body: some View {
    Text(item.summary)

    TodoListItemView(item: item, doc: doc)
  }
}

// #Preview {
//   TodoListItemView(item: TodoItem(summary: "Hello"))
// }

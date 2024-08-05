import SwiftData
import SwiftUI

public struct TodoItemDetailsView: View {
  let item: TodoItem

  public init(item: TodoItem) {
    self.item = item
  }

  public var body: some View {
    Text(item.summary)

    Text("edit history versions: \(item.editHistory.history.count)")
    Text("schema version: \(item.v)")

    TodoListItemView(item: item)
  }
}

#Preview {
  TodoListItemView(item: TodoItem(summary: "Hello"))
}

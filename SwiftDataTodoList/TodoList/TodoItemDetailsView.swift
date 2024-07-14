import SwiftData
import SwiftUI

public struct TodoItemDetailsView: View {
  let item: TodoItem

  public init(item: TodoItem) {
    self.item = item
  }

  public var body: some View {
    Text(item.summary)
  }
}

#Preview {
  TodoListItemView(item: TodoItem(summary: "Hello"))
}

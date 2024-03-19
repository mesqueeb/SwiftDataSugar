import SwiftData
import SwiftUI

public struct TodoItemView: View {
  let item: TodoItem

  public init(item: TodoItem) {
    self.item = item
  }

  public var body: some View {
    Text(item.summary)
  }
}

#Preview {
  TodoItemView(item: TodoItem(summary: "Hello"))
}

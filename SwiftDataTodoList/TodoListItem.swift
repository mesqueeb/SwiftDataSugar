import SwiftData
import SwiftUI

struct TodoListItem: View {
  let item: TodoItem

  @State private var isEditing: Bool = false

  private var editingSummary: Binding<String> {
    Binding<String>(
      get: { item.summary },
      set: { newValue in
        dbTodo.update(id: item.id, \.summary, newValue)
      }
    )
  }

  private func toggleChecked(_ item: TodoItem) {
    withAnimation {
      let newValue = !item.isChecked
      dbTodo.update(id: item.id, \.isChecked, newValue)
      dbTodo.update(id: item.id, \.dateChecked, newValue ? Date() : nil)
      dbTodo.update(id: item.id, \.dateUpdated, Date())
    }
  }

  private func deleteItem(_ item: TodoItem) {
    withAnimation {
      dbTodo.delete(id: item.id)
    }
  }

  private func finishEditing() {
    dbTodo.update(id: item.id, \.dateUpdated, Date())
    isEditing = false
  }

  var body: some View {
    HStack {
      Button(action: { toggleChecked(item) }) {
        Image(systemName: item.isChecked ? "checkmark.square" : "square")
      }

      if isEditing {
        CInput(modelValue: editingSummary, placeholder: "...", revertOnExit: true, autoFocus: true, onBlur: finishEditing)
          .onSubmit(finishEditing)
          .padding(CGFloat(4))
          .frame(maxWidth: .infinity, alignment: .leading) // Make text take up as much space as possible
      } else {
        Button(action: { isEditing = true }) {
          Text(item.summary)
            .strikethrough(item.isChecked, color: .gray)
            .padding(CGFloat(4))
            .frame(maxWidth: .infinity, alignment: .leading) // Make text take up as much space as possible
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        Button(action: { isEditing = true }) {
          Image(systemName: "pencil")
        }
      }
      Button(action: { deleteItem(item) }) {
        Image(systemName: "trash")
      }
    }
  }
}

#Preview {
  TodoListItem(item: TodoItem(summary: "Hello it's me"))
    .modelContainer(for: TodoItem.self, inMemory: true)
}

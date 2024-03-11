import SwiftData
import SwiftUI

struct TodoListItem: View {
  let item: TodoItem
  let refresh: () -> Void

  @State private var isEditing: Bool = false

  private var editingSummary: Binding<String> {
    Binding<String>(
      get: { item.summary },
      set: { newValue in
        item.summary = newValue
        item.dateUpdated = Date()
      }
    )
  }

  private func toggleChecked(_ item: TodoItem) {
    withAnimation {
      let newValue = !item.isChecked
      item.isChecked = newValue
      item.dateChecked = newValue ? Date() : nil
      item.dateUpdated = Date()
    }
  }

  private func deleteItem(_ item: TodoItem) {
    _ = withAnimation {
      Task.detached {
        do {
          try await dbTodo.delete(id: item.id)
          refresh()
        } catch {
          print("error →", error)
        }
      }
    }
  }

  var body: some View {
    HStack {
      Button(action: { toggleChecked(item) }) {
        Image(systemName: item.isChecked ? "checkmark.square" : "square")
      }

      if isEditing {
        CInput(modelValue: editingSummary, placeholder: "...", autoFocus: true, onBlur: { isEditing = false })
          .onSubmit { isEditing = false }
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
  TodoListItem(item: TodoItem(summary: "Hello it's me"), refresh: { print("refreshed") })
    .modelContainer(for: TodoItem.self, inMemory: true)
}

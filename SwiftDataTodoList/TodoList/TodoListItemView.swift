import SwiftData
import SwiftUI

public struct TodoListItemView: View {
  let item: TodoItem
  let id: PersistentIdentifier

  public init(item: TodoItem) {
    self.item = item
    self.id = item.id
  }

  @Environment(\.openWindow) private var openWindow
  @State private var isEditing: Bool = false

  private var editingSummary: Binding<String> {
    Binding<String>(
      get: { item.summary },
      set: { newValue in
        Task.detached { try await dbTodos.update(id: id) { data in
          data.summary = newValue
        } }
      }
    )
  }

  private func toggleChecked(_ item: TodoItem) {
    withAnimation {
      let newValue = !item.isChecked
      Task.detached {
        try await dbTodos.update(id: id) { data in
          data.isChecked = newValue
          data.dateChecked = newValue ? Date() : nil
        }
      }
    }
  }

  /// Prevent a crash when the same delete button is clicked rapidly
  @State private var isDeleting = false
  private func deleteItem(_ item: TodoItem) {
    isDeleting = true
    _ = withAnimation {
      Task { try await dbTodos.delete(id: id) }
    }
  }

  private func finishEditing() {
    Task.detached {
      try await dbTodos.update(id: id) { data in
        data.dateUpdated = Date()
        data.editHistory.addEntry(from: data)
      }
      Task { @MainActor in self.isEditing = false }
    }
  }

  public var body: some View {
    HStack {
      CButton(action: { toggleChecked(item) }) {
        Image(systemName: item.isChecked ? "checkmark.square" : "square")
      }.disabled(isDeleting)

      if isEditing {
        CInput(modelValue: editingSummary, placeholder: "...", revertOnExit: true, autoFocus: true, onBlur: finishEditing)
          .onSubmit(finishEditing)
          .padding(CGFloat(4))
          .frame(maxWidth: .infinity, alignment: .leading) // Make text take up as much space as possible
          .disabled(isDeleting)
      } else {
        Text(item.summary)
          .strikethrough(item.isChecked, color: .gray)
          .padding(CGFloat(4))
          .frame(maxWidth: .infinity, alignment: .leading) // Make text take up as much space as possible
          .contentShape(Rectangle())
          .gesture(
            TapGesture(count: 2).onEnded {
              openWindow(id: "item", value: item.uid)
            }.exclusively(before: TapGesture(count: 1).onEnded {
              isEditing = true
            })
          )

        CButton(action: { isEditing = true }) {
          Image(systemName: "pencil")
        }.disabled(isDeleting)
      }
      CButton(action: { deleteItem(item) }) {
        Image(systemName: "trash")
      }.disabled(isDeleting)
    }
    .padding(.horizontal, 16)
  }
}

#Preview {
  TodoListItemView(item: TodoItem(summary: "Hello it's me"))
    .modelContainer(for: TodoItem.self, inMemory: true)
}

import SwiftData
import SwiftUI

struct TodoListItemView: View {
  @Environment(\.modelContext) private var modelContext
  let item: TodoItem
  let doc: DbDocument<TodoItem>

  @Environment(\.openWindow) private var openWindow
  @State private var isEditing: Bool = false

  private var editingSummary: Binding<String> {
    Binding<String>(
      get: { item.summary },
      set: { newValue in
        Task { try await doc.update { $0.summary = newValue } }
      }
    )
  }

  private func toggleChecked(_ item: TodoItem) {
    withAnimation {
      let newValue = !item.isChecked
      Task {
        try await doc.update { data in
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
    withAnimation {
      Task { try await doc.delete() }
    }
  }

  private func finishEditing() {
    Task {
      try await doc.update { $0.dateUpdated = Date() }
      isEditing = false
    }
  }

  var body: some View {
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

// #Preview {
//   TodoListItemView(item: TodoItem(summary: "Hello it's me"))
//     .modelContainer(for: TodoItem.self, inMemory: true)
// }

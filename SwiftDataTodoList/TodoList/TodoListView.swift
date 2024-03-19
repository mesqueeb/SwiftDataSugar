import SwiftData
import SwiftUI

typealias Option<T: Hashable> = (label: String, value: T)

let sortOptions: [Option<[SortDescriptor<TodoItem>]>] = [
  (label: "Date Added", value: [SortDescriptor<TodoItem>(\.dateCreated, order: .forward)]),
  (label: "A-Z", value: [SortDescriptor<TodoItem>(\.summary, order: .forward)]),
  (label: "Z-A", value: [SortDescriptor<TodoItem>(\.summary, order: .reverse)])
]

struct TodoListView: View {
  @State private var activeSort: [SortDescriptor<TodoItem>] = sortOptions[0].value
  @State private var searchText: String = ""
  @State private var showChecked: Bool = true

  var activePredicate: Predicate<TodoItem>? { TodoItem.query(searchText: searchText, showChecked: showChecked) }

  @State private var newItemSummary: String = ""

  private func addItem() {
    withAnimation {
      let data = TodoItem(summary: newItemSummary)
      Task {
        try await dbTodo.insert(data)
        newItemSummary = ""
      }
    }
  }

  var body: some View {
    VStack {
      List {
        SwiftDataQuery(predicate: activePredicate, sortBy: activeSort) { item in
          TodoListItem(item: item)
        }
      }
      .searchable(text: $searchText)
      .toolbar {
        Menu {
          Picker("Sort Order", selection: $activeSort) {
            ForEach(sortOptions, id: \.label) { option in Text(option.label).tag(option.value) }
          }
          Picker("Filter", selection: $showChecked) {
            Text("Show All").tag(true)
            Text("Hide Checked Items").tag(false)
          }
        } label: { Label("Sort", systemImage: "arrow.up.arrow.down") }
          .pickerStyle(.inline)
      }
      .toolbar { CrashTests() }
      HStack {
        CInput(modelValue: $newItemSummary, placeholder: "New Item", onSubmit: addItem)
          .textFieldStyle(RoundedBorderTextFieldStyle())

        Button(action: addItem) {
          Image(systemName: "plus")
        }
      }
      .padding()
    }
  }
}

#Preview {
  TodoListView()
    .modelContainer(for: TodoItem.self, inMemory: true)
}

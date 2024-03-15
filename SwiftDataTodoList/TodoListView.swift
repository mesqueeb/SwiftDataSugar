import SwiftData
import SwiftUI

typealias Option<T: Hashable> = (label: String, value: T)

let sortOptions: [Option<[SortDescriptor<TodoItem>]>] = [
  (label: "Date Added", value: [SortDescriptor<TodoItem>(\.dateCreated, order: .forward)]),
  (label: "A-Z", value: [SortDescriptor<TodoItem>(\.summary, order: .forward)]),
  (label: "Z-A", value: [SortDescriptor<TodoItem>(\.summary, order: .reverse)])
]

struct TodoListView: View {
  // @Environment(\.modelContext) private var modelContext
  // @Query(sort: \TodoItem.dateCreated, order: .forward) private var items: [TodoItem] = []
  @State private var activeSort: [SortDescriptor<TodoItem>] = sortOptions[0].value
  @State private var searchText: String = ""
  @State private var showChecked: Bool = true

  var items: [TodoItem] { dbTodo.fetchedData }

  var predicate: Predicate<TodoItem>? { TodoItem.query(searchText: searchText, showChecked: showChecked) }
  var sortBy: [SortDescriptor<TodoItem>] { activeSort }

  @State private var newItemSummary: String = ""

  private func addItem() {
    withAnimation {
      let data = TodoItem(summary: newItemSummary)
      dbTodo.insert(data)
      newItemSummary = ""
    }
  }

  var body: some View {
    VStack {
      List {
        ForEach(items) { item in
          TodoListItem(item: item, refresh: {})
            .id(item.id) // Use ID for List reordering and animations
        }
        .onDelete(perform: { indexes in print("indexes →", indexes) })
      }
      .refreshable { dbTodo.reQuery() }
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
      .toolbar {
        CrashTests(items: items)
      }
      #if os(macOS)
      Button(action: dbTodo.reQuery) {
        Text("Refetch")
      }
      #endif
      HStack {
        CInput(modelValue: $newItemSummary, placeholder: "New Item", onSubmit: addItem)
          .textFieldStyle(RoundedBorderTextFieldStyle())

        Button(action: addItem) {
          Image(systemName: "plus")
        }
      }
      .padding()
    }
    .onAppear { dbTodo.fetchAll() }
    .onChange(of: activeSort) { _, _ in dbTodo.query(predicate: predicate, sortBy: sortBy) }
    .onChange(of: searchText) { _, _ in dbTodo.query(predicate: predicate, sortBy: sortBy) }
    .onChange(of: showChecked) { _, _ in dbTodo.query(predicate: predicate, sortBy: sortBy) }
  }
}

#Preview {
  TodoListView()
    .modelContainer(for: TodoItem.self, inMemory: true)
}

import SwiftData
import SwiftUI

let sortOptions: [Option<[SortDescriptor<TodoItem>]>] = [
  (label: "Date Added", value: [SortDescriptor<TodoItem>(\.dateCreated, order: .forward)]),
  (label: "A-Z", value: [SortDescriptor<TodoItem>(\.summary, order: .forward)]),
  (label: "Z-A", value: [SortDescriptor<TodoItem>(\.summary, order: .reverse)]),
]
let filterOptions: [Option<Bool>] = [
  (label: "Show All", value: true),
  (label: "Hide Checked Items", value: false),
]

struct TodoListView: View {
  @State private var activeSort: [SortDescriptor<TodoItem>] = sortOptions[0].value
  @State private var searchText: String = ""
  @State private var showChecked: Bool = true

  var activePredicate: Predicate<TodoItem>? { TodoItem.query(searchText: searchText, showChecked: showChecked) }

  @State private var newItemSummary: String = ""

  private func addItem() {
    if newItemSummary.isEmpty { return }
    withAnimation {
      let data = TodoItem(summary: newItemSummary)
      Task {
        try await dbTodo.insert(data)
        newItemSummary = ""
      }
    }
  }

  var body: some View {
    NavigationStack {
      VStack {
        ScrollView {
          LazyVStack {
            Spacer(minLength: 8)
            SwiftDataQuery(predicate: activePredicate, sortBy: activeSort) { item in
              TodoListItemView(item: item)
            }
            Spacer(minLength: 8)
          }
        }
        HStack {
          CInput(modelValue: $newItemSummary, placeholder: "New Item", onSubmit: addItem)
            .textFieldStyle(RoundedBorderTextFieldStyle())

          CButton(action: addItem) {
            Image(systemName: "plus")
          }
        }
        .padding()
      }
      .toolbar {
        ToolbarItem {
          MenuFilterAndSort(
            sortOptions: sortOptions,
            filterOptions: filterOptions,
            activeSort: $activeSort,
            activeFilter: $showChecked
          )
        }
        ToolbarItem {
          MenuCrashTests()
        }
      }
    }
    .searchable(text: $searchText)
  }
}

#Preview {
  TodoListView()
    .modelContainer(for: TodoItem.self, inMemory: true)
}

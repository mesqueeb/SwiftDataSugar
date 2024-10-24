import SwiftData
import SwiftUI

public typealias Option<T: Hashable> = (label: String, value: T)

public struct MenuFilterAndSort: View {
  let sortOptions: [Option<[SortDescriptor<TodoItem>]>]
  let filterOptions: [Option<Bool>]

  @Binding private var activeSort: [SortDescriptor<TodoItem>]
  @Binding private var activeFilter: Bool

  public init(
    sortOptions: [Option<[SortDescriptor<TodoItem>]>],
    filterOptions: [Option<Bool>],
    activeSort: Binding<[SortDescriptor<TodoItem>]>,
    activeFilter: Binding<Bool>
  ) {
    self.sortOptions = sortOptions
    self.filterOptions = filterOptions
    self._activeSort = activeSort
    self._activeFilter = activeFilter
  }

  public var body: some View {
    Menu {
      Picker("Sort Order", selection: $activeSort) {
        ForEach(sortOptions, id: \.label) { option in Text(option.label).tag(option.value) }
      }
      Picker("Filter", selection: $activeFilter) {
        ForEach(filterOptions, id: \.label) { option in Text(option.label).tag(option.value) }
      }
    } label: {
      Label("Sort", systemImage: "arrow.up.arrow.down")
    }
    .pickerStyle(.inline)  // swift-format-ignore
    #if os(visionOS)
      .glassBackgroundEffect()
    #endif
  }
}

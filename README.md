# SwiftDataSugar 🌯

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmesqueeb%2FSwiftDataSugar%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/mesqueeb/SwiftDataSugar)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmesqueeb%2FSwiftDataSugar%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/mesqueeb/SwiftDataSugar)

```
.package(url: "https://github.com/mesqueeb/SwiftDataSugar", from: "0.0.2")
```

A collection of utilities that make it easier to work with SwiftData in a SwiftUI environment.

- `DbCollection` is an actor made for doing CRUD on SwiftData from a background thread (and avoids pitfalls that prevent UI reactivity)
- `DbQuery` is a swiftUI view which uses `@Query` but makes it easier to use with dynamic predicate/sortby
- `MigrationStep` is a protocol to keep your migration logic organised for migration testing purposes
- `initModelContainer` wraps `ModelContainer` initialisation to more easily write migration unit tests

The rendered documentation can be found here: [swiftpackageindex.com/mesqueeb/SwiftDataSugar/documentation](https://swiftpackageindex.com/mesqueeb/SwiftDataSugar/documentation)

## Sample Project: SwiftDataTodoList

A point of reference on how to implement CRUD via SwiftData on all Apple platforms.

Features of this proof of concept:

1. Writing uses a background thread (uses the `@ModelActor` macro)
2. Reading uses MainActor thread (uses SwiftUI's `@Query` macro)
3. Migration setup with unit testing
4. Full Multi-platform support

### 1. Writing data

- Writing data to the SwiftData models is done on a background thread
- An `actor` that conforms to `ModelActor` has been set up with CRUD-like methods to easily write data to the model
- This actor is called `DbCollection`
- Instantiating `DbCollection` must be done on `@MainActor` to prevent an issue where writing data isn't reactive in SwiftUI. (see detailed explanation at [A New Issue: The View Does Not Refresh After Data Update](https://fatbobman.com/en/posts/practical-swiftdata-building-swiftui-applications-with-modern-approaches/#a-new-issue-the-view-does-not-refresh-after-data-update), an issue I've reported to Fatbobman and prompted him to write an article on)
- `DbCollection` can be used for multiple models
- in this app the usage of `DbCollection` is showcased for a `Todo` model

```swift
// example instantiating multiple collections in the `@main` swift file
@MainActor public let dbTodos = DbCollection<TodoItem>(modelContainer: modelContainer)
@MainActor public let dbUsers = DbCollection<User>(modelContainer: modelContainer)
```

### 2. Reading data

- Reading data from the SwiftData models is done on the MainActor thread
- SwiftUI's `@Query` can be used for simple views that need to query data without dynamic requirements
- The usage of `@Query` is wrapped in new view called `DbQuery` where you can pass a dynamic _predicate_ and _sortBy_ instances that queries data
- in this app the usage of `DbQuery` is showcased for a list that can be filtered and sorted dynamically

```swift
DbQuery(predicate: activePredicate, sortBy: activeSort) { items in
  ForEach(items, id: \.id) { item in
    TodoListItemView(item: item)
      .id(item.id) // Use ID for List reordering and animations
    }
  }
}
```

### 3. Migration setup with unit testing

- Custom Migrations in SwiftData, which are hard to get right, are showcased in this app with 3 versions and 2 migrations
- The latest schema has all of its structs and models type aliased for easier use throughout the codebase
- Only data crucial to migrations is scoped inside of the versioned schema, other usefull methods and convenience initialisers are extended only on the latest schema
- Actual migration logic neatly organised per-version: it bundles just the logic to upgrade to the relevant version in the same file as that version's schema
- The final combined migration plan combines each migration step per version
- Full unit testing in place of each migration phase (with modern Swift Testing) to give confidence a latest migration will not crash your user's apps on launch
- The unit testing showcases exaclty _how_ to test migrations in SwiftData

### 4. Multi-Platform Support

- All code used in this proof of concept is compatible with all Apple platforms

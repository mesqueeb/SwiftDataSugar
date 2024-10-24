import Foundation
import SwiftData

public func printMemoryAddress(_ description: String, _ ctx: ModelContext?) {
  if let ctx {
    let memoryAddress = Unmanaged.passUnretained(ctx).toOpaque()
    print("\(description) @\(memoryAddress)")
  } else {
    print("\(description) @--- NIL")
  }
}

public func printGCDThread(_ description: String = "") {
  print(
    "\(description) Thread: \(String(validatingUTF8: __dispatch_queue_get_label(nil)) ?? "unknown")"
  )
}

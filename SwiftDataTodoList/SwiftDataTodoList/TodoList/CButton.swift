import SwiftUI

/// A wrapper around Button to apply default styling etc.
public struct CButton<Content: View>: View {
  let action: () -> Void
  let content: () -> Content?

  init(
    action: @escaping () -> Void,
    @ViewBuilder content: @escaping () -> Content = { EmptyView() }
  ) {
    self.action = action
    self.content = content
  }

  public var body: some View {
    Button(action: action) { content() }  // swift-format-ignore
      #if os(visionOS)
        .glassBackgroundEffect()
      #endif
  }
}

#Preview { CButton(action: {}) { Text("Tap me!") } }

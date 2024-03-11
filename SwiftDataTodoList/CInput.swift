import SwiftUI

struct CInput: View {
  @Binding var modelValue: String
  var placeholder: String = ""
  var autoFocus: Bool = false
  var onBlur: (() -> Void)? = nil

  // FocusState to track the focus state of the TextField
  @FocusState private var isInputFocused: Bool

  var body: some View {
    TextField(placeholder, text: $modelValue)
      .focused($isInputFocused)
      .onChange(of: isInputFocused) { _, isFocused in
        if !isFocused { onBlur?() }
      }
      .onAppear {
        if autoFocus {
          self.isInputFocused = true
        }
      }
  }
}

#Preview {
  @State var text: String = ""

  return VStack {
    TextField("Focus me", text: $text)
      .padding()
    CInput(modelValue: $text, placeholder: "Type in me", autoFocus: true, onBlur: { print("Input field lost focus") })
      .padding()
  }
}

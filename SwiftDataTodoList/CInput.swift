import DebouncedOnChange
import SwiftUI

/// A wrapper around TextField to make working with the binding more predictable.
///
/// Features
/// - Does not trigger double `set` updates on input
/// - Does not trigger a binding `set` update when loosing focus
/// - Applies a default 250ms debounce
/// - Supports autoFocus & onBlur
/// - Supports reverting text input on a specified keystroke
///
/// Usage
/// ```swift
/// CInput(modelValue: textBinding, placeholder: "Type in me", autoFocus: true, onBlur: { print("Input field lost focus") })
/// ```
public struct CInput: View {
  @Binding var modelValue: String
  let placeholder: String
  let debounceMs: Int
  let revertOnExit: Bool
  let autoFocus: Bool
  let onBlur: (() -> Void)?
  /// You must pass a closure for `onSubmit` instead of using the `.onSubmit` modifier that's available by default
  /// Because otherwise we cannot trigger the debounce cancellation and set the value in time
  let onSubmit: (() -> Void)?

  public init(
    modelValue: Binding<String>,
    placeholder: String = "",
    debounceMs: Int = 250,
    revertOnExit: Bool = false,
    autoFocus: Bool = false,
    onBlur: (() -> Void)? = nil,
    onSubmit: (() -> Void)? = nil
  ) {
    self._modelValue = modelValue
    self._futureValue = State(initialValue: modelValue.wrappedValue)
    self._innerValue = State(initialValue: modelValue.wrappedValue)
    self.initialValue = modelValue.wrappedValue
    self.placeholder = placeholder
    self.debounceMs = debounceMs
    self.revertOnExit = revertOnExit
    self.autoFocus = autoFocus
    self.onBlur = onBlur
    self.onSubmit = onSubmit
  }

  @State private var debounceInput: Task<Void, Never>?
  private var initialValue: String
  @State private var futureValue: String
  @State private var innerValue: String
  /// FocusState to track the focus state of the TextField
  @FocusState private var hasFocus: Bool

  public var body: some View {
    TextField(placeholder, text: $innerValue)
      /// Watch modelValue updates
      .onChange(of: modelValue) { _, newValue in
        innerValue = newValue
      }
      /// Watch innerValue updates with debounce
      .onChange(of: innerValue) { _, newValue in
        futureValue = newValue
      }
      .onChange(of: innerValue, debounceTime: .milliseconds(250)) { _, newValue, task in
        modelValue = newValue
        debounceInput = task
      }
      /// Handle auto focus & onBlur
      .focused($hasFocus)
      .onChange(of: hasFocus) { _, focussed in if !focussed { onBlur?() } }
      .onAppear { if autoFocus { self.hasFocus = true } }
      .onSubmit {
        print("futureValue →", futureValue)
        debounceInput?.cancel()
        modelValue = futureValue
        onSubmit?()
      }
      /// Handle revertOnExit
      .onExitCommand {
        debounceInput?.cancel()
        if revertOnExit { modelValue = initialValue }
        self.hasFocus = false
      }
  }
}

public struct CInputPreview: View {
  @State var text: String = ""

  var textInTextField: Binding<String> {
    Binding<String>(
      get: { text },
      set: { newValue in
        print("[TextField] set to newValue →", newValue)
        text = newValue
      }
    )
  }

  var textInCInput: Binding<String> {
    Binding<String>(
      get: { text },
      set: { newValue in
        print("[CInput] set to newValue →", newValue)
        text = newValue
      }
    )
  }

  public var body: some View {
    VStack {
      Text(text).font(.title)
      TextField("Focus me", text: textInTextField)
        .padding()
      CInput(modelValue: textInCInput, placeholder: "Type in me", autoFocus: true, onBlur: { print("Input field lost focus") })
        .padding()
    }.onChange(of: text) { _, newValue in print("newValue →", newValue) }
  }
}

#Preview {
  CInputPreview()
}

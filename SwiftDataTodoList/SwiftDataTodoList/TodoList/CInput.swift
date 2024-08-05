import Debouncify
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
  @State var updatingModelValueTask: Task<Void, Never>? = nil

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
    self._innerValue = State(initialValue: modelValue.wrappedValue)
    self.placeholder = placeholder
    self.debounceMs = debounceMs
    self.revertOnExit = revertOnExit
    self.autoFocus = autoFocus
    self.onBlur = onBlur
    self.onSubmit = onSubmit
  }

  @State private var initialValue: String? = nil
  @State private var innerValue: String
  @FocusState private var hasFocus: Bool

  public var body: some View {
    TextField(placeholder, text: $innerValue)
      /// Watch modelValue updates
      .onChange(of: modelValue) { _, newValue in
        self.innerValue = newValue
      }
      /// Watch innerValue updates with debounce
      .onChangeDebounced(of: innerValue, after: .milliseconds(debounceMs), task: $updatingModelValueTask) { _, newValue in
        self.modelValue = newValue
      }
      /// Handle auto focus & onBlur
      .focused($hasFocus)
      .onChange(of: hasFocus) { _, focussed in if !focussed { self.onBlur?() } }
      .onAppear {
        if self.initialValue == nil { self.initialValue = self.modelValue }
        if self.autoFocus { self.hasFocus = true }
      }
      .onSubmit {
        self.updatingModelValueTask?.cancel()
        self.modelValue = self.innerValue
        self.onSubmit?()
      }
    #if os(macOS)
      /// Handle revertOnExit
      .onExitCommand {
        self.updatingModelValueTask?.cancel()
        if self.revertOnExit, let initialValue = self.initialValue {
          self.modelValue = initialValue
        }
        self.hasFocus = false
      }
    #endif
  }
}

public struct CInputPreview: View {
  @State var text: String = ""

  var textInTextField: Binding<String> {
    Binding<String>(
      get: { self.text },
      set: { newValue in
        print("[TextField] set to newValue →", newValue)
        self.text = newValue
      }
    )
  }

  var textInCInput: Binding<String> {
    Binding<String>(
      get: { self.text },
      set: { newValue in
        print("[CInput] set to newValue →", newValue)
        self.text = newValue
      }
    )
  }

  public var body: some View {
    VStack {
      Text(self.text).font(.title)
      TextField("Focus me", text: self.textInTextField)
        .padding()
      CInput(modelValue: self.textInCInput, placeholder: "Type in me", autoFocus: true, onBlur: { print("Input field lost focus") })
        .padding()
    }.onChange(of: text) { _, newValue in print("newValue →", newValue) }
  }
}

#Preview {
  CInputPreview()
}

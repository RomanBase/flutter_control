part of flutter_control;

/// Extends [TextEditingController] to integrate with the Control framework's
/// state management and lifecycle. It provides validation, focus management,
/// and chaining capabilities for input fields.
///
/// Experimental: This API is subject to change.
class InputControl extends TextEditingController with DisposeHandler {
  /// Regex pattern for validation.
  final String? regex;

  /// Focus node for the input field.
  FocusNode? _focus;

  /// Lazily initializes and returns the focus node.
  /// This should be passed to the `focusNode` property of a [TextField].
  FocusNode get focus =>
      _focus ?? (_focus = FocusNode()..addListener(_notifyFocus));

  /// Checks if the focus node is attached to a widget.
  bool get focusable => focus.context != null;

  /// Checks if the corresponding widget has focus.
  bool get hasFocus => _focus?.hasFocus ?? false;

  /// Backing field for the validity state.
  bool _isValid = true;

  /// Whether the current text is valid according to the [regex].
  bool get isValid => _isValid;

  /// Backing field for the error message.
  String? _error;

  /// The current error message for the input field.
  /// Setting a new error will notify listeners.
  String? get error => _error;

  /// Sets the error message and notifies listeners.
  set error(String? value) {
    _error = value;
    notifyListeners();
  }

  /// Backing field for the obscure text state.
  bool _obscure = false;

  /// Whether the text in the input field is obscured.
  bool get obscure => _obscure;

  /// Sets the obscure text state and notifies listeners.
  set obscure(bool value) {
    _obscure = value;
    notifyListeners();
  }

  /// The next [InputControl] in a focus chain.
  InputControl? _next;

  /// Callback for when the input is submitted (e.g., by pressing the 'done' action).
  VoidCallback? _onDone;

  /// Callback for when the text changes.
  ValueCallback<String>? _onChanged;

  /// A debounced callback for text changes.
  FutureBlock? _onChangedDelay;

  /// If true, the [_onChanged] callback will also be triggered on submit.
  bool _onChangedDone = false;

  /// Checks if there is a next control in the focus chain.
  bool get isNextChained => _next != null;

  /// Checks if an `onDone` callback is set.
  bool get isDoneMounted => _onDone != null;

  @override
  set text(String? newText) {
    newText ??= '';

    value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
      composing: TextRange.empty,
    );
  }

  /// Checks if the current text is empty.
  bool get isEmpty => text.isEmpty;

  /// Checks if the current text is not empty.
  bool get isNotEmpty => text.isNotEmpty;

  /// Creates an [InputControl].
  ///
  /// [text] The initial text.
  /// [regex] A regex pattern for validation.
  InputControl({String? text, this.regex}) {
    value =
        text == null ? TextEditingValue.empty : TextEditingValue(text: text);
  }

  /// Chains this control to the [next] control.
  /// When this field is submitted, focus will move to the [next] control.
  /// Returns the [next] control to allow for fluent chaining.
  InputControl next(InputControl control) {
    _next = control;
    return control;
  }

  /// Sets the callback to be executed on a submit event.
  /// Returns this control for fluent configuration.
  InputControl done(VoidCallback onDone) {
    _onDone = onDone;
    return this;
  }

  /// Sets the callback for text changes.
  ///
  /// [onChanged] The callback to execute.
  /// [delay] An optional duration to debounce the callback.
  /// [onDone] If true, the callback will also be triggered on submit.
  /// Returns this control for fluent configuration.
  InputControl changed(ValueCallback<String> onChanged,
      {Duration? delay, bool onDone = false}) {
    _onChanged = onChanged;
    _onChangedDone = onDone;

    if (delay == null) {
      _onChangedDelay = null;
    } else {
      _onChangedDelay = FutureBlock.extend(
        parent: _onChangedDelay,
        duration: delay,
        onDone: () {
          _onChanged?.call(text);
        },
        retrigger: false,
      );
    }

    return this;
  }

  /// Submits the current text for validation and moves focus to the next control if chained.
  /// Triggers the `onDone` callback if set.
  void submit([String? text]) {
    if (text != null) {
      this.text = text;
    }

    validate();
    focusNext();

    if (_onDone != null) {
      if (_onChangedDone) {
        if (_onChangedDelay != null) {
          _onChangedDelay!.trigger();
        } else {
          _onChanged?.call(this.text);
        }
      } else {
        _onChangedDelay?.stop();
      }

      _onDone!.call();
    }
  }

  /// Sets focus to the next [InputControl] in the chain.
  void focusNext() {
    if (_next == null) {
      return;
    }

    if (_next!.focusable) {
      _next!.setFocus(true);
    } else {
      _next!.focusNext();
    }
  }

  /// Notifies the [changed] event.
  /// If a delay is configured, the notification will be debounced.
  void change(String text) {
    if (_onChangedDelay != null) {
      _onChangedDelay = FutureBlock.extend(parent: _onChangedDelay);
    } else if (_onChanged != null) {
      _onChanged!(text);
    }
  }

  /// Submits the first control in the chain that has an `onDone` callback.
  /// If [all] is true, it submits the entire chain.
  void chainSubmit({bool all = false}) {
    validate();

    if (_onDone != null) {
      if (_onChangedDone) {
        if (_onChangedDelay != null) {
          _onChangedDelay!.trigger();
        } else {
          _onChanged?.call(this.text);
        }
      } else {
        _onChangedDelay?.stop();
      }

      _onDone!.call();

      if (!all) {
        return;
      }
    }

    _next?.chainSubmit();
  }

  /// Requests or removes focus from the input field.
  void setFocus(bool requestFocus) {
    if (!focusable) {
      return;
    }

    if (requestFocus) {
      FocusScope.of(focus.context!).requestFocus(focus);
    } else {
      focus.unfocus();
    }
  }

  /// Callback for focus changes. Clears the error when focus is gained.
  void _notifyFocus() {
    if (hasFocus) {
      error = null;
    }
  }

  /// Validates the current text against the [regex] pattern.
  /// Returns `true` if the text is valid or if no regex is provided.
  bool validate() {
    if (regex == null) {
      return _isValid = true;
    }

    return _isValid = RegExp(regex!).hasMatch(text);
  }

  /// Validates the entire chain of controls.
  ///
  /// [unfocus] If true, unfocuses the entire chain after validation.
  /// Returns `true` if all controls in the chain are valid.
  bool validateChain({bool unfocus = true}) {
    if (_next == null) {
      return validate();
    }

    if (unfocus) {
      unfocusChain();
    }

    final isChainValid = _next!
        .validateChain(unfocus: false); // validate from end to check all fields

    return validate() && isChainValid;
  }

  /// Unfocuses all controls in the chain.
  void unfocusChain() {
    setFocus(false);
    _next?.unfocusChain();
  }

  /// Clears the text, error, and all callbacks.
  ///
  /// [validity] The validity state to set after cleaning.
  void clean({bool validity = true}) {
    text = null;
    error = null;
    _onDone = null;
    _onChanged = null;
    _next = null;
    _isValid = validity;
  }

  /// Manually sets the validity of the control.
  void validity(bool value) => _isValid = value;

  @override
  void softDispose() {
    super.softDispose();
  }

  @override
  void dispose() {
    super.dispose();

    _focus?.removeListener(_notifyFocus);
    _focus = null;
  }
}

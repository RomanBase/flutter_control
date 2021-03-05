import 'package:flutter_control/core.dart';

/// Experimental !
/// Extends [TextEditingController] and adds functionality to match [Control] library.
/// Currently usable with [InputField], [InputFieldV1] and other [TextField]s...
class InputControl extends TextEditingController with DisposeHandler {
  /// Regex to validate.
  final String? regex;

  /// Focus notifier of [TextField].
  FocusNode? _focus;

  /// Lazy focus notifier. Should be passed to [TextField].
  FocusNode get focus =>
      _focus ?? (_focus = FocusNode()..addListener(_notifyFocus));

  /// Checks if [focus] node is attached to corresponding [Widget].
  bool get focusable => focus.context != null;

  /// Checks if corresponding [Widget] is focused.
  bool get hasFocus => _focus?.hasFocus ?? false;

  /// Holds field validity.
  bool _isValid = true;

  /// Checks [text] validity. Proceed during [submit] and [validate].
  bool get isValid => _isValid;

  /// Error text message.
  String? _error;

  /// Error text message.
  String? get error => _error;

  /// Error text message.
  set error(String? value) {
    _error = value;
    notifyListeners();
  }

  /// Checks if field is obscured.
  bool _obscure = false;

  /// Checks if corresponding [Widget] is obscured.
  bool get obscure => _obscure;

  /// Sets obscuring to corresponding [Widget].
  set obscure(bool value) {
    _obscure = value;
    notifyListeners();
  }

  /// Next control in chain.
  InputControl? _next;

  /// Callback of [submit].
  VoidCallback? _onDone;

  /// Callback of [text] changes.
  ValueCallback<String>? _onChanged;

  /// Checks if 'next' control is chained.
  bool get isNextChained => _next != null;

  /// Checks if 'done' callback is set.
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

  /// Check si [text] is not empty.
  bool get isEmpty => text == null || text.isEmpty;

  /// Checks if [text] is null or empty.
  bool get isNotEmpty => text != null && text.isNotEmpty;

  InputControl({String? text, this.regex}) {
    value =
        text == null ? TextEditingValue.empty : TextEditingValue(text: text);
  }

  /// Sets [control] to chain.
  /// Returns chained [control].
  InputControl next(InputControl control) {
    _next = control;
    return control;
  }

  /// Sets callback to [submit] event.
  /// Returns this control.
  InputControl done(VoidCallback onDone) {
    _onDone = onDone;
    return this;
  }

  /// Sets callback to [change] event.
  /// Returns this control.
  InputControl changed(ValueCallback<String> onChanged) {
    _onChanged = onChanged;
    return this;
  }

  /// Submits [text] and [validate] input.
  /// Sets focus to next 'control' if chained.
  void submit([String? text]) {
    if (text != null) {
      this.text = text;
    }

    validate();
    focusNext();

    if (_onDone != null) {
      _onDone!();
    }
  }

  /// Sets focus to next possible [Widget] in chain.
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

  /// Notifies [changed] event.
  void change(String text) {
    if (_onChanged != null) {
      _onChanged!(text);
    }
  }

  /// Submits first possible field with [done] event.
  /// Submits whole chain if [all] is set.
  void chainSubmit({bool all: false}) {
    validate();

    if (_onDone != null) {
      _onDone!();

      if (!all) {
        return;
      }
    }

    _next?.chainSubmit();
  }

  /// Changes focus if corresponding [Widget] is [focusable].
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

  /// Callback of [focus] changes.
  void _notifyFocus() {
    if (hasFocus) {
      error = null;
    }
  }

  /// Validates [text] with [regex] if set.
  /// Returns 'true' if [text] matches [regex].
  bool validate() {
    if (regex == null) {
      return _isValid = true;
    }

    return _isValid = RegExp(regex!).hasMatch(text);
  }

  /// Validates continuous chain. Typically called on first item in chain..
  /// Set [unfocus] to [unfocusChain] - Unfocus corresponding [Widget]s in chain.
  /// Returns 'true' if all controls are valid.
  bool validateChain({bool unfocus: true}) {
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

  /// Unfocus corresponding [Widget]s in continuous chain.
  /// Typically called on first item in chain.
  /// Check [validateChain] to also validate inputs.
  void unfocusChain() {
    setFocus(false);
    _next?.unfocusChain();
  }

  /// Cleans all variables and events.
  ///   - text
  ///   - error text
  ///   - done event
  ///   - changed event
  ///   - next event
  /// And sets validity.
  /// [focus] stays unchanged.
  void clean({bool validity: true}) {
    text = null;
    error = null;
    _onDone = null;
    _onChanged = null;
    _next = null;
    _isValid = validity;
  }

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

/// Still experimental [TextField] builder..
class InputField extends ControllableWidget<InputControl> {
  final String? label;
  final String? hint;
  final Color? color;
  final InputDecoration? decoration;
  final InputBuilder? builder;

  static InputBuilder standard({
    TextInputType keyboardType: TextInputType.text,
    TextInputAction action: TextInputAction.next,
    TextStyle? style,
  }) =>
      (context, scope, decoration) {
        final theme = Theme.of(context);

        return TextField(
          controller: scope,
          onChanged: scope.change,
          onSubmitted: scope.submit,
          focusNode: scope.focus,
          decoration: decoration,
          keyboardType: TextInputType.text,
          textInputAction: action,
          obscureText: scope.obscure,
          style: style ??
              theme.textTheme.bodyText1!.copyWith(
                  color: decoration.border?.borderSide.color ??
                      theme.textSelectionTheme.cursorColor),
        );
      };

  InputField({
    Key? key,
    required InputControl control,
    this.label,
    this.hint,
    this.decoration,
    this.color,
    this.builder,
  }) : super(
          control,
          key: key,
        );

  @override
  void onInit(Map args) {
    super.onInit(args);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cursor =
        color ?? theme.textSelectionTheme.cursorColor ?? Colors.black;

    final _decoration = (decoration ??
            InputDecoration(
              border:
                  UnderlineInputBorder(borderSide: BorderSide(color: cursor)),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: cursor.withOpacity(0.5))),
              focusedBorder:
                  UnderlineInputBorder(borderSide: BorderSide(color: cursor)),
              disabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: cursor.withOpacity(0.25))),
              labelStyle: theme.textTheme.bodyText1!
                  .copyWith(color: cursor.withOpacity(0.5)),
              hintStyle: theme.textTheme.bodyText1!
                  .copyWith(color: cursor.withOpacity(0.5)),
            ))
        .copyWith(
      labelText: label,
      hintText: hint,
      errorText: (!control.isValid) ? control._error : null,
    );

    return (builder ?? standard())(
      context,
      control,
      _decoration,
    );
  }
}

typedef Widget InputBuilder(
    BuildContext context, InputControl scope, InputDecoration decoration);

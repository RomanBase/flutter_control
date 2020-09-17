import 'package:flutter_control/core.dart';

/// Still experimental control for [TextField] builder..
class InputControl extends TextEditingController with Disposable {
  final String regex;

  FocusNode _focus;

  FocusNode get focus => _focus ?? (_focus = FocusNode());

  bool get isFocusable => focus.context != null;

  bool _isValid = true;

  bool get isValid => _isValid;

  String _error;

  String get error => _error;

  set error(String value) {
    _error = value;
    notifyListeners();
  }

  bool _obscure = false;

  bool get obscure => _obscure;

  set obscure(bool value) {
    _obscure = value;
    notifyListeners();
  }

  InputControl _next;

  VoidCallback _onDone;

  VoidCallback _onFocusChanged;

  ValueCallback<String> _onChanged;

  bool get isNextChained => _next != null;

  bool get isDoneMounted => _onDone != null;

  @override
  set text(String newText) {
    value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText == null ? -1 : newText.length),
      composing: TextRange.empty,
    );
  }

  bool get isEmpty => text == null;

  InputControl({String text, this.regex}) {
    value = text == null ? TextEditingValue.empty : TextEditingValue(text: text);
  }

  InputControl next(InputControl control) {
    _next = control;
    return control;
  }

  InputControl done(VoidCallback onDone) {
    _onDone = onDone;
    return this;
  }

  InputControl changed(ValueCallback<String> onChanged) {
    _onChanged = onChanged;
    return this;
  }

  void submit(String text) {
    validate();

    _next?.setFocus(true);

    if (_onDone != null) {
      _onDone();
    }
  }

  void change(String text) {
    if (_onChanged != null) {
      _onChanged(text);
    }
  }

  void chainSubmit({bool all: false}) {
    if (_onDone != null) {
      _onDone();

      if (!all) {
        return;
      }
    }

    _next?.chainSubmit();
  }

  void setFocus(bool requestFocus) {
    if (requestFocus) {
      if (isFocusable) {
        FocusScope.of(focus.context).requestFocus(focus);
      }
    } else {
      focus.unfocus();
    }
  }

  void onFocusChanged(ValueCallback<bool> listener) {
    if (_onFocusChanged != null) {
      focus.removeListener(_onFocusChanged);
      _onFocusChanged = null;
    }

    if (listener != null) {
      focus.addListener(_onFocusChanged = () => listener(focus.hasFocus));
    }
  }

  bool validate() {
    if (regex == null) {
      return _isValid = true;
    }

    return _isValid = RegExp(regex).hasMatch(value ?? '');
  }

  bool validateChain({bool unfocus: true}) {
    if (_next == null) {
      return validate();
    }

    if (unfocus) {
      unfocusChain();
    }

    final isChainValid = _next.validateChain(unfocus: unfocus); // validate from end to check all fields

    return validate() && isChainValid;
  }

  void unfocusChain() {
    setFocus(false);
    _next?.unfocusChain();
  }
}

/// Still experimental [TextField] builder..
class InputField extends ControllableWidget<InputControl> {
  final String label;
  final String hint;
  final Color color;
  final InputDecoration decoration;
  final InputBuilder builder;

  static InputBuilder standard({
    TextInputType keyboardType: TextInputType.text,
    TextInputAction action: TextInputAction.next,
    TextStyle style,
  }) =>
      (context, scope, decoration) => TextField(
            controller: scope,
            onChanged: scope.change,
            onSubmitted: scope.submit,
            focusNode: scope.focus,
            decoration: decoration,
            keyboardType: TextInputType.text,
            textInputAction: action,
            obscureText: scope.obscure,
            style: style ?? Theme.of(context).primaryTextTheme,
          );

  InputField({
    Key key,
    @required InputControl control,
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
    final cursor = color ?? theme.cursorColor;

    final _decoration = (decoration ??
            InputDecoration(
              border: UnderlineInputBorder(borderSide: BorderSide(color: cursor)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cursor.withOpacity(0.5))),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: cursor)),
              disabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cursor.withOpacity(0.25))),
              labelStyle: theme.textTheme.bodyText1.copyWith(color: cursor.withOpacity(0.5)),
              hintStyle: theme.textTheme.bodyText1.copyWith(color: cursor.withOpacity(0.5)),
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

typedef Widget InputBuilder(BuildContext context, InputControl scope, InputDecoration decoration);

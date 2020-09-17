import 'package:flutter_control/core.dart';

/// Still experimental control for [TextField] builder..
class InputControlV2 extends TextEditingController with Disposable, StateControl {
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
    notifyState();
  }

  bool _obscure = false;

  bool get obscure => _obscure;

  set obscure(bool value) {
    _obscure = value;
    notifyState();
  }

  InputControlV2 _next;

  VoidCallback _onDone;

  VoidCallback _onFocusChanged;

  ValueCallback<String> _onChanged;

  bool get isNextChained => _next != null;

  bool get isDoneMounted => _onDone != null;

  set text(String newText) {
    value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText == null ? -1 : newText.length),
      composing: TextRange.empty,
    );
  }

  InputControlV2({String text, this.regex}) {
    value = text == null ? TextEditingValue.empty : TextEditingValue(text: text);
  }

  InputControlV2 next(InputControlV2 control) {
    _next = control;
    return control;
  }

  InputControlV2 done(VoidCallback onDone) {
    _onDone = onDone;
    return this;
  }

  InputControlV2 changed(ValueCallback<String> onChanged) {
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
class InputFieldV2 extends StateboundWidget<InputControlV2> with ThemeProvider {
  final String label;
  final String hint;
  final Color color;
  final InputDecoration decoration;
  final InputBuilder builder;

  static InputBuilder standard({
    TextInputType keyboardType: TextInputType.text,
    TextInputAction action: TextInputAction.next,
  }) =>
      (context, scope, decoration) => TextField(
            controller: scope,
            onChanged: control.change,
            onSubmitted: control.submit,
            focusNode: control.focus,
            decoration: decoration,
            keyboardType: TextInputType.text,
            textInputAction: action,
            obscureText: scope.obscure,
          );

  InputFieldV2({
    Key key,
    @required InputControlV2 control,
    this.label,
    this.hint,
    this.decoration,
    this.color,
    this.builder,
  }) : super(
          key: key,
          control: control,
        );

  @override
  void onInit(Map args) {
    super.onInit(args);
  }

  @override
  Widget build(BuildContext context) {
    final cursor = color ?? theme.data.cursorColor;

    final _decoration = (decoration ??
            InputDecoration(
              border: UnderlineInputBorder(borderSide: BorderSide(color: cursor)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cursor.withOpacity(0.5))),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: cursor)),
              disabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cursor.withOpacity(0.25))),
              labelStyle: font.bodyText1.copyWith(color: cursor.withOpacity(0.5)),
              hintStyle: font.bodyText1.copyWith(color: cursor.withOpacity(0.5)),
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

typedef Widget InputBuilder(BuildContext context, InputControlV2 scope, InputDecoration decoration);

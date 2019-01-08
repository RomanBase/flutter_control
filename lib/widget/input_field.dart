import 'package:flutter_control/core.dart';

class FocusController extends FocusNode {
  BuildContext _context;

  void setContext(BuildContext context) {
    _context = context;
  }

  void focus() {
    if (_context != null) {
      FocusScope.of(_context).requestFocus(this);
    }
  }
}

/// CONTROLLER
class InputController extends StateController {
  final String regex;

  final _editController = TextEditingController();
  final _focusController = FocusController();

  String _error;
  String _text;

  String get text => _text;

  bool _isValid = true;

  bool get isValid => _isValid;

  bool get hasFocus => _focusController.hasFocus;

  InputController _next;
  VoidCallback _onDone;

  InputController({String text, this.regex}) {
    _text = text;
  }

  void setText(String text) {
    _text = text;
    notifyState();
  }

  void setError(String text) {
    _error = text;
    notifyState();
  }

  InputController next(InputController controller) {
    return _next = controller;
  }

  void done(VoidCallback onDone) {
    _onDone = onDone;
  }

  void submit() {
    if (_next != null) {
      _next.focus(true);
    }

    if (_onDone != null) {
      _onDone();
    }
  }

  void focus(bool requestFocus) {
    if (requestFocus) {
      _focusController.focus();
    } else {
      _focusController.unfocus();
    }
  }

  bool validate() {
    if (regex == null) {
      return _isValid = true;
    }

    return _isValid = text != null && RegExp(regex).hasMatch(text);
  }

  @override
  void notifyState({state}) {
    if (text != null) {
      _editController.text = text;
      _editController.selection = TextSelection.collapsed(offset: text.length);
    }

    super.notifyState(state: state);
  }

  @override
  InputField initWidget() => InputField(controller: this);

  @override
  void dispose() {
    super.dispose();
  }
}

/// WIDGET
class InputField extends ControlWidget<InputController> {
  final String hint;
  final String label;

  final TextStyle style;
  final bool obscure;
  final Color cursorColor;
  final InputDecoration decoration;
  final TextAlign align;
  final TextInputType keyboardType;
  final TextInputAction action;
  final bool autocorrect;

  InputField({
    @required InputController controller,
    this.hint,
    this.label,
    this.style,
    this.obscure = false,
    this.cursorColor,
    this.decoration,
    this.align = TextAlign.start,
    this.keyboardType,
    this.action = TextInputAction.next,
    this.autocorrect = false,
  }) : super(controller: controller);

  @override
  State<StatefulWidget> createState() => _InputFieldState();
}

/// STATE
class _InputFieldState extends ControlState<InputController, InputField> {
  @override
  Widget buildWidget(BuildContext context, InputController controller) {
    controller._focusController.setContext(context);

    return TextField(
      onChanged: (text) => controller._text = text,
      onSubmitted: (text) => controller.submit(),
      controller: controller._editController,
      focusNode: controller._focusController,
      style: widget.style,
      obscureText: widget.obscure,
      cursorColor: widget.cursorColor,
      textAlign: widget.align,
      keyboardType: widget.keyboardType,
      textInputAction: widget.action,
      autocorrect: widget.autocorrect,
      decoration: (widget.decoration ?? InputDecoration()).copyWith(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: (!controller.isValid && !controller._focusController.hasFocus) ? controller._error : null,
      ),
    );
  }
}

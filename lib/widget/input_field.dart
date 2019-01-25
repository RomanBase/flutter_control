import 'package:flutter_control/core.dart';

/// Extends and adds functionality to standard FocusNode
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

/// Controller of InputField.
/// Can chain multiple Controllers for submissions.
class InputController extends StateController {
  /// Regex to check value validity.
  final String regex;

  /// Standard TextEditingController to provide default text.
  final _editController = TextEditingController();

  /// Controls focus of InputField.
  final _focusController = FocusController();

  /// Warning text to display when Field isn't valid.
  String _error;

  /// Current text of Field.
  String _text;

  /// returns Current text.
  /// not null
  String get text => _text ?? '';

  /// Validity of text - regex based.
  bool _isValid = true;

  /// returns Current validity - regex based.
  /// Validity is checked right after text submit.
  bool get isValid => _isValid;

  /// returns true if Field is focused.
  bool get hasFocus => _focusController.hasFocus;

  /// Next InputController.
  InputController _next;

  /// Callback when user submit text.
  VoidCallback _onDone;

  /// Helps easily add/remove callback at FocusController.
  VoidCallback _onFocusChanged;

  /// Default constructor
  InputController({String text, this.regex}) {
    _text = text;
  }

  /// Sets text and notify InputField State to change Widget.
  void setText(String text) {
    _text = text;
    notifyState();
  }

  /// Sets text and notify InputField State to change Widget.
  void setError(String text) {
    _error = text;
    notifyState();
  }

  /// Sets next Controller into chain.
  InputController next(InputController controller) {
    return _next = controller;
  }

  /// Sets callback for submit.
  void done(VoidCallback onDone) {
    _onDone = onDone;
  }

  /// Submit text and unfocus controlled InputField and focus next one (if is chained).
  /// Done callback is called as well.
  void submit() {
    validate();

    if (_next != null) {
      _next.focus(true);
    }

    if (_onDone != null) {
      _onDone();
    }
  }

  /// Change focus of InputField.
  void focus(bool requestFocus) {
    if (requestFocus) {
      _focusController.focus();
    } else {
      _focusController.unfocus();
    }
  }

  /// Sets on focus changed listener.
  /// Only one listener is active at time.
  /// Set null to remove listener.
  void onFocusChanged(Action<bool> listener) {
    if (_onFocusChanged != null) {
      _focusController.removeListener(_onFocusChanged);
      _onFocusChanged = null;
    }

    if (listener != null) {
      _focusController.addListener(_onFocusChanged = () => listener(hasFocus));
    }
  }

  /// Validate text with given regex.
  /// This method isn't called continuously.
  /// Typically just after submit.
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

    //_editController.dispose();
    //_focusController.dispose();
  }
}

//TODO: expose more params from TextField
/// More powerful TextField with Controller
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
    this.obscure: false,
    this.cursorColor,
    this.decoration,
    this.align: TextAlign.start,
    this.keyboardType,
    this.action: TextInputAction.next,
    this.autocorrect: false,
  }) : super(controller: controller);

  @override
  State<StatefulWidget> createState() => _InputFieldState();
}

/// Builds just TextField and sets up Controllers.
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

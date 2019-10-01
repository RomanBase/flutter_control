import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_control/core.dart';

/// Extends and adds functionality to standard [FocusNode]
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

/// Controller of [InputField].
/// Can chain multiple Controllers for submissions.
class InputController extends StateController {
  @override
  bool get preferSoftDispose => true;

  /// Regex to check value validity.
  final String regex;

  /// Standard TextEditingController to provide default text.
  TextEditingController _editController;

  /// Controls focus of InputField.
  FocusController _focusController;

  /// Warning text to display when Field isn't valid.
  String _error;

  /// Current text of Field.
  String _text;

  /// Text obscure for passwords etc.
  bool _obscure = false;

  /// returns Current text.
  /// Non null
  String get value => _text ?? '';

  /// Validity of text - regex based.
  bool _isValid = true;

  /// returns Current validity - regex based.
  /// Validity is checked right after text submit.
  bool get isValid => _isValid;

  /// returns true if Field is focused.
  bool get hasFocus => _focusController?.hasFocus ?? false;

  /// Next InputController.
  InputController _next;

  /// Callback when user submit text.
  VoidCallback _onDone;

  /// Helps easily add/remove callback at FocusController.
  VoidCallback _onFocusChanged;

  /// Callback when user changes text.
  ValueCallback<String> _onChanged;

  /// Default constructor
  InputController({String text, this.regex}) {
    _text = text;
  }

  /// Initializes [TextEditingController] and [FocusController].
  /// Can be called multiple times to prevent early disposed controllers.
  void _initControllers() {
    if (_editController == null) {
      _editController = TextEditingController(text: value);
    }

    if (_focusController == null) {
      _focusController = FocusController();
      _focusController.addListener(() {
        if (hasFocus) {
          setError(null);
        }
      });
    }
  }

  @override
  void onStateInitialized() => _initControllers();

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

  /// Sets text obscure to show/hide passwords etc.
  void setObscure(bool obscure) {
    if (_obscure == obscure) {
      return;
    }

    _obscure = obscure;
    notifyState();
  }

  /// Sets next Controller into chain.
  InputController next(InputController controller) {
    return _next = controller;
  }

  /// Sets callback for input submit.
  InputController done(VoidCallback onDone) {
    _onDone = onDone;

    return this;
  }

  /// Sets callback for text changes.
  InputController changed(ValueCallback<String> onChanged) {
    _onChanged = onChanged;

    return this;
  }

  /// Sets text to controller and notify text changed listener.
  void _changeText(String text) {
    _text = text;

    if (_onChanged != null) {
      _onChanged(text);
    }
  }

  /// Submit text and unfocus controlled InputField and focus next one (if is chained).
  /// [done] callback is called as well.
  void submit() {
    validate();

    if (_next != null) {
      _next.focus(true);
    }

    if (_onDone != null) {
      _onDone();
    }
  }

  /// [done] callback is called for first or for [all] chained inputs.
  void chainSubmit({bool all: false}) {
    if (_onDone != null) {
      _onDone();

      if (!all) {
        return;
      }
    }

    _next?.chainSubmit();
  }

  /// Change focus of InputField.
  void focus(bool requestFocus) {
    if (_focusController == null) {
      printDebug('no focus controller found');
      return;
    }

    if (requestFocus) {
      _focusController.focus();
    } else {
      _focusController.unfocus();
    }
  }

  /// Sets on focus changed listener.
  /// Only one listener is active at time.
  /// Set null to remove listener.
  void onFocusChanged(ValueCallback<bool> listener) {
    _initControllers();

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

    return _isValid = RegExp(regex).hasMatch(value ?? '');
  }

  /// Validate text with given regex thru all chained inputs.
  /// This method isn't called continuously.
  /// Typically after whole form submission.
  bool validateChain({bool unfocus: true}) {
    if (_next == null) {
      return validate();
    }

    if (unfocus) {
      focus(false);
    }

    final isNextValid = _next.validateChain(unfocus: unfocus); // validate from end to check all fields

    return validate() && isNextValid;
  }

  /// Unfocus field thru all chained inputs.
  void unfocusChain() {
    focus(false);
    _next?.unfocusChain();
  }

  /// Clears text and notifies [TextField]
  void clear() => setText(null);

  @override
  void notifyState([state]) {
    if (value != null) {
      _initControllers();

      _editController.text = value;
      _editController.selection = TextSelection.collapsed(offset: value.length);
    }

    super.notifyState(state);
  }

  @override
  void dispose() {
    super.dispose();

    _editController.dispose();
    _focusController.dispose();

    _editController = null;
    _focusController = null;
  }
}

/// More powerful [TextField] with [InputController] and default [InputDecoration]
///
/// [InputController.next]
/// [InputController.done]
/// [InputController.changed]
class InputField extends ControlWidget {
  /// Controller of the [TextField]
  /// Sets initial text, focus, error etc.
  final InputController controller;

  /// Text that suggests what sort of input the field accepts.
  ///
  /// Displayed on top of the input [child] (i.e., at the same location on the
  /// screen where text may be entered in the input [child]) when the input
  /// [isEmpty] and either (a) [labelText] is null or (b) the input has the focus.
  final String hint;

  /// Text that describes the input field.
  ///
  /// When the input field is empty and unfocused, the label is displayed on
  /// top of the input field (i.e., at the same location on the screen where
  /// text may be entered in the input field). When the input field receives
  /// focus (or if the field is non-empty), the label moves above (i.e.,
  /// vertically adjacent to) the input field.
  final String label;

  /// The style to use for the text being edited.
  ///
  /// This text style is also used as the base style for the [decoration].
  ///
  /// If null, defaults to the `subhead` text style from the current [Theme].
  final TextStyle style;

  /// The decoration to show around the text field.
  ///
  /// By default, draws a horizontal line under the text field but can be
  /// configured to show an icon, label, hint text, and error text.
  ///
  /// Specify null to remove the decoration entirely (including the
  /// extra padding introduced by the decoration to save space for the labels).
  final InputDecoration decoration;

  /// {@macro flutter.widgets.editableText.keyboardType}
  final TextInputType keyboardType;

  /// The type of action button to use for the keyboard.
  ///
  /// Defaults to [TextInputAction.newline] if [keyboardType] is
  /// [TextInputType.multiline] and [TextInputAction.done] otherwise.
  final TextInputAction textInputAction;

  /// {@macro flutter.widgets.editableText.textCapitalization}
  final TextCapitalization textCapitalization;

  /// {@macro flutter.widgets.editableText.strutStyle}
  final StrutStyle strutStyle;

  /// {@macro flutter.widgets.editableText.textAlign}
  final TextAlign textAlign;

  /// {@macro flutter.widgets.editableText.textDirection}
  final TextDirection textDirection;

  /// {@macro flutter.widgets.editableText.autofocus}
  final bool autofocus;

  /// {@macro flutter.widgets.editableText.obscureText}
  final bool obscureText;

  /// {@macro flutter.widgets.editableText.autocorrect}
  final bool autocorrect;

  /// {@macro flutter.widgets.editableText.maxLines}
  final int maxLines;

  /// {@macro flutter.widgets.editableText.minLines}
  final int minLines;

  /// {@macro flutter.widgets.editableText.expands}
  final bool expands;

  /// {@macro flutter.widgets.text_field.maxLength}
  final int maxLength;

  /// {@macro flutter.widgets.text_field.maxLengthEnforced}
  final bool maxLengthEnforced;

  /// {@macro flutter.widgets.editableText.inputFormatters}
  final List<TextInputFormatter> inputFormatters;

  /// If false the text field is "disabled": it ignores taps and its
  /// [decoration] is rendered in grey.
  ///
  /// If non-null this property overrides the [decoration]'s
  /// [Decoration.enabled] property.
  final bool enabled;

  /// {@macro flutter.widgets.editableText.cursorWidth}
  final double cursorWidth;

  /// {@macro flutter.widgets.editableText.cursorRadius}
  final Radius cursorRadius;

  /// The color to use when painting the cursor.
  ///
  /// Defaults to the theme's `cursorColor` when null.
  final Color cursorColor;

  /// The appearance of the keyboard.
  ///
  /// This setting is only honored on iOS devices.
  ///
  /// If unset, defaults to the brightness of [ThemeData.primaryColorBrightness].
  final Brightness keyboardAppearance;

  /// {@macro flutter.widgets.editableText.scrollPadding}
  final EdgeInsets scrollPadding;

  /// {@macro flutter.widgets.editableText.enableInteractiveSelection}
  final bool enableInteractiveSelection;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// {@macro flutter.widgets.edtiableText.scrollPhysics}
  final ScrollPhysics scrollPhysics;

  final bool readOnly;

  final ToolbarOptions toolbarOptions;

  final bool showCursor;

  final VoidCallback onTap;

  final InputCounterWidgetBuilder buildCounter;

  final ScrollController scrollController;

  InputField({
    Key key,
    @required this.controller,
    this.label,
    this.hint,
    this.decoration,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization: TextCapitalization.none,
    this.style,
    this.strutStyle,
    this.textAlign: TextAlign.start,
    this.textDirection,
    this.readOnly: false,
    this.toolbarOptions,
    this.showCursor,
    this.autofocus: false,
    this.obscureText: false,
    this.autocorrect: true,
    this.maxLines: 1,
    this.minLines,
    this.expands: false,
    this.maxLength,
    this.maxLengthEnforced: true,
    this.inputFormatters,
    this.enabled,
    this.cursorWidth: 2.0,
    this.cursorRadius,
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding: const EdgeInsets.all(20.0),
    this.dragStartBehavior: DragStartBehavior.start,
    this.enableInteractiveSelection: true,
    this.onTap,
    this.buildCounter,
    this.scrollController,
    this.scrollPhysics,
  }) : super(key: key);

  @override
  List<BaseController> initControllers() {
    controller._obscure = obscureText;

    return [controller];
  }

  @override
  void notifyWidget(ControlState state) {
    super.notifyWidget(state);

    controller._initControllers();
    controller._focusController.setContext(context);
  }

  @override
  Widget build(BuildContext context) {
    final cursor = cursorColor ?? theme.cursorColor;

    return TextField(
      onChanged: controller._changeText,
      onSubmitted: (text) => controller.submit(),
      controller: controller._editController,
      focusNode: controller._focusController,
      decoration: (decoration ??
              InputDecoration(
                border: UnderlineInputBorder(borderSide: BorderSide(color: cursor)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cursor.withOpacity(0.5))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: cursor)),
                disabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cursor.withOpacity(0.25))),
                labelStyle: font.body1.copyWith(color: cursor.withOpacity(0.5)),
                hintStyle: font.body1.copyWith(color: cursor.withOpacity(0.5)),
              ))
          .copyWith(
        labelText: label,
        hintText: hint,
        errorText: (!controller.isValid) ? controller._error : null,
      ),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: style ?? font.body1.copyWith(color: cursor),
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      toolbarOptions: toolbarOptions,
      showCursor: showCursor,
      readOnly: readOnly,
      autofocus: autofocus,
      obscureText: controller._obscure,
      autocorrect: autocorrect,
      maxLines: maxLines,
      minLines: minLines,
      expands: expands,
      maxLength: maxLength,
      maxLengthEnforced: maxLengthEnforced,
      inputFormatters: inputFormatters,
      enabled: enabled,
      cursorWidth: cursorWidth,
      cursorRadius: cursorRadius,
      cursorColor: cursor,
      keyboardAppearance: keyboardAppearance,
      scrollPadding: scrollPadding,
      dragStartBehavior: dragStartBehavior,
      enableInteractiveSelection: enableInteractiveSelection,
      onTap: onTap,
      buildCounter: buildCounter,
      scrollController: scrollController,
      scrollPhysics: scrollPhysics,
    );
  }
}

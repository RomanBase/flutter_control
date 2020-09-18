import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_control/core.dart';

/// More powerful [TextField] with [InputControlOld] and default [InputDecoration]
///
/// [InputControlOld.next]
/// [InputControlOld.done]
/// [InputControlOld.changed]
class InputFieldV1 extends ControllableWidget<InputControl> with ThemeProvider {
  /// Controller of the [TextField]
  /// Sets initial text, focus, error etc.
  final InputControl control;

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

  InputFieldV1({
    Key key,
    @required this.control,
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
  }) : super(
          control,
          key: key,
        );

  @override
  void onInit(Map args) {
    super.onInit(args);

    control.obscure = obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final cursor = cursorColor ?? theme.data.cursorColor;

    return TextField(
      onChanged: control.change,
      onSubmitted: control.submit,
      controller: control,
      focusNode: control.focus,
      decoration: (decoration ??
              InputDecoration(
                border:
                    UnderlineInputBorder(borderSide: BorderSide(color: cursor)),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: cursor.withOpacity(0.5))),
                focusedBorder:
                    UnderlineInputBorder(borderSide: BorderSide(color: cursor)),
                disabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: cursor.withOpacity(0.25))),
                labelStyle:
                    font.bodyText1.copyWith(color: cursor.withOpacity(0.5)),
                hintStyle:
                    font.bodyText1.copyWith(color: cursor.withOpacity(0.5)),
              ))
          .copyWith(
        labelText: label,
        hintText: hint,
        errorText: (!control.isValid) ? control.error : null,
      ),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: style ?? font.bodyText1.copyWith(color: cursor),
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      toolbarOptions: toolbarOptions,
      showCursor: showCursor,
      readOnly: readOnly,
      autofocus: autofocus,
      obscureText: control.obscure,
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

import 'package:flutter_control/core.dart';

/// Still experimental [TextField] builder..
class InputField extends ControllableWidget<InputControl> {
  final String? label;
  final String? hint;
  final Color? color;
  final InputDecoration? decoration;
  final InputBuilder? builder;

  static InputBuilder text({
    TextInputType keyboardType: TextInputType.text,
    TextInputAction? action,
    TextStyle? style,
    VoidCallback? onSubmit,
    bool autofocus: false,
    int? lines,
    TextAlign textAlign: TextAlign.start,
  }) =>
      (context, scope, decoration) {
        return TextField(
          controller: scope,
          onChanged: scope.change,
          onSubmitted: (text) {
            onSubmit?.call();
            scope.submit(text);
          },
          autofocus: autofocus,
          focusNode: scope.focus,
          decoration: decoration,
          keyboardType: keyboardType,
          textInputAction: action ?? (scope.isNextChained ? TextInputAction.next : TextInputAction.done),
          obscureText: scope.obscure,
          style: style ?? Theme.of(context).textTheme.bodyText1,
          textAlign: textAlign,
          maxLines: lines == null ? 1 : null,
          expands: lines != null,
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
    final cursor = color ?? theme.textSelectionTheme.cursorColor ?? Colors.black;

    final _decoration = (decoration ??
            InputDecoration(
              border: UnderlineInputBorder(borderSide: BorderSide(color: cursor)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cursor.withOpacity(0.5))),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: cursor)),
              disabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cursor.withOpacity(0.25))),
              labelStyle: theme.textTheme.bodyText1!.copyWith(color: cursor.withOpacity(0.5)),
              hintStyle: theme.textTheme.bodyText1!.copyWith(color: cursor.withOpacity(0.5)),
            ))
        .copyWith(
      labelText: label,
      hintText: hint,
      errorText: (!control.isValid) ? control.error : null,
    );

    return (builder ?? text())(
      context,
      control,
      _decoration,
    );
  }
}

typedef Widget InputBuilder(BuildContext context, InputControl scope, InputDecoration decoration);

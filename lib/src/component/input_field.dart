part of flutter_control;

/// Still experimental [TextField] builder..
class InputField extends ControllableWidget<InputControl> {
  final String? label;
  final String? hint;
  final Color? color;
  final InputDecoration? decoration;
  final InputBuilder builder;

  InputField({
    super.key,
    required super.control,
    this.label,
    this.hint,
    this.decoration,
    this.color,
    required this.builder,
  });

  @override
  void onInit(Map args, CoreContext context) {
    super.onInit(args, context);
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
              labelStyle: theme.textTheme.bodyLarge!
                  .copyWith(color: cursor.withOpacity(0.5)),
              hintStyle: theme.textTheme.bodyLarge!
                  .copyWith(color: cursor.withOpacity(0.5)),
            ))
        .copyWith(
      labelText: label,
      hintText: hint,
      errorText: (!control.isValid) ? control.error : null,
    );

    return builder.call(
      context,
      control,
      _decoration,
    );
  }
}

typedef Widget InputBuilder(
    BuildContext context, InputControl scope, InputDecoration decoration);
